# The load balancer that distributes load between the EC2 Instances
resource "aws_elb" "reveluxlabs_site" {
  name = "reveluxlabs-site"
  subnets = ["${split(",", var.elb_subnet_ids)}"]
  security_groups = ["${aws_security_group.reveluxlabs_site_elb.id}"]
  cross_zone_load_balancing = true

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    interval = 30

    # The reveluxlabs-site has a health check endpoint at the /health URL
    target = "HTTP:${var.reveluxlabs_site_port}/health"
  }

  listener {
    instance_port = "${var.reveluxlabs_site_port}"
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}

# The securty group that controls what traffic can go in and out of the ELB
resource "aws_security_group" "reveluxlabs_site_elb" {
  name = "reveluxlabs-site-elb"
  description = "The security group for the reveluxlabs-site ELB"
  vpc_id = "${var.vpc_id}"

  # Outbound Everything
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP from anywhere
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The ECS Task that specifies what Docker containers we need to run the reveluxlabs-site.
# Note the SINATRA_BACKEND_PORT environment variable which we point to the sinatra-backend ELB as a simple "service
# discovery" mechanism. The format replicates the behavior of Docker links, which we use in the docker-compose.yml file,
# so the same approach works in both prod and dev. For more info, see:
# https://docs.docker.com/engine/userguide/networking/default_network/dockerlinks/#environment-variables
resource "aws_ecs_task_definition" "reveluxlabs_site" {
  family = "reveluxlabs-site"
  container_definitions = <<EOF
[
  {
    "name": "reveluxlabs-site",
    "image": "${var.reveluxlabs_site_image}:${var.reveluxlabs_site_version}",
    "cpu": 256,
    "memory": 768,
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${var.reveluxlabs_site_port},
        "hostPort": ${var.reveluxlabs_site_port},
        "protocol": "tcp"
      }
    ],
    "environment": []
  }
]
EOF
}

# A long-running ECS Service for the reveluxlabs site
resource "aws_ecs_service" "reveluxlabs_site" {
  name = "reveluxlabs-site"
  cluster = "${aws_ecs_cluster.reveluxlabs_ha_cluster.id}"
  task_definition = "${aws_ecs_task_definition.reveluxlabs_site.arn}"
  depends_on = ["aws_iam_role_policy.ecs_service_policy"]
  desired_count = 2
  deployment_minimum_healthy_percent = 50
  iam_role = "${aws_iam_role.ecs_service_role.arn}"

  load_balancer {
    elb_name = "${aws_elb.reveluxlabs_site.id}"
    container_name = "reveluxlabs-site"
    container_port = "${var.reveluxlabs_site_port}"
  }
}