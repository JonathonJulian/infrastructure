[runners]
%{ for name, config in runners ~}
${name} ansible_host=${config.ip_address}
%{ endfor ~}

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_python_interpreter=/usr/bin/python3