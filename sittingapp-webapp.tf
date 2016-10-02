# The load balancer that distributes load between the EC2 Instances
resource "aws_elb" "sittingapp_webapp" {
  name = "sittingapp-webapp"
  subnets = ["${split(",", var.elb_subnet_ids)}"]
  security_groups = ["${aws_security_group.sittingapp_webapp_elb.id}"]
  cross_zone_load_balancing = true

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    interval = 30

    # The sittingapp-webapp has a health check endpoint at the /health URL
    target = "HTTP:${var.sittingapp_webapp_port}/health"
  }

  listener {
    instance_port = "${var.sittingapp_webapp_port}"
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}

# The securty group that controls what traffic can go in and out of the ELB
resource "aws_security_group" "sittingapp_webapp_elb" {
  name = "sittingapp-webapp-elb"
  description = "The security group for the sittingapp-webapp ELB"
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

# The ECS Task that specifies what Docker containers we need to run the sittingapp-webapp.
resource "aws_ecs_task_definition" "sittingapp_webapp" {
  family = "sittingapp-webapp"
  container_definitions = <<EOF
[
  {
    "name": "sittingapp-webapp",
    "image": "${var.sittingapp_webapp_image}:${var.sittingapp_webapp_version}",
    "cpu": 256,
    "memory": 768,
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${var.sittingapp_webapp_port},
        "hostPort": ${var.sittingapp_webapp_port},
        "protocol": "tcp"
      }
    ],
    "environment": []
  }
]
EOF
}

# A long-running ECS Service for the sittingapp-webapp Task
resource "aws_ecs_service" "sittingapp_webapp" {
  name = "sittingapp-webapp"
  cluster = "${aws_ecs_cluster.reveluxlabs_ha_cluster.id}"
  task_definition = "${aws_ecs_task_definition.sittingapp_webapp.arn}"
  depends_on = ["aws_iam_role_policy.ecs_service_policy"]
  desired_count = 2
  deployment_minimum_healthy_percent = 50
  iam_role = "${aws_iam_role.ecs_service_role.arn}"

  load_balancer {
    elb_name = "${aws_elb.sittingapp_webapp.id}"
    container_name = "sittingapp-webapp"
    container_port = "${var.sittingapp_webapp_port}"
  }
}