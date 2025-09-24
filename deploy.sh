#!/bin/bash
set -e  # Exit on any error

# Enhanced security: cleanup on any exit
cleanup() {
    unset DB_PASSWORD TF_VAR_data_db_password DB_HOST DB_NAME DB_PORT DB_USER 2>/dev/null || true
    echo -e "${GREEN}🧹 Cleaned up sensitive variables${NC}"
}
trap cleanup EXIT INT TERM

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Ring Textilservice deployment...${NC}"

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}❌ terraform is required but not installed${NC}"; exit 1; }
command -v python >/dev/null 2>&1 || { echo -e "${RED}❌ python is required but not installed${NC}"; exit 1; }

# Check if we're in the right directory (project root)
if [ ! -d "terraform" ] || [ ! -f "terraform/main.tf" ]; then
    echo -e "${RED}❌ terraform/ directory or main.tf not found. Run this script from the project root${NC}"
    exit 1
fi

# Check if .env file exists and load it
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ .env file not found in project root${NC}"
    exit 1
fi

# Enhanced environment variable loading (more secure)
echo -e "${YELLOW}📋 Loading environment variables...${NC}"
set -a  # automatically export variables
source .env
set +a

# Validate required variables
if [ -z "$TF_VAR_data_db_username" ] || [ -z "$TF_VAR_data_db_password" ]; then
    echo -e "${RED}❌ Database credentials not found in .env file${NC}"
    exit 1
fi

# Check for Python dependencies
echo -e "${YELLOW}🐍 Checking Python dependencies...${NC}"
python -c "import psycopg2" 2>/dev/null || {
    echo -e "${YELLOW}📦 Installing libraries...${NC}"
    pip install psycopg2-binary
}

echo -e "${GREEN}✅ Environment loaded${NC}"

# Step 1: Run Terraform
echo -e "${YELLOW}🏗️  Step 1: Deploying infrastructure with Terraform...${NC}"
cd terraform/
terraform init
terraform apply -auto-approve

# Get RDS endpoint from Terraform output using -raw flag
echo -e "${YELLOW}📊 Getting RDS endpoint...${NC}"
DB_HOST=$(terraform output -raw rds_endpoint 2>/dev/null || echo "")
DB_NAME=$(terraform output -raw rds_db_name 2>/dev/null || echo "")
DB_PORT=$(terraform output -raw rds_port 2>/dev/null || echo "")

if [ -z "$DB_HOST" ] || [ -z "$DB_NAME" ]; then
    echo -e "${RED}❌ Could not get RDS endpoint from Terraform outputs${NC}"
    echo -e "${YELLOW}💡 Available outputs:${NC}"
    terraform output
    exit 1
fi

echo -e "${GREEN}✅ Infrastructure deployed successfully${NC}"
echo -e "${GREEN}   Database connection info retrieved${NC}"

# Step 2: Apply database schema using Python
echo -e "${YELLOW}🗄️  Step 2: Creating database schema...${NC}"

# Set environment variables for Python script
export DB_HOST="$DB_HOST"
export DB_PORT="$DB_PORT"
export DB_NAME="$DB_NAME"
export DB_USER="$TF_VAR_data_db_username"
export DB_PASSWORD="$TF_VAR_data_db_password"

# Run Python schema deployment script
echo -e "${YELLOW}📝 Applying database schema...${NC}"
cd ..  # Go back to project root for Python script

if [ -f "src/db/deploy_schema.py" ]; then
    python src/db/deploy_schema.py
    echo -e "${GREEN}✅ Database schema applied successfully${NC}"
else
    echo -e "${RED}❌ Schema deployment script not found at src/db/deploy_schema.py${NC}"
    echo -e "${YELLOW}💡 Current directory: $(pwd)${NC}"
    echo -e "${YELLOW}💡 Looking for: src/db/deploy_schema.py${NC}"
    ls -la src/db/ 2>/dev/null || echo -e "${YELLOW}💡 src/db/ directory not found${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}📋 Summary:${NC}"
echo -e "${GREEN}   ✅ Infrastructure deployed${NC}"
echo -e "${GREEN}   ✅ Database schema created${NC}"
echo ""
echo -e "${YELLOW}🔐 Database credentials are stored in your .env file${NC}"
echo -e "${YELLOW}📖 You can now run your Glue jobs or connect applications to the database${NC}"

# Note: cleanup() will run automatically via trap