job "wordpress" {
  # Specify the region and datacenters this job can run in.
  #region = "eu-central-1"
  #datacenters = ["eu-central-1"]
  datacenters = ["us-east-1"]


  # Service type jobs optimize for long-lived services. This is
  # the default but we can change to batch for short-lived tasks.
  type = "service"

  # Priority controls our access to resources and scheduling priority.
  # This can be 1 to 100, inclusively, and defaults to 50.
  # priority = 50

  # Restrict our job to only linux. We can specify multiple
  # constraints as needed.
  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  # Configure the job to do rolling updates
  update {
    # Stagger updates every 10 seconds
    stagger = "10s"

    # Update a single task at a time
    max_parallel = 1
  }

  # Create a 'wordpress' group. Each task in the group will be
  # scheduled onto the same machine.
  group "wordpress" {
    # Control the number of instances of this groups.
    # Defaults to 1
    count = 1

    # Restart Policy - This block defines the restart policy for TaskGroups,
    # the attempts value defines the number of restarts Nomad will do if Tasks
    # in this TaskGroup fails in a rolling window of interval duration
    # The delay value makes Nomad wait for that duration to restart after a Task
    # fails or crashes.
    restart {
      interval = "5m"
      attempts = 10
      delay    = "25s"
      mode     = "delay"
    }
    network {
        mbits = 10

        # Request for a dynamic port
        port "http" {
            static = 80
        }
    }
    service {
        name = "wordpress"
        tags = ["global"]
        port = "http"
        provider = "nomad"

        check {
          name     = "wordpress running on port 80"
          type     = "http"
          protocol = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }
    # Define a nodejs task to run
    task "wordpress" {
      # Use Docker to run the task.
      driver = "docker"

      # Configure Docker driver with the image
      config {
        image = "wordpress:latest"
        network_mode = "host"
      }
      template {
        data = <<EOF
{{- with nomadVar "nomad/jobs/wordpress/wp-mysql-pass" -}}
WORDPRESS_DB_NAME = {{ .database_name }}
WORDPRESS_DB_USER = {{ .database_user }}
WORDPRESS_DB_PASSWORD = {{ .database_pass }}
{{ range nomadService "database" }}
        WORDPRESS_DB_HOST     = "{{ .Address }}.{{ .Port }}"
{{- end -}}
{{- end -}}
EOF

        # For troubleshooting purposes. Should be written to ${NOMAD_SECRETS_DIR}
        # We right those variables to the environment so the task can read on start up
        destination = "local/env"
        env         = true
      }

      # We must specify the resources required for
      # this task to ensure it runs on a machine with
      # enough capacity.
      resources {
        cpu = 500 # Mhz
        memory = 256 # MB
      }
    }
  }
}