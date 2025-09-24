lint:
	pylint src test

format:
	@echo "Running black..."
	@black .
	@echo "Running isort..."
	@isort .
	@echo "Formatting complete!"

# Deploy everything (build image, push to ECR, terraform apply)
deploy:
	chmod +x deploy.sh
	./deploy.sh | tee .last_deploy.log

destroy:
	chmod +x destroy.sh
	./destroy.sh | tee .last_destroy.log

pip-export:
	uv export --format requirements-txt > requirements.txt
	@echo "✅ requirements.txt generated successfully!"

.PHONY: lint format deploy destroy