{
  "runners": [
    %{ for name, config in runners ~}
    %{ if lookup(config, "ip_address", null) != null ~}
    {
      "name": "${name}",
      "host": "${config.ip_address}",
      "user": "${coalesce(config.username, "ubuntu")}",
      "type": %{ if startswith(name, "control") ~}"control_plane"%{ else ~}"worker"%{ endif ~},
      "resources": {
        "cpu": ${config.cpu},
        "memory": ${config.memory},
        "disk": ${config.disk_size_gb}
      }
    }%{ if !last(name) ~},%{ endif ~}
    %{ endif ~}
    %{ endfor ~}
  ]
}
