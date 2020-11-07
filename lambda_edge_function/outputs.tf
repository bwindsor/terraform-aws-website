output "arn" {
  value = aws_lambda_function.lambda_edge_function.arn
}

output "qualified_arn" {
  value = aws_lambda_function.lambda_edge_function.qualified_arn
}

output "function_name" {
  value = aws_lambda_function.lambda_edge_function.function_name
}

output "invoke_arn" {
  value = aws_lambda_function.lambda_edge_function.invoke_arn
}
