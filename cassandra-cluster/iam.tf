resource "aws_iam_role" "ssm_role" {
  
    name               = "ssm_role"
    assume_role_policy = file("./role-policies/assume-role.json")

    tags = merge({
        Name                = "${var.tag_environment}.${var.tag_sub_product}"
        Description         = var.tag_description
    }, local.common_tags)
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm_profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_iam_role_policy" "ssm_policy" {
  name      = "ssm_policy"
  role      = aws_iam_role.ssm_role.id
  policy    =  file("./role-policies/policy.json")
}