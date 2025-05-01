[masters]
%{ for name, config in masters ~}
${name} ansible_host=${config.ip_address}
%{ endfor ~}

[workers]
%{ for name, config in workers ~}
${name} ansible_host=${config.ip_address}
%{ endfor ~}

[k8s_cluster:children]
masters
workers

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3
rke2_token=${rke2_token}