[masters]
%{ for name, config in masters ~}
%{ if lookup(config, "ip_address", null) != null ~}
${name} ansible_host=${config.ip_address} ansible_user=${coalesce(config.username, "ubuntu")}
%{ endif ~}
%{ endfor ~}

[workers]
%{ for name, config in workers ~}
%{ if lookup(config, "ip_address", null) != null ~}
${name} ansible_host=${config.ip_address} ansible_user=${coalesce(config.username, "ubuntu")}
%{ endif ~}
%{ endfor ~}

[k8s_cluster:children]
masters
workers

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
rke2_token=${rke2_token}
