job "elastic" {
  type        = "service"
  datacenters = ["dc1"]

  update {
    max_parallel      = 1
    health_check      = "checks"
    min_healthy_time  = "180s"
    healthy_deadline  = "5m"
    progress_deadline = "10m"
    auto_revert       = false
    canary            = 0
  }

  group "elasticsearch" {
    count = 1

    network {
      port "es_port" {
        static = 9200
        to     = 9200
      }
      port "tcp" {
        static = 9300
        to     = 9300
      }
      port "kibana" {
        static = 5601
        to     = 5601
      }
    }

    # volume "es_data" {
    #   type      = "host"
    #   read_only = false
    #   source    = "es_data"
    # }

    task "elastic_container" {
      driver       = "docker"
      kill_timeout = "600s"
      kill_signal  = "SIGTERM"

      env {
        ES_JAVA_OPTS     = "-Xms256m -Xmx1g"
        ELASTIC_PASSWORD = "mysecretpassword"
      }

      template {
        data = <<EOH
network.host: 0.0.0.0
cluster.name: wiki_elastic
discovery.type: single-node
xpack.license.self_generated.type: basic
xpack.security.enabled: false
xpack.monitoring.collection.enabled: true
xpack.security.authc:
    anonymous:
      username: anonymous_user 
      roles: search_agent
      authz_exception: true 
      
http.cors.enabled : true
http.cors.allow-origin: "*"
http.cors.allow-methods: OPTIONS, HEAD, GET, POST, PUT, DELETE
http.cors.allow-credentials: true
http.cors.allow-headers: X-Requested-With, X-Auth-Token, Content-Type, Content-Length, Authorization, Access-Control-Allow-Headers, Accept

path.repo: ["/snapshots"]
          EOH

        destination = "local/elastic/elasticsearch.yml"
      }

      # volume_mount {
      #   volume      = "es_data"
      #   destination = "/usr/share/elasticsearch/data" #<-- in the container
      #   read_only   = false
      # }

      config {
        #network_mode = "host"
        image   = "docker.elastic.co/elasticsearch/elasticsearch:8.6.0"
        command = "elasticsearch"
        ports   = ["es_port", "tcp"]
        volumes = [
          "local/elastic/snapshots:/snapshots",
          "local/elastic/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml",
        ]
        args = [
          "-Ecluster.name=wiki_elastic",
          "-Ediscovery.type=single-node"
        ]

        ulimit {
          memlock = "-1"
          nofile  = "65536"
          nproc   = "8192"
        }
      }

      service {
        name     = "elasticsearch"
        tags     = ["global"]
        provider = "nomad"
        port     = "es_port"

        # check {
        #   name     = "transport-tcp"
        #   port     = "tcp"
        #   type     = "tcp"
        #   interval = "30s"
        #   timeout  = "4s"
        # }

        # check {
        #     name     = "rest-http"
        #     type     = "http"
        #     port     = "http"
        #     path     = "/"
        #     interval = "30s"
        #     timeout  = "4s"
        #     header {
        #       Authorization = ["Basic ZWxhc3RpYzpjaGFuZ2VtZQ=="]
        #     }
        #   }
      }

      resources {
        cpu    = 800
        memory = 1024
      }
    }



    task "es-cluster-kibana" {
      driver       = "docker"
      kill_timeout = "60s"
      kill_signal  = "SIGTERM"

      config {
        image   = "docker.elastic.co/kibana/kibana:8.6.0"
        command = "kibana"
        ports   = ["kibana"]
        # https:#www.elastic.co/guide/en/kibana/current/settings.html
        # https:#www.elastic.co/guide/en/kibana/current/settings-xpack-kb.html
        args = [
          #"--elasticsearch.url=http:#${NOMAD_JOB_NAME}.service.consul:80",
          #"--elasticsearch.url=http:#${NOMAD_JOB_NAME}-kibana.service.consul:9200",
          "--elasticsearch.hosts=http://${NOMAD_ADDR_es_port}",
          #"--elasticsearch.password=mysecretpassword",
          #"--xpack.security.enabled=false",
          "--server.host=0.0.0.0",
          "--server.name=kibana-server",
          "--server.publicBaseUrl=https://sylv-nomad-test.fly.dev:5601",
          "--server.port=${NOMAD_PORT_kibana}",
          #"--path.data=/alloc/data",
          #"--elasticsearch.preserveHost=false",
          "--xpack.monitoring.ui.container.elasticsearch.enabled=false"
          #"--xpack.apm.ui.enabled=false",
          #"--xpack.graph.enabled=false",
          #"--xpack.ml.enabled=false",
        ]

      }


      #       template {
      #           data = <<EOH
      # server.name: kibana
      # server.host: 0.0.0.0
      # server.publicBaseUrl: https://my.kibana.com
      # elasticsearch.hosts: [ "http://my.server.ip:9200" ]
      # monitoring.ui.container.elasticsearch.enabled: true
      # elasticsearch.username: kibana_system
      # elasticsearch.password: 'mykibanapassword'
      #           EOH
      #           destination = "local/kibana/kibana.yml"
      #       }

      service {
        name     = "kibana"
        port     = "kibana"
        provider = "nomad"

        # check {
        #   name     = "http-kibana"
        #   port     = "kibana"
        #   type     = "tcp"
        #   interval = "5s"
        #   timeout  = "4s"
        # }
      }
      resources {
        cpu    = 500
        memory = 768

      }
    }
    volume "tmp_vol" {
      type      = "host"
      read_only = true
      source    = "tmp"
    }

    volume "nomad_vol" {
      type      = "host"
      read_only = true
      source    = "nomad"
    }

    task "filebeat_container" {
      driver       = "docker"
      kill_timeout = "600s"
      kill_signal  = "SIGTERM"
      # autodiscover does not work at all
      template {
        data        = <<EOH
filebeat.inputs:
- type: filestream
  id: logs
  paths:
    - /tmp/nomad/alloc/*/alloc/logs/*
    - /tmp/host/nomad_log
filebeat.autodiscover:
  providers:
    - type: nomad
      hints.enabled: true
      allow_stale: true
      templates:
          config:
            - type: log
              paths:
                - /tmp/nomad/alloc/${data.nomad.allocation.id}/alloc/logs/${data.nomad.task.name}.std*
              exclude_lines: ["^\\s+[\\-`('.|_]"]  # drop asciiart lines
processors:
  - dissect:
      tokenizer: "/tmp/nomad/alloc/%%{alloc_id}/alloc/logs/%%{task_name}.std"
      field: "log.file.path"
      target_prefix: "nomad"  
  - copy_fields:
      fields:
        - from: nomad.task_name
          to: event.dataset
      fail_on_error: false
      ignore_missing: true
output.elasticsearch:
  hosts: ["http://${NOMAD_ADDR_es_port}"]
  username: "elastic"
  password: "mysecretpassword" 
  ssl:
    enabled: false
logging:
  level: debug
  to_files: true
  to_stderr: true
  files:
    path: /tmp
    name: filebeat.log
setup.kibana:
  host: "http://${NOMAD_ADDR_kibana}"
          EOH
        destination = "local/filebeat/filebeat.yml"
      }


      config {
        image = "docker.elastic.co/beats/filebeat:8.6.0"
        # entrypoint = ["/usr/bin/sleep", "1d"]
        # command = "filebeat"
        volumes = [
          "local/filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml",
        ]

        ulimit {
          memlock = "-1"
          nofile  = "65536"
          nproc   = "8192"
        }
      }

      volume_mount {
        volume      = "tmp_vol"
        destination = "/tmp/host"
        read_only   = true
      }

      volume_mount {
        volume      = "nomad_vol"
        destination = "/tmp/nomad"
        read_only   = true
      }

      service {
        name     = "filebeat"
        tags     = ["global"]
        provider = "nomad"
      }

      resources {
        cpu    = 200
        memory = 512
      }
    }
  }

}
