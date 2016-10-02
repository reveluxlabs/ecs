# The load balancer that distributes load between the EC2 Instances
resource "aws_elb" "smart_machines_site" {
  name = "smart-machines-site"
  subnets = ["${split(",", var.elb_subnet_ids)}"]
  security_groups = ["${aws_security_group.smart_machines_site_elb.id}"]
  cross_zone_load_balancing = true

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    interval = 30

    # The smart-machines-site has a health check endpoint at the /health URL
    target = "HTTP:${var.smart_machines_site_port}/health"
  }

  listener {
    instance_port = "${var.smart_machines_site_port}"
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}

# The securty group that controls what traffic can go in and out of the ELB
resource "aws_security_group" "smart_machines_site_elb" {
  name = "smart-machines-site-elb"
  description = "The security group for the smart-machines-site ELB"
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

# The ECS Task that specifies what Docker containers we need to run the smart-machines-site.
resource "aws_ecs_task_definition" "smart_machines_site" {
  family = "smart-machines-site"
  container_definitions = <<EOF
[
  {
    "name": "smart-machines-site",
    "image": "${var.smart_machines_site_image}:${var.smart_machines_site_version}",
    "cpu": 256,
    "memory": 768,
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${var.smart_machines_site_port},
        "hostPort": ${var.smart_machines_site_port},
        "protocol": "tcp"
      }
    ],
    "environment": []
  }
]
EOF
}

# A long-running ECS Service for the smart-machines-site Task
resource "aws_ecs_service" "smart_machines_site" {
  name = "smart-machines-site"
  cluster = "${aws_ecs_cluster.reveluxlabs_ha_cluster.id}"
  task_definition = "${aws_ecs_task_definition.smart_machines_site.arn}"
  depends_on = ["aws_iam_role_policy.ecs_service_policy"]
  desired_count = 2
  deployment_minimum_healthy_percent = 50
  iam_role = "${aws_iam_role.ecs_service_role.arn}"

  load_balancer {
    elb_name = "${aws_elb.smart_machines_site.id}"
    container_name = "smart-machines-site"
    container_port = "${var.smart_machines_site_port}"
  }
}