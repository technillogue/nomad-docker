data_dir             = "/data/nomad"
disable_update_check = true
enable_syslog        = false
plugin_dir           = "/usr/lib/nomad/plugins"

server {
  enabled          = true
  bootstrap_expect = 1
}

tls {
  http = false # handled by fly
}

client {
  enabled = true

  # CNI-related settings
  cni_config_dir = "/etc/cni"
  cni_path       = "/usr/libexec/cni"

  options {
    # Uncomment to disable some drivers
    #driver.denylist = "java,raw_exec"

    # Disable some fingerprinting
    fingerprint.denylist = "env_aws,env_azure,env_digitalocean,env_gce"
  }
  host_volume "tmp" {
    path      = "/tmp"
    read_only = true
  }
  host_volume "nomad" {
    path      = "/data/nomad"
    read_only = true
  }
}

# Docker Configuration
plugin "docker" {
  volumes {
    enabled = true
  }
}

ui {
  # Uncomment to enable UI, it will listen on port 4646
  enabled = true
}
