output "reveluxlabs_site_url" {
  value = "http://${aws_elb.reveluxlabs_site.dns_name}:${var.reveluxlabs_site_port}"
}

output "smart_machines_site_url" {
  value = "http://${aws_elb.smart_machines_site.dns_name}:${var.smart_machines_site_port}"
}

output "sittingapp_webapp_url" {
  value = "http://${aws_elb.sittingapp_webapp.dns_name}:${var.sittingapp_webapp_port}"
}