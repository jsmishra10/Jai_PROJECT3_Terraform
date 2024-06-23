output "auto_scaling_group_name" {
  description = "Auto scaling group name"
  value = aws_autoscaling_group.autoscale.name
}

output "launch_template_id" {
  description = " launch template id"
  value = aws_launch_template.template.id
}

output "load_balancer_id" {
  description = " Load Balancer DNS Name"
  value = aws_elb.load_balancer.dns_name
}

