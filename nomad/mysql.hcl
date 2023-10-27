job "mysql" {
    # Specify this job should run in the region named "us". Regions
    # are defined by the Nomad servers' configuration.
    region = "us"

    # Spread the tasks in this job between us-west-1 and us-east-1.
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

    # Configure the job to do rolling updates.
    # Specify this job to have rolling updates, one-at-a-time, with
    # 10 second intervals.
    update {
        # Stagger updates every 10 seconds
        stagger = "10s"

        # Update a single task at a time
        max_parallel = 1
    }

    # A group defines a series of tasks that should be co-located
    # on the same client (host). All tasks within a group will be
    # placed on the same host.
    group "mysql" {
        # Control the number of instances of this groups.
        # Defaults to 1
        count = 1
        # This is similar to replicasets in Kubernetes

        # Restart Policy - This block defines the restart policy for TaskGroups,
        # the attempts value defines the number of restarts Nomad will do if Tasks
        # in this TaskGroup fails in a rolling window of interval duration
        # The delay value makes Nomad wait for that duration to restart after a Task
        # fails or crashes.
        restart {
            interval = "5m"
            attempts = 10
            delay = "25s"
            mode = "delay"
        }
        network {
            mbits = 10

            # Request for a static port
            port "mysql" {
                static = 3306
            }
        }
        service {
            name = "mysql"
            tags = ["global"]
            port = "mysql"
            provider = "nomad"

            check {
                name = "mysql alive"
                type = "tcp"
                interval = "10s"
                timeout = "2s"
            }
        }

        # Define a SQL task to run 
        task "mysql" {
        # Use Docker to run the task.
            driver = "docker"

        config {
            #image = "mysql"

            # The mysql/mysql-server Docker container allows setting the root pwd
            # using a file path
            image = "mysql:5.7"
            network_mode = "host"
            args = [ "--bind-address=0.0.0.0" ]
        }

        template {
            data = <<EOF
    {{- with nomadVar "nomad/jobs/mysql/wp-blog-db-pass" -}}
    MYSQL_ROOT_PASSWORD = {{ .password }}
    MYSQL_ROOT_HOST = "%"
    {{- end -}}
    EOF

            destination = "local/env"
            env         = true
        }

        # We must specify the resources required for
        # this task to ensure it runs on a machine with
        # enough capacity.
        resources {
            cpu = 500
            # Mhz
            memory = 256
            # MB
            }
        }
    }
}
