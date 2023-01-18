job "mirror" {
  datacenters = ["dc1"]

  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }
  group "server" {
    count = 1

    # The "network" stanza specifies the network configuration for the allocation
    # including requesting port bindings.
    #
    # For more information and examples on the "network" stanza, please see
    # the online documentation at:
    #
    #     https://www.nomadproject.io/docs/job-specification/network
    #
    network {
      port "web" {
	static = 8080
        to = 3000
      }
    }

    # The "service" stanza instructs Nomad to register this task as a service
    # in the service discovery engine, which is currently Nomad or Consul. This
    # will make the service discoverable after Nomad has placed it on a host and
    # port.
    #
    # For more information and examples on the "service" stanza, please see
    # the online documentation at:
    #
    #     https://www.nomadproject.io/docs/job-specification/service
    #
    service {
      name     = "mirror"
      tags     = ["global", "server"]
      port     = "web"
      provider = "nomad"

      # The "check" stanza instructs Nomad to create a Consul health check for
      # this service. A sample check is provided here for your convenience;
      # uncomment it to enable it. The "check" stanza is documented in the
      # "service" stanza documentation.

      # check {
      #   name     = "alive"
      #   type     = "tcp"
      #   interval = "10s"
      #   timeout  = "2s"
      # }

    }

    # The "restart" stanza configures a group's behavior on task failure. If
    # left unspecified, a default restart policy is used based on the job type.
    #
    # For more information and examples on the "restart" stanza, please see
    # the online documentation at:
    #
    #     https://www.nomadproject.io/docs/job-specification/restart
    #
    restart {
      # The number of attempts to run the job within the specified interval.
      attempts = 2
      interval = "30m"

      # The "delay" parameter specifies the duration to wait before restarting
      # a task after it has failed.
      delay = "15s"

      # The "mode" parameter controls what happens when a task has restarted
      # "attempts" times within the interval. "delay" mode delays the next
      # restart until the next interval. "fail" mode does not restart the task
      # if "attempts" has been hit within the interval.
      mode = "fail"
    }

    # The "ephemeral_disk" stanza instructs Nomad to utilize an ephemeral disk
    # instead of a hard disk requirement. Clients using this stanza should
    # not specify disk requirements in the resources stanza of the task. All
    # tasks in this group will share the same ephemeral disk.
    #
    # For more information and examples on the "ephemeral_disk" stanza, please
    # see the online documentation at:
    #
    #     https://www.nomadproject.io/docs/job-specification/ephemeral_disk
    #
    ephemeral_disk {
      # When sticky is true and the task group is updated, the scheduler
      # will prefer to place the updated allocation on the same node and
      # will migrate the data. This is useful for tasks that store data
      # that should persist across allocation updates.
      # sticky = true
      #
      # Setting migrate to true results in the allocation directory of a
      # sticky allocation directory to be migrated.
      # migrate = true
      #
      # The "size" parameter specifies the size in MB of shared ephemeral disk
      # between tasks in the group.
      size = 300
    }

    # The "affinity" stanza enables operators to express placement preferences
    # based on node attributes or metadata.
    #
    # For more information and examples on the "affinity" stanza, please
    # see the online documentation at:
    #
    #     https://www.nomadproject.io/docs/job-specification/affinity
    #
    # affinity {
    # attribute specifies the name of a node attribute or metadata
    # attribute = "${node.datacenter}"


    # value specifies the desired attribute value. In this example Nomad
    # will prefer placement in the "us-west1" datacenter.
    # value  = "us-west1"


    # weight can be used to indicate relative preference
    # when the job has more than one affinity. It defaults to 50 if not set.
    # weight = 100
    #  }


    # The "spread" stanza allows operators to increase the failure tolerance of
    # their applications by specifying a node attribute that allocations
    # should be spread over.
    #
    # For more information and examples on the "spread" stanza, please
    # see the online documentation at:
    #
    #     https://www.nomadproject.io/docs/job-specification/spread
    #
    # spread {
    # attribute specifies the name of a node attribute or metadata
    # attribute = "${node.datacenter}"


    # targets can be used to define desired percentages of allocations
    # for each targeted attribute value.
    #
    #   target "us-east1" {
    #     percent = 60
    #   }
    #   target "us-west1" {
    #     percent = 40
    #   }
    #  }

    # The "task" stanza creates an individual unit of work, such as a Docker
    # container, web application, or batch processing.
    #
    # For more information and examples on the "task" stanza, please see
    # the online documentation at:
    #
    #     https://www.nomadproject.io/docs/job-specification/task
    #
    task "mirror" {
      # The "driver" parameter specifies the task driver that should be used to
      # run the task.
      driver = "docker"

      # The "config" stanza specifies the driver configuration, which is passed
      # directly to the driver to start the task. The details of configurations
      # are specific to each driver, so please see specific driver
      # documentation for more information.
      config {
        image = "technillogue/mirror:latest"
        ports = ["web"]

        # The "auth_soft_fail" configuration instructs Nomad to try public
        # repositories if the task fails to authenticate when pulling images
        # and the Docker driver has an "auth" configuration block.
        auth_soft_fail = true
      }

      # The "artifact" stanza instructs Nomad to download an artifact from a
      # remote source prior to starting the task. This provides a convenient
      # mechanism for downloading configuration files or data needed to run the
      # task. It is possible to specify the "artifact" stanza multiple times to
      # download multiple artifacts.
      #
      # For more information and examples on the "artifact" stanza, please see
      # the online documentation at:
      #
      #     https://www.nomadproject.io/docs/job-specification/artifact
      #
      # artifact {
      #   source = "http://foo.com/artifact.tar.gz"
      #   options {
      #     checksum = "md5:c4aa853ad2215426eb7d70a21922e794"
      #   }
      # }


      # The "logs" stanza instructs the Nomad client on how many log files and
      # the maximum size of those logs files to retain. Logging is enabled by
      # default, but the "logs" stanza allows for finer-grained control over
      # the log rotation and storage configuration.
      #
      # For more information and examples on the "logs" stanza, please see
      # the online documentation at:
      #
      #     https://www.nomadproject.io/docs/job-specification/logs
      #
      # logs {
      #   max_files     = 10
      #   max_file_size = 15
      # }

      # The "resources" stanza describes the requirements a task needs to
      # execute. Resource requirements include memory, cpu, and more.
      # This ensures the task will execute on a machine that contains enough
      # resource capacity.
      #
      # For more information and examples on the "resources" stanza, please see
      # the online documentation at:
      #
      #     https://www.nomadproject.io/docs/job-specification/resources
      #
      resources {
        cpu    = 250 # 500 MHz
        memory = 128 # 256MB
      }


      # The "template" stanza instructs Nomad to manage a template, such as
      # a configuration file or script. This template can optionally pull data
      # from Consul or Vault to populate runtime configuration data.
      #
      # For more information and examples on the "template" stanza, please see
      # the online documentation at:
      #
      #     https://www.nomadproject.io/docs/job-specification/template
      #
      # template {
      #   data          = "---\nkey: {{ key \"service/my-key\" }}"
      #   destination   = "local/file.yml"
      #   change_mode   = "signal"
      #   change_signal = "SIGHUP"
      # }

      # The "template" stanza can also be used to create environment variables
      # for tasks that prefer those to config files. The task will be restarted
      # when data pulled from Consul or Vault changes.
      #
      # template {
      #   data        = "KEY={{ key \"service/my-key\" }}"
      #   destination = "local/file.env"
      #   env         = true
      # }

      # The "vault" stanza instructs the Nomad client to acquire a token from
      # a HashiCorp Vault server. The Nomad servers must be configured and
      # authorized to communicate with Vault. By default, Nomad will inject
      # The token into the job via an environment variable and make the token
      # available to the "template" stanza. The Nomad client handles the renewal
      # and revocation of the Vault token.
      #
      # For more information and examples on the "vault" stanza, please see
      # the online documentation at:
      #
      #     https://www.nomadproject.io/docs/job-specification/vault
      #
      # vault {
      #   policies      = ["cdn", "frontend"]
      #   change_mode   = "signal"
      #   change_signal = "SIGHUP"
      # }

      # Controls the timeout between signalling a task it will be killed
      # and killing the task. If not set a default is used.
      # kill_timeout = "20s"
    }
  }
}
