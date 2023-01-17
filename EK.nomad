job "wiki_elastic" {
  type        = "service"
  datacenters = ["dc1"]

  update {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "180s"
    healthy_deadline = "5m"
    progress_deadline = "10m"
    auto_revert = true
    auto_promote = true
    canary = 1
  }

  group "elasticsearch" {
    count = 1

    network {
        port "http" {
              static = 9200
          }
          port "tcp" {
              static = 9300
          }
    }

    # volume "es_data" {
    #   type      = "host"
    #   read_only = false
    #   source    = "es_data"
    # }

    task "elastic_container" {
      driver = "docker"
      kill_timeout = "600s"
      kill_signal = "SIGTERM"

      env {
        ES_JAVA_OPTS = "-Xms2g -Xmx2g"
        ELASTIC_PASSWORD = "mysecretpassword"
      }

      template {
          data = <<EOH
network.host: 0.0.0.0
cluster.name: wiki_elastic
discovery.type: single-node
xpack.license.self_generated.type: basic
xpack.security.enabled: true
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
        network_mode = "host"
        image = "docker.elastic.co/elasticsearch/elasticsearch:8.3.2"
        command = "elasticsearch"
        ports = ["http","tcp"]
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
          nofile = "65536"
          nproc = "8192"
        }
      }

      service {
        name = "elasticsearch"
	tags = ["global"]
	provider = "nomad"
	port = "http"
	
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
        cpu    = 400
        memory = 512
      }
    }
  
  task "es-cluster-kibana" {
      driver       = "docker"
      kill_timeout = "60s"
      kill_signal  = "SIGTERM"

      config {
        image   = "docker.elastic.co/kibana/kibana:7.6.2"
        command = "kibana"

        # https:#www.elastic.co/guide/en/kibana/current/settings.html
        # https:#www.elastic.co/guide/en/kibana/current/settings-xpack-kb.html
        args = [
          #"--elasticsearch.url=http:#${NOMAD_JOB_NAME}.service.consul:80",
          #"--elasticsearch.url=http:#${NOMAD_JOB_NAME}-kibana.service.consul:9200",
          "--elasticsearch.hosts=${NOMAD_ADDR_elastic_container}",
          "--server.host=0.0.0.0",
          "--server.name=kibana-server",
          "--server.port=${NOMAD_PORT_kibana}",
          #"--path.data=/alloc/data",
          #"--elasticsearch.preserveHost=false",
          "--xpack.monitoring.ui.container.elasticsearch.enabled=false"
          #"--xpack.apm.ui.enabled=false",
          #"--xpack.graph.enabled=false",
          #"--xpack.ml.enabled=false",
        ]
        
        mounts = [
                # sample volume mount
            {
                type = "bind"
                target = "/etc/kibana/" #"/path/in/container"
                source = "/opt/elastic/vol_kibana/config"#"/path/in/host"
                readonly = false
                bind_options {
                    propagation = "rshared"
                }
            }
        ]

      }

      service {
        name = "${NOMAD_JOB_NAME}-kibana"
        port = "kibana"
	provider = "nomad"

        # check {
        #   name     = "http-kibana"
        #   port     = "kibana"
        #   type     = "tcp"
        #   interval = "5s"
        #   timeout  = "4s"
        # }

      resources {
        cpu    = 500
        memory = 512

   
        network {
            mode = "bridge"
            port "kibana" {
                static = 5601
                to     = 5601
               
            }
            #port "http" {}
        }
      }      
    }
  } 
}
}
