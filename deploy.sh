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

# Step 2: Deploy database schema using Lambda
echo -e "${YELLOW}🗄️  Step 2: Creating database schema...${NC}"

# Get Lambda function name from Terraform output
LAMBDA_FUNCTION_NAME=$(terraform output -raw lambda_function_name 2>/dev/null || echo "")

if [ -z "$LAMBDA_FUNCTION_NAME" ]; then
    echo -e "${RED}❌ Could not get Lambda function name from Terraform outputs${NC}"
    echo -e "${YELLOW}💡 Available outputs:${NC}"
    terraform output
    exit 1
fi

echo -e "${YELLOW}📝 Invoking Lambda function for schema deployment...${NC}"
echo -e "${YELLOW}   Function: $LAMBDA_FUNCTION_NAME${NC}"

# Invoke Lambda function
LAMBDA_RESULT=$(aws lambda invoke \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --payload '{}' \
    --output text \
    --query 'StatusCode' \
    /tmp/lambda_response.json 2>/dev/null)

if [ "$LAMBDA_RESULT" = "200" ]; then
    echo -e "${GREEN}✅ Lambda invocation successful${NC}"
    
    # Show Lambda response
    if [ -f "/tmp/lambda_response.json" ]; then
        echo -e "${YELLOW}📄 Lambda response:${NC}"
        cat /tmp/lambda_response.json | jq '.' 2>/dev/null || cat /tmp/lambda_response.json
        rm -f /tmp/lambda_response.json
    fi
    
    echo -e "${GREEN}✅ Database schema deployed successfully via Lambda${NC}"
else
    echo -e "${RED}❌ Lambda invocation failed with status: $LAMBDA_RESULT${NC}"
    
    if [ -f "/tmp/lambda_response.json" ]; then
        echo -e "${YELLOW}� Lambda error response:${NC}"
        cat /tmp/lambda_response.json
        rm -f /tmp/lambda_response.json
    fi
    
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