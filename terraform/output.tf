output "aws_waf_rule_arn" {
  value = aws_waf_rule.waf_rule.arn
}

output "aws_waf_rule_id" {
  value = aws_waf_rule.waf_rule.id
}

output "aws_waf_web_acl_arn" {
  value = aws_waf_web_acl.waf_acl.arn
}

output "aws_waf_web_acl_id" {
  value = aws_waf_web_acl.waf_acl.id
}

output "aws_waf_rule_group_arn" {
  value = aws_waf_rule_group.rule_group.arn
}

output "aws_waf_rule_group_id" {
  value = aws_waf_rule_group.rule_group.id
}
