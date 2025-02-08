require 'fileutils'
require 'yaml'
require 'erb'

option_keys = []
problematic_files = []

Dir::glob(__dir__ + "/ansible/lib/ansible/modules/**/*").each {|f|
  if File.directory? f
    FileUtils.mkdir_p(File.join(__dir__ + "/../snippets/text-mode/ansible", File.basename(f)))
    next
  end

  puts "Processing: #{f}"

  yml = ''
  start = false
  open(f).each {|line|
    start = false if /^'''/.match line
    start = false if /^"""/.match line
    line.gsub!(/(.+)\- "When(.+)"$/, '\1- When\2') # for postgresql_user DOCUMENTATION
    yml << line if start
    start = true if /^DOCUMENTATION = .?'''/.match line
    start = true if /^DOCUMENTATION = .?"""/.match line
  } if File.file? f

  begin
    doc = YAML.safe_load(yml)
  rescue Psych::SyntaxError => e
    relative_path = f
    relative_path.sub(__dir__ + "/ansible/lib/ansible/modules", "")
    msg = "Error parsing YAML in #{relative_path}: #{e.message}"
    puts msg
    problematic_files << msg
    next
  end
  next unless doc
  index = 2
  options = ''
  doc['options'].each {|key, value|
    option_keys << key
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
  } if doc['options']
  options = ' $2' unless doc['options']

  options << ' $0'
  template = <<~END_SNIPPET
    # name : <%= doc['short_description'] %>
    # key : <%= doc['module'] %>
    # condition: ansible
    # --
    - name: ${1:<%= doc['short_description'] %>}
      <%= doc['module'] %>:<%= options %>
  END_SNIPPET
  snippet = ERB.new template
  dirname = File.basename(File.dirname(f))
  snippet_dir = File.join(__dir__ + "/../snippets/text-mode/ansible", dirname)
  FileUtils.mkdir_p(snippet_dir) unless Dir.exist?(snippet_dir)
  File.write(File.join(snippet_dir, File.basename(f).gsub(/.py$/, '')), snippet.result(binding))

  File.write(__dir__ + "/../dict/ansible", option_keys.uniq.join("\n"))
}

# Print the list of problematic files at the end
if problematic_files.any?
  puts "\nList of problematic files:"
  problematic_files.each { |file| puts file }
end
