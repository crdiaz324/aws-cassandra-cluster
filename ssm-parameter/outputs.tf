output "admin_user_password_arn"{
    value = aws_ssm_parameter.admin_user_password.arn
}

output "application_user_password_arn"{
    value = aws_ssm_parameter.application_user_password.arn
}

output "monitor_user_password_arn"{
    value = aws_ssm_parameter.monitor_user_password.arn
}