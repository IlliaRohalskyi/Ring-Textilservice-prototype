output "glue_job_name" {
  description = "Name of the Glue job created in the compute module"
  value       = aws_glue_job.data_processing_job.name
}