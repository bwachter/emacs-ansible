require 'fileutils'
require 'yaml'
require 'erb'
require 'open3'

ANSIBLE_TAG = 'v2.18.2'

SNIPPET_SOURCE = "#{__dir__}/ansible/lib/ansible/modules".freeze
SNIPPET_DEST = "#{__dir__}/../snippets/text-mode/ansible".freeze
WORDLIST = "#{__dir__}/../dict/ansible".freeze

$option_keys = []
$problematic_files = []

def get_current_branch(target_dir, branch)
  # Check the current branch in the repository
  Dir.chdir(target_dir) do
    cmd = 'git symbolic-ref --short HEAD 2>/dev/null || ' \
          'git describe --tags --exact-match 2>/dev/null'
    output, status = Open3.capture2e(cmd)
    raise "Failed to get current branch or tag: #{output}" unless status.success?

    output.strip
  end
end

def checkout_branch(target_dir, branch)
  current = get_current_branch(target_dir, branch)
  if current == branch
    puts "Repository is already on branch #{branch}."
    return
  end

  # Checkout the specified branch if the repository already exists
  Dir.chdir(target_dir) do
    cmd = "git checkout #{branch}"
    output, status = Open3.capture2e(cmd)
    puts "Output: #{output}"
    raise "Failed to checkout branch: #{output}" unless status.success?

    # Pull the latest changes from the branch
    cmd = 'git pull'
    output, status = Open3.capture2e(cmd)
    puts "Output: #{output}"
    raise "Failed to pull latest changes: #{output}" unless status.success?
  end
  puts "Switched to branch #{branch} in #{target_dir}."
end

def checkout_repo(repo_url, target_dir, branch)
  # Clone the repository into the target directory if it doesn't exist already
  if File.exist?("#{target_dir}/.git")
    checkout_branch(target_dir, branch)
    return
  end

  puts "Checking out #{repo_url} to #{target_dir}..."
  cmd = "git clone --branch #{branch} #{repo_url} #{target_dir}"
  output, status = Open3.capture2e(cmd)
  puts "Output: #{output}"
  raise "Failed to clone repository: #{output}" unless status.success?

  puts "Repository successfully checked out at #{target_dir} on branch #{branch}"
end

def get_yml(file_path)
  yml = ''
  start = false
  File.open(file_path) do |file|
    file.each_line do |line|
      start = false if /^'''/.match line
      start = false if /^"""/.match line
      line.gsub!(/(.+)- "When(.+)"$/, '\1- When\2') # for postgresql_user DOCUMENTATION
      yml << line if start
      start = true if /^DOCUMENTATION = .?'''/.match line
      start = true if /^DOCUMENTATION = .?"""/.match line
    end
  end
  yml
end

def extract_doc(yml, file_path)
  begin
    doc = YAML.safe_load(yml)
  rescue Psych::SyntaxError => e
    relative_path = file_path
    relative_path.sub(SNIPPET_SOURCE, '')
    msg = "Error parsing YAML in #{relative_path}: #{e.message}"
    puts msg
    $problematic_files << msg
    return
  end
  doc
end

def extract_options(doc)
  index = 2
  options = ''
  doc&.dig('options')&.each do |key, value|
    $option_keys << key
    next unless value['required']

    options << ' '
    options << key
    if value['default']
      options << '=${'
      options << index.to_s
      options << ':'
      options << value['default'].to_s
      options << '}'
    else
      options << '=$'
      options << index.to_s
    end
    index += 1
  end
  options = ' $2' unless doc['options']

  options << ' $0'
  options
end

def create_template(options, doc)
  <<~END_SNIPPET
    # name : <%= doc['short_description'] %>
    # key : <%= doc['module'] %>
    # condition: ansible
    # --
    - name: ${1:<%= doc['short_description'] %>}
      <%= doc['module'] %>:<%= options %>
  END_SNIPPET
end

def process_file(file_path)
  return if File.directory?(file_path)

  puts "Processing: #{file_path}"

  yml = get_yml(file_path)

  doc = extract_doc(yml, file_path)
  return unless doc

  options = extract_options(doc)
  snippet = ERB.new create_template(options, doc)
  dirname = File.basename(File.dirname(file_path))
  snippet_dir = File.join(SNIPPET_DEST, dirname)
  FileUtils.mkdir_p(snippet_dir) unless Dir.exist?(snippet_dir)
  File.write(File.join(snippet_dir, File.basename(file_path).gsub(/.py$/, '')), snippet.result(binding))

  File.write(WORDLIST, $option_keys.uniq.join("\n"))
end

def process_files(directory)
  $problematic_files = []

  Dir.glob("#{directory}/**/*").each do |file|
    process_file(file)
  end

  return unless $problematic_files.any?

  # Print the list of problematic files at the end
  puts "\nList of problematic files:"
  $problematic_files.each { |file| puts file }
end

checkout_repo('https://github.com/ansible/ansible.git', "#{__dir__}/ansible", ANSIBLE_TAG)
process_files(SNIPPET_SOURCE)
