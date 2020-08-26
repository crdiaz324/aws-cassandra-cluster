resource "aws_ssm_parameter" "admin_user_password" {
    name    = "admin_user_password"
    type    = "SecureString"
    value   = var.admin_user_password

    # tags = merge({
    #     Name            = "${var.tag_environment}-${var.tag_sub_product}-ssm-parameter"
    #     Description     = "Storing the password securely for cassadanra cluster users"
    # }, local.common_tags)
}

resource "aws_ssm_parameter" "application_user_password"{
    name    = "application_user_password"
    type    = "SecureString"
    value   = var.application_user_password

    # tags = merge({
    #     Name            = "${var.tag_environment}-${var.tag_sub_product}-ssm-parameter"
    #     Description     = "Storing the password securely for cassadanra cluster users"
    # }, local.common_tags)
}

resource "aws_ssm_parameter" "monitor_user_password"{
    name    = "monitor_user_password"
    type    = "SecureString"
    value   = var.monitor_user_password

#    tags = merge({
#         Name            = "${var.tag_environment}-${var.tag_sub_product}-ssm-parameter"
#         Description     = "Storing the password securely for cassadanra cluster users"
#     }, local.common_tags)
}



