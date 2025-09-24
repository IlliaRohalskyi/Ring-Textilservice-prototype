#!/bin/bash

# filepath: c:\Users\2004l\Desktop\Ring-Textilservice-prototype\destroy.sh

# Exit immediately if a command exits with a non-zero status
set -e

# Load environment variables from .env
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "❌ .env file not found. Please ensure it exists in the project root."
    exit 1
fi

# Navigate to the terraform directory and destroy infrastructure
echo "🚀 Destroying infrastructure..."
cd terraform
terraform destroy -auto-approve
cd ..

echo "✅ Infrastructure destroyed successfully!"