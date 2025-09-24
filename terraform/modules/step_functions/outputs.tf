output "step_function_arn" {
  description = "ARN of the Step Function state machine"
  value       = aws_sfn_state_machine.data_processing_workflow.arn
}

output "step_function_name" {
  description = "Name of the Step Function state machine"
  value       = aws_sfn_state_machine.data_processing_workflow.name
}
