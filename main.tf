data "archive_file" "zip" {
  type             = "zip"
  source_dir       = "${path.module}/src"
  output_path      = "security-compliance-checker.zip"
  output_file_mode = "0666"
}

# TODO: use publicly available terraform resource
# module "lambda_function_role" {
#   source             = ""
#   role_name          = "security-compliance-checker-role"
#   assume_role_policy = templatefile("${path.module}/docs/assume_role_policy.json", { services = "lambda.amazonaws.com" })
#   policy             = templatefile("${path.module}/docs/compliance_checker.json", { description = "Access config" }) // how do attach arn to this policy dynamically?
#   policy_name        = "security-compliance-checker-policy"
#   role_description   = "Allow access to AWS config"
# }

resource "aws_lambda_function" "security-compliance-checker" {
  function_name    = "security-compliance-checker"
  description      = "Parses compliance trend data and uploads to S3."
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role             = module.lambda_function_role.arn
  handler          = "complianceTracker.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900
  memory_size      = 512
  tags = {
    owner     = ""
    managedby = "Terraform"
    app       = "compliance-checker"
    contact   = ""
  }
  environment {
    variables = {
      #total_control_findings_by_generator_id_arn        = aws_securityhub_insight.total_control_findings_by_generator_id.arn
      total_control_findings_by_generator_id_a_g_arn    = aws_securityhub_insight.total_control_findings_by_generator_id_a_g.arn
      total_control_findings_by_generator_id_h_n_arn    = aws_securityhub_insight.total_control_findings_by_generator_id_h_n.arn
      total_control_findings_by_generator_id_o_u_arn    = aws_securityhub_insight.total_control_findings_by_generator_id_o_u.arn
      total_control_findings_by_generator_id_v_z_arn    = aws_securityhub_insight.total_control_findings_by_generator_id_v_z.arn
      total_control_findings_by_account_id_arn          = aws_securityhub_insight.total_control_findings_by_account_id.arn
      total_control_findings_by_resource_arn            = aws_securityhub_insight.total_control_findings_by_resource.arn
      total_control_findings_by_severity_arn            = aws_securityhub_insight.total_control_findings_by_severity.arn
      #total_failed_control_findings_by_generator_id_arn = aws_securityhub_insight.total_failed_control_findings_by_generator_id.arn
      total_failed_control_findings_by_generator_id_a_f_arn = aws_securityhub_insight.total_failed_control_findings_by_generator_id_a_f.arn
      total_failed_control_findings_by_generator_id_g_l_arn = aws_securityhub_insight.total_failed_control_findings_by_generator_id_g_l.arn
      total_failed_control_findings_by_generator_id_m_r_arn = aws_securityhub_insight.total_failed_control_findings_by_generator_id_m_r.arn
      total_failed_control_findings_by_generator_id_s_x_arn = aws_securityhub_insight.total_failed_control_findings_by_generator_id_s_x.arn
      total_failed_control_findings_by_generator_id_y_z_arn = aws_securityhub_insight.total_failed_control_findings_by_generator_id_y_z.arn
      total_failed_control_findings_by_account_id_arn   = aws_securityhub_insight.total_failed_control_findings_by_account_id.arn
      total_failed_control_findings_by_resource_arn     = aws_securityhub_insight.total_failed_control_findings_by_resource.arn
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_security_compliance_checker" {
  statement_id  = "AllowComplianceCheckerExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security-compliance-checker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rule.arn
}

resource "aws_cloudwatch_event_target" "target" {
  target_id = "Weekly-Security-Compliance-Target"
  arn       = aws_lambda_function.security-compliance-checker.arn
  rule      = aws_cloudwatch_event_rule.rule.name
}

resource "aws_cloudwatch_event_rule" "rule" {
  name                = "Weekly-Security-Compliance-Rule"
  description         = "Runs the security-compliance-checker once every week."
  schedule_expression = "rate(7 days)"
}

# resource "aws_securityhub_insight" "total_control_findings_by_generator_id" {
#   name               = "total_control_findings_by_generator_id"
#   group_by_attribute = "GeneratorId"
#   filters {
#     product_name {
#       comparison = "EQUALS"
#       value      = "Security Hub"
#     }
#     workflow_status {
#       comparison = "NOT_EQUALS"
#       value      = "SUPPRESSED"
#     }
#     record_state {
#       comparison = "EQUALS"
#       value      = "ACTIVE"
#     }
#   }
# }

resource "aws_securityhub_insight" "total_control_findings_by_generator_id_a_g" {
  name               = "total_control_findings_by_generator_id_a_g"
  group_by_attribute = "GeneratorId"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/A" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/B" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/C" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/D" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/Z" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/F" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/G" 
    }
  }
}

resource "aws_securityhub_insight" "total_control_findings_by_generator_id_h_n" {
  name               = "total_control_findings_by_generator_id_h_n"
  group_by_attribute = "GeneratorId"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/H" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/I" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/J" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/K" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/L" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/M" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/N" 
    }
  }
}

resource "aws_securityhub_insight" "total_control_findings_by_generator_id_o_u" {
  name               = "total_control_findings_by_generator_id_o_u"
  group_by_attribute = "GeneratorId"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/O" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/P" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/Q" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/R" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/S" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/T" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/U" 
    }
  }
}

resource "aws_securityhub_insight" "total_control_findings_by_generator_id_v_z" {
  name               = "total_control_findings_by_generator_id_v_z"
  group_by_attribute = "GeneratorId"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/V" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/W" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/X" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/Y" 
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/E" 
    }
  }
}

resource "aws_securityhub_insight" "total_failed_control_findings_by_generator_id_a_f" {
  name               = "total_failed_control_findings_by_generator_id_a_f"
  group_by_attribute = "GeneratorId"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/A"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/B"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/C"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/D"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/E"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/F"
    }
  }
}

resource "aws_securityhub_insight" "total_failed_control_findings_by_generator_id_g_l" {
  name               = "total_failed_control_findings_by_generator_id_g_l"
  group_by_attribute = "GeneratorId"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/G"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/H"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/I"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/J"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/K"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/L"
    }
  }
}

resource "aws_securityhub_insight" "total_failed_control_findings_by_generator_id_m_r" {
  name               = "total_failed_control_findings_by_generator_id_m_r"
  group_by_attribute = "GeneratorId"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/M"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/N"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/O"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/P"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/Q"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/R"
    }
  }
}

resource "aws_securityhub_insight" "total_failed_control_findings_by_generator_id_s_x" {
  name               = "total_failed_control_findings_by_generator_id_s_x"
  group_by_attribute = "GeneratorId"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/S"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/T"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/U"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/V"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/W"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/X"
    }
  }
}

resource "aws_securityhub_insight" "total_failed_control_findings_by_generator_id_y_z" {
  name               = "total_failed_control_findings_by_generator_id_y_z"
  group_by_attribute = "GeneratorId"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/Y"
    }
    generator_id {
      comparison = "PREFIX"
      value      = "security-control/Z"
    }
  }
}

resource "aws_securityhub_insight" "total_control_findings_by_account_id" {
  name               = "total_control_findings_by_account_id"
  group_by_attribute = "AwsAccountId"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }
}

resource "aws_securityhub_insight" "total_failed_control_findings_by_account_id" {
  name               = "total_failed_control_findings_by_account_id"
  group_by_attribute = "AwsAccountId"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
  }
}

resource "aws_securityhub_insight" "total_control_findings_by_resource" {
  name               = "total_control_findings_by_resource"
  group_by_attribute = "ResourceType"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }
}

resource "aws_securityhub_insight" "total_failed_control_findings_by_resource" {
  name               = "total_failed_control_findings_by_resource"
  group_by_attribute = "ResourceType"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
    compliance_status {
      comparison = "EQUALS"
      value      = "FAILED"
    }
  }
}

resource "aws_securityhub_insight" "total_control_findings_by_severity" {
  name               = "total_control_findings_by_severity"
  group_by_attribute = "SeverityLabel"
  filters {
    product_name {
      comparison = "EQUALS"
      value      = "Security Hub"
    }
    workflow_status {
      comparison = "NOT_EQUALS"
      value      = "SUPPRESSED"
    }
    record_state {
      comparison = "EQUALS"
      value      = "ACTIVE"
    }
  }
}