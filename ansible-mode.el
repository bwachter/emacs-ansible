;;; ansible.el --- Ansible minor mode -*- lexical-binding: t -*-

;; Copyright (C) 2014 by 101000code/101000LAB
;; Copyright (C) 2024 by Mark A. Hershberger

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

;; Version: 0.4.1
;; Author: k1LoW (Kenichirou Oyama), <k1lowxb [at] gmail [dot] com>
;;                                   <k1low [at] 101000lab [dot] org>
;; Updates: Mark A. Hershberger, <mah@everybody.org>
;; URL: https://gitlab.com/emacs-ansible/emacs-ansible
;; Package-Requires: ((s "1.9.0") (f "0.16.2") (emacs "25.1"))

;;; Install
;; Put this file into load-path'ed directory, and byte compile it if
;; desired.  And put the following expression into your ~/.emacs.
;;
;; (require 'ansible-mode)

;;; Commentary:
;; This is minor-mode for editing ansible files.

;;; Commands:
;;
;; Below are complete command list:
;;
;;  `ansible-mode'
;;    Ansible minor mode.

;;; Code:

;;require
(require 's)
(require 'f)
(require 'cl-lib)
(require 'easy-mmode)

(defgroup ansible-mode nil
  "Ansible minor mode."
  :group 'languages
  :prefix "ansible-")

(defconst ansible-mode-dir (file-name-directory (or load-file-name
                                                    buffer-file-name)))

;;;###autoload
(defvar ansible-mode-key-map
  (make-sparse-keymap)
  "Keymap for Ansible.")

(defvar ansible-mode-hook nil
  "Hook.")

(defvar ansible-mode-section-face 'ansible-mode-section-face)
(defface ansible-mode-section-face
  '((((class color) (min-colors 88) (background dark))
     :foreground "indian red" ))
  "Face for ansible first level section names in playbooks.
Used for vars, tasks, handlers, etc."
  :group 'ansible-mode)

(defvar ansible-mode-task-label-face 'ansible-mode-task-label-face)
(defface ansible-mode-task-label-face
  '((((class color) (min-colors 88) (background dark))  :foreground "green" ))
  "Face for ansible task names in playbooks."
  :group 'ansible-mode)

(defconst ansible-mode-section-keywords-regex
  (concat
   "^ *-? "
   (regexp-opt
    '("environment" "handlers" "hosts" "import_tasks" "include" "include_tasks"
      "post_tasks" "pre_tasks" "role" "roles" "tasks" "vars" "vars_files"
      "vars_prompt")
    t)
   ":")
  "Special keywords used to identify toplevel information in a playbook.")

(defconst ansible-mode-task-keywords-regex
  (concat
   "^ *-? "
   (regexp-opt
    '("a10_server" "a10_service_group" "a10_virtual_server" "acl" "add_host"
      "airbrake_deployment" "alternatives" "apache2_module" "apk" "apt"
      "apt_key" "apt_repository" "apt_rpm" "assemble" "assert" "async_status"
      "at" "authorized_key" "azure" "azure_rm_deployment"
      "azure_rm_networkinterface" "azure_rm_networkinterface_facts"
      "azure_rm_publicipaddress" "azure_rm_publicipaddress_facts"
      "azure_rm_resourcegroup" "azure_rm_resourcegroup_facts"
      "azure_rm_securitygroup" "azure_rm_securitygroup_facts"
      "azure_rm_storageaccount" "azure_rm_storageaccount_facts"
      "azure_rm_storageblob" "azure_rm_subnet" "azure_rm_virtualmachine"
      "azure_rm_virtualmachineimage_facts" "azure_rm_virtualnetwork"
      "azure_rm_virtualnetwork_facts" "bigip_facts" "bigip_gtm_wide_ip"
      "bigip_monitor_http" "bigip_monitor_tcp" "bigip_node" "bigip_pool"
      "bigip_pool_member" "bigip_virtual_server" "bigpanda" "blockinfile"
      "boundary_meter" "bower" "bundler" "bzr" "campfire" "capabilities"
      "circonus_annotation" "cl_bond" "cl_bridge" "cl_img_install"
      "cl_interface" "cl_interface_policy" "cl_license" "cl_ports"
      "clc_aa_policy" "clc_alert_policy" "clc_blueprint_package"
      "clc_firewall_policy" "clc_group" "clc_loadbalancer" "clc_modify_server"
      "clc_publicip" "clc_server" "clc_server_snapshot" "cloudflare_dns"
      "cloudformation" "cloudtrail" "command" "composer" "consul" "consul_acl"
      "consul_kv" "consul_session" "copy" "cpanm" "cron" "cronvar" "crypttab"
      "cs_account" "cs_affinitygroup" "cs_cluster" "cs_configuration"
      "cs_domain" "cs_facts" "cs_firewall" "cs_instance" "cs_instance_facts"
      "cs_instancegroup" "cs_ip_address" "cs_iso" "cs_loadbalancer_rule"
      "cs_loadbalancer_rule_member" "cs_network" "cs_pod" "cs_portforward"
      "cs_project" "cs_resourcelimit" "cs_securitygroup" "cs_securitygroup_rule"
      "cs_sshkeypair" "cs_staticnat" "cs_template" "cs_user" "cs_vmsnapshot"
      "cs_volume" "cs_zone" "cs_zone_facts" "datadog_event" "datadog_monitor"
      "debconf" "debug" "deploy_helper" "digital_ocean" "digital_ocean_domain"
      "digital_ocean_sshkey" "django_manage" "dnf" "dnsimple" "dnsmadeeasy"
      "docker" "docker_container" "docker_image" "docker_image_facts"
      "docker_login" "docker_service" "dpkg_selections" "dynamodb_table"
      "easy_install" "ec2" "ec2_ami" "ec2_ami_copy" "ec2_ami_find" "ec2_asg"
      "ec2_eip" "ec2_elb" "ec2_elb_facts" "ec2_elb_lb" "ec2_eni" "ec2_eni_facts"
      "ec2_facts" "ec2_group" "ec2_instance" "ec2_instance_info" "ec2_key"
      "ec2_lc" "ec2_metric_alarm" "ec2_remote_facts" "ec2_scaling_policy"
      "ec2_snapshot" "ec2_snapshot_facts" "ec2_tag" "ec2_vol" "ec2_vol_facts"
      "ec2_vpc" "ec2_vpc_dhcp_options" "ec2_vpc_igw" "ec2_vpc_net"
      "ec2_vpc_net_facts" "ec2_vpc_route_table" "ec2_vpc_route_table_facts"
      "ec2_vpc_subnet" "ec2_vpc_subnet_facts" "ec2_win_password" "ecs_cluster"
      "ecs_service" "ecs_service_facts" "ecs_task" "ecs_taskdefinition"
      "ejabberd_user" "elasticache" "elasticache_subnet_group"
      "elasticsearch_plugin" "eos_command" "eos_config" "eos_eapi"
      "eos_template" "expect" "facter" "fail" "fetch" "file" "filesystem" "find"
      "firewalld" "flowdock" "gc_storage" "gce" "gce_img" "gce_lb" "gce_net"
      "gce_pd" "gce_tag" "gem" "get_url" "getent" "git" "git_config"
      "github_hooks" "gitlab_group" "gitlab_project" "gitlab_user"
      "gluster_volume" "group" "group_by" "grove" "hall" "haproxy" "hg"
      "hipchat" "homebrew" "homebrew_cask" "homebrew_tap" "hostname" "htpasswd"
      "iam" "iam_cert" "iam_policy" "include_vars" "influxdb_database"
      "influxdb_retention_policy" "ini_file" "ios_command" "ios_config"
      "ios_template" "iosxr_command" "iosxr_config" "iosxr_template"
      "ipify_facts" "iptables" "irc" "jabber" "jboss" "jira" "junos_command"
      "junos_config" "junos_facts" "junos_netconf" "junos_package"
      "junos_template" "kernel_blacklist" "known_hosts" "kubernetes" "layman"
      "librato_annotation" "lineinfile" "linode" "lldp" "locale_gen"
      "logentries" "lvg" "lvol" "lxc_container" "macports" "mail" "make"
      "maven_artifact" "modprobe" "mongodb_parameter" "mongodb_user" "monit"
      "mount" "mqtt" "mysql_db" "mysql_replication" "mysql_user"
      "mysql_variables" "nagios" "netscaler" "newrelic_deployment" "nexmo"
      "nmcli" "npm" "nxos_command" "nxos_config" "nxos_facts" "nxos_feature"
      "nxos_interface" "nxos_ip_interface" "nxos_nxapi" "nxos_ping"
      "nxos_switchport" "nxos_template" "nxos_vlan" "nxos_vrf"
      "nxos_vrf_interface" "nxos_vrrp" "ohai" "open_iscsi" "openbsd_pkg"
      "openvswitch_bridge" "openvswitch_db" "openvswitch_port" "opkg"
      "ops_command" "ops_config" "ops_facts" "ops_template" "os_auth"
      "os_client_config" "os_flavor_facts" "os_floating_ip" "os_group"
      "os_image" "os_image_facts" "os_ironic" "os_ironic_inspect"
      "os_ironic_node" "os_keypair" "os_keystone_domain"
      "os_keystone_domain_facts" "os_keystone_role" "os_network"
      "os_networks_facts" "os_nova_flavor" "os_object" "os_port" "os_port_facts"
      "os_project" "os_project_facts" "os_router" "os_security_group"
      "os_security_group_rule" "os_server" "os_server_actions" "os_server_facts"
      "os_server_volume" "os_subnet" "os_subnets_facts" "os_user"
      "os_user_facts" "os_user_group" "os_user_role" "os_volume" "osx_defaults"
      "osx_say" "ovirt" "package" "pacman" "pagerduty" "pagerduty_alert"
      "pam_limits" "patch" "pause" "pear" "ping" "pingdom" "pip" "pkg5"
      "pkg5_publisher" "pkgin" "pkgng" "pkgutil" "portage" "portinstall"
      "postgresql_db" "postgresql_ext" "postgresql_lang" "postgresql_privs"
      "postgresql_user" "profitbricks" "profitbricks_datacenter"
      "profitbricks_nic" "profitbricks_volume" "profitbricks_volume_attachments"
      "proxmox" "proxmox_template" "puppet" "pushbullet" "pushover"
      "rabbitmq_binding" "rabbitmq_exchange" "rabbitmq_parameter"
      "rabbitmq_plugin" "rabbitmq_policy" "rabbitmq_queue" "rabbitmq_user"
      "rabbitmq_vhost" "raw" "rax" "rax_cbs" "rax_cbs_attachments" "rax_cdb"
      "rax_cdb_database" "rax_cdb_user" "rax_clb" "rax_clb_nodes" "rax_clb_ssl"
      "rax_dns" "rax_dns_record" "rax_facts" "rax_files" "rax_files_objects"
      "rax_identity" "rax_keypair" "rax_meta" "rax_mon_alarm" "rax_mon_check"
      "rax_mon_entity" "rax_mon_notification" "rax_mon_notification_plan"
      "rax_network" "rax_queue" "rax_scaling_group" "rax_scaling_policy" "rds"
      "rds_param_group" "rds_subnet_group" "redhat_subscription" "redis"
      "replace" "rhn_channel" "rhn_register" "riak" "rollbar_deployment"
      "route53" "route53_facts" "route53_health_check" "route53_zone" "rpm_key"
      "s3" "s3_bucket" "s3_lifecycle" "s3_logging" "script" "seboolean"
      "selinux" "selinux_permissive" "sendgrid" "sensu_check" "seport" "service"
      "set_fact" "setup" "shell" "sl_vm" "slack" "slackpkg" "slurp" "snmp_facts"
      "sns" "sns_topic" "solaris_zone" "sqs_queue" "stackdriver" "stat"
      "sts_assume_role" "subversion" "supervisorctl" "svc" "svr4pkg" "swdepot"
      "synchronize" "sysctl" "systemd" "taiga_issue" "template" "twilio"
      "typetalk" "ufw" "unarchive" "uptimerobot" "uri" "urpmi" "user" "vca_fw"
      "vca_nat" "vca_vapp" "vertica_configuration" "vertica_facts"
      "vertica_role" "vertica_schema" "vertica_user" "virt" "virt_net"
      "virt_pool" "vmware_cluster" "vmware_datacenter" "vmware_dns_config"
      "vmware_dvs_host" "vmware_dvs_portgroup" "vmware_dvswitch" "vmware_host"
      "vmware_maintenancemode" "vmware_migrate_vmk" "vmware_portgroup"
      "vmware_target_canonical_facts" "vmware_vm_facts" "vmware_vm_shell"
      "vmware_vm_vss_dvs_migrate" "vmware_vmkernel" "vmware_vmkernel_ip_config"
      "vmware_vsan_cluster" "vmware_vswitch" "vsphere_copy" "vsphere_guest"
      "wait_for" "webfaction_app" "webfaction_db" "webfaction_domain"
      "webfaction_mailbox" "webfaction_site" "win_acl" "win_acl_inheritance"
      "win_chocolatey" "win_copy" "win_dotnet_ngen" "win_environment"
      "win_feature" "win_file" "win_file_version" "win_firewall_rule"
      "win_get_url" "win_group" "win_iis_virtualdirectory"
      "win_iis_webapplication" "win_iis_webapppool" "win_iis_webbinding"
      "win_iis_website" "win_lineinfile" "win_msi" "win_nssm" "win_owner"
      "win_package" "win_ping" "win_reboot" "win_regedit" "win_regmerge"
      "win_scheduled_task" "win_service" "win_share" "win_stat" "win_template"
      "win_timezone" "win_unzip" "win_updates" "win_uri" "win_user"
      "win_webpicmd" "xattr" "xenserver_facts" "yum" "yum_repository"
      "zabbix_group" "zabbix_host" "zabbix_hostmacro" "zabbix_maintenance"
      "zabbix_screen" "zfs" "znode" "zypper" "zypper_repository")
    t)
   ":")
  "List of ansible task names.")

(defconst ansible-mode-keywords-regex
  (concat
   "^ +"
   (regexp-opt
    '("args" "become" "become_user" "connection" "delay" "delegate_to"
      "gather_facts" "local_action" "notify" "register" "retries" "strategy"
      "tags" "tags" "until" "when" "with_dict" "with_fileglob"
      "with_first_found" "with_flattened" "with_indexed_items" "with_ini"
      "with_inventory_hostnames" "with_items" "with_lines" "with_nested"
      "with_random_choice" "with_sequence" "with_subelements" "with_together")
    t)
   ":")
  "Ansible keywords used with tasks.")


(defvar ansible-mode-playbook-font-lock
`((,ansible-mode-section-keywords-regex    (1 ansible-mode-section-face t))
    (,ansible-mode-task-keywords-regex       (1 font-lock-keyword-face t))
    (,ansible-mode-keywords-regex            (1 font-lock-builtin-face t))
    ("^ *- \\(name\\):\\([^#\n]*\\)"
     (1 font-lock-builtin-face t)
     (2 ansible-mode-task-label-face t))
    ("\\({{\\)\\([^}]+\\)\\(}}\\)"
     (1 font-lock-builtin-face t)
     (2 font-lock-function-name-face t)
     (3 font-lock-builtin-face t))
    ("\\({%\\)\\([^}]+\\)\\(%}\\)"
     (1 font-lock-builtin-face t)
     (2 font-lock-function-name-face t)
     (3 font-lock-builtin-face t))
    ("\\({#\\)\\([^}]+\\)\\(#}\\)"
     (1 font-lock-comment-delimiter-face t)
     (2 font-lock-comment-face t)
     (3 font-lock-comment-delimiter-face t)))
  "Font lock definitions for ansible playbooks.")


(defun ansible-mode-add-font-lock ()
  "Extend YAML with syntax highlight for ansible playbooks."
  (interactive)
  (font-lock-add-keywords 'nil ansible-mode-playbook-font-lock 'append)
  (font-lock-flush))

(defun ansible-mode-remove-font-lock ()
  "Add syntax highlight to ansible playbooks."
  (interactive)
  (font-lock-remove-keywords 'nil ansible-mode-playbook-font-lock)
  (font-lock-flush))

;;;###autoload
(define-minor-mode ansible-mode
  "Ansible minor mode."
  :lighter " Ansible"
  :group 'ansible
  (if ansible-mode
      (progn
        (setq minor-mode-map-alist
              (cons (cons 'ansible-mode ansible-mode-key-map)
                    minor-mode-map-alist))
        (ansible-mode-dict-initialize)
        (ansible-mode-remove-font-lock)
        (ansible-mode-add-font-lock)
	(when (featurep 'ansible-yasnippet)
          (ansible-yasnippet-load-snippets)
	  (add-hook 'kill-buffer-hook #'ansible-yasnippet-maybe-unload-snippets nil t))
        (run-hooks 'ansible-mode-hook))
    (ansible-mode-remove-font-lock)
    (when (featurep 'ansible-yasnippet)
      (ansible-yasnippet-maybe-unload-snippets 0))))

;;;###autoload
(defun ansible-mode-dict-initialize ()
  "Initialize Ansible auto-complete."
  (let ((dict-dir (expand-file-name "dict" ansible-mode-dir)))
    (when (and (f-directory? dict-dir) (boundp 'ac-user-dictionary-files))
      (add-to-list 'ac-user-dictionary-files (f-join dict-dir "ansible-mode") t))))

;;;###ansible-lint
(defun ansible-lint-errors ()
  "Replace make -k with ansible-lint, with an UTF-8 locale to avoid crashes."
  (make-local-variable 'compile-command)
  (let ((ansiblelint_command "ansible-lint ") (loc "LANG=C.UTF-8 "))
    (setq compile-command (concat loc ansiblelint_command buffer-file-name))))

(add-hook 'ansible-mode-hook 'ansible-lint-errors)

(provide 'ansible-mode)

;;; ansible-mode.el ends here
