data "aws_ssm_parameter" "admin_user_password"{
    name                = "admin_user_password"
    with_decryption     = true
}

data "aws_ssm_parameter" "application_user_password" {
     name = "application_user_password"
     with_decryption     = true
}

data "aws_ssm_parameter" "monitor_user_password" {
     name = "monitor_user_password"
     with_decryption     = true
}