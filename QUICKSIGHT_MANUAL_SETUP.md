# QuickSight Manual Setup Guide for Ring Textilservice

This guide provides step-by-step instructions for setting up QuickSight with your Ring Textilservice database after the Terraform infrastructure has been deployed.

## 🚀 Prerequisites (Already Done by Terraform)

The following infrastructure components have been automatically created:
- ✅ IAM Role for QuickSight VPC access
- ✅ Security groups for database connectivity
- ✅ Secrets Manager secret with database credentials
- ✅ Network security rules for QuickSight-to-RDS communication

## 📋 Manual Setup Steps

### Step 1: Sign Up for QuickSight

1. **Navigate to QuickSight**
   ```
   https://quicksight.aws.amazon.com/
   ```

2. **Sign up for QuickSight Account**
   - Choose **Standard Edition** (free tier available)
   - Select your AWS region (ensure it matches your RDS region)
   - Complete the account setup process

3. **Configure QuickSight Permissions**
   - During setup, grant QuickSight access to:
     - Amazon S3 (for potential data sources)
     - Amazon RDS (for database connections)
     - Amazon VPC (for private network access)

### Step 2: Create VPC Connection

1. **Open QuickSight Console**
   - Go to **Manage QuickSight** → **Security & permissions**
   - Select **VPC connections**

2. **Add New VPC Connection**
   - Click **Add VPC connection**
   - **Connection Name**: `Ring-Textilservice-VPC-Connection`
   - **VPC ID**: `[Get from Terraform output: vpc_id]`
   - **Subnet IDs**: `[Get from Terraform output: quicksight_subnet_ids]`
   - **Security Group IDs**: `[Get from Terraform output: quicksight_security_group_id]`
   - **IAM Role ARN**: `[Get from Terraform output: quicksight_vpc_role_arn]`

3. **Test VPC Connection**
   - Wait for connection status to show **Available**
   - If failed, check security group rules and IAM permissions

### Step 3: Create Database Data Source

1. **Navigate to Data Sources**
   - Go to **Datasets** → **New dataset**
   - Select **PostgreSQL**

2. **Configure Database Connection**
   - **Data source name**: `Ring Textilservice Database`
   - **Connection type**: **VPC Connection**
   - **VPC connection**: Select `Ring-Textilservice-VPC-Connection` (created in Step 2)
   - **Database server**: `[Get from Terraform output: rds_endpoint]`
   - **Port**: `5432`
   - **Database**: `[Get from Terraform output: rds_db_name]`
   - **Username**: `[Check terraform.tfvars for data_db_username]`
   - **Password**: `[Check terraform.tfvars for data_db_password]`

3. **Test Connection**
   - Click **Validate connection**
   - Ensure connection is successful before proceeding

### Step 4: Create Datasets for Each Table

Create individual datasets for each table in your database:

#### Dataset 1: Overview Production Data
- **Dataset name**: `Overview Production Metrics`
- **Table**: `overview`
- **Import to SPICE**: Recommended for better performance
- **Key columns to verify**:
  - `datum` (Date)
  - `tonnage_gesamt` (Total Tonnage)
  - `wasser_gesamt` (Total Water Usage)
  - `effizienz_faktor` (Efficiency Factor)

#### Dataset 2: Fleet Performance
- **Dataset name**: `Fleet Performance Metrics`
- **Table**: `fleet`
- **Key columns to verify**:
  - `datum` (Date)
  - `fahrstunden_gesamt` (Total Driving Hours)
  - `km_gesamt` (Total Kilometers)
  - `fahrzeuge_aktiv` (Active Vehicles)

#### Dataset 3: Washing Machine Utilization
- **Dataset name**: `Washing Machine Metrics`
- **Table**: `washing_machines`
- **Key columns to verify**:
  - `datum` (Date)
  - `ladungen_gesamt` (Total Loads)
  - `auslastung_prozent` (Utilization Percentage)

#### Dataset 4: Drying Equipment Usage
- **Dataset name**: `Drying Equipment Metrics`
- **Table**: `drying`
- **Key columns to verify**:
  - `datum` (Date)
  - `trockenzyklen_gesamt` (Total Drying Cycles)
  - `energieverbrauch_kwh` (Energy Consumption kWh)

### Step 5: Create Simple Visualizations

#### Visualization 1: Daily Production Trend
1. **Create New Analysis** from `Overview Production Metrics` dataset
2. **Chart Type**: Line Chart
3. **Configuration**:
   - **X-axis**: `datum` (drag to X-axis)
   - **Value**: `tonnage_gesamt` (drag to Value)
   - **Title**: "Daily Production Volume Trend"
4. **Formatting**:
   - Format Y-axis as numbers with proper units
   - Add trend line if desired

#### Visualization 2: Production Efficiency Dashboard
1. **Chart Type**: KPI Cards (create 3 separate KPI visuals)
2. **KPI 1 - Total Production**:
   - **Value**: Sum of `tonnage_gesamt`
   - **Title**: "Total Production (Tonnes)"
3. **KPI 2 - Water Efficiency**:
   - **Value**: Average of `effizienz_faktor`
   - **Title**: "Average Efficiency Factor"
4. **KPI 3 - Total Water Usage**:
   - **Value**: Sum of `wasser_gesamt`
   - **Title**: "Total Water Used (L)"

#### Visualization 3: Fleet Utilization
1. **Create New Analysis** from `Fleet Performance Metrics` dataset
2. **Chart Type**: Combo Chart (Bar + Line)
3. **Configuration**:
   - **X-axis**: `datum`
   - **Bars**: `fahrstunden_gesamt` (Total Driving Hours)
   - **Line**: `fahrzeuge_aktiv` (Active Vehicles)
   - **Title**: "Fleet Utilization Overview"

#### Visualization 4: Equipment Performance
1. **Chart Type**: Clustered Bar Chart
2. **Combine datasets** (use calculated fields or join datasets)
3. **Configuration**:
   - **X-axis**: `datum`
   - **Values**: 
     - `ladungen_gesamt` (Washing loads)
     - `trockenzyklen_gesamt` (Drying cycles)
   - **Title**: "Daily Equipment Usage"

### Step 6: Create Comprehensive Dashboard

1. **Create New Dashboard**
   - **Name**: `Ring Textilservice Operations Dashboard`
   - **Description**: `Overview of production, fleet, and equipment metrics`

2. **Add Visualizations to Dashboard**
   - Add all created visualizations
   - Arrange in logical layout (production metrics at top, operational metrics below)

3. **Configure Dashboard Filters**
   - Add **Date Range Filter** for all visuals
   - Add **Month/Quarter Filter** for trend analysis
   - Set default filter to "Last 30 days"

4. **Set Auto-Refresh**
   - Configure dashboard to refresh automatically
   - Recommended: Daily refresh to get latest ETL data

### Step 7: Share and Permissions

1. **Share Dashboard**
   - Click **Share** → **Share dashboard**
   - Add users/groups who need access
   - Set appropriate permissions (Viewer/Co-owner)

2. **Schedule Email Reports** (Optional)
   - Set up automated email reports for stakeholders
   - Configure weekly/monthly summary reports

## 🔧 Getting Connection Details

Run these commands to get the required connection information:

```bash
cd terraform
terraform output quicksight_vpc_role_arn
terraform output quicksight_security_group_id
terraform output quicksight_subnet_ids
terraform output rds_endpoint
terraform output rds_db_name
```

## 🔍 Troubleshooting Common Issues

### VPC Connection Failed
- **Check**: Security group rules allow QuickSight access
- **Verify**: IAM role has proper VPC permissions
- **Ensure**: Subnets are in the same VPC as RDS

### Database Connection Timeout
- **Check**: RDS security group allows inbound from QuickSight security group
- **Verify**: Database credentials are correct
- **Ensure**: VPC connection is active and healthy

### No Data in Visualizations
- **Verify**: ETL pipeline has run and populated tables
- **Check**: Dataset is importing from correct table
- **Refresh**: SPICE datasets to get latest data

### Performance Issues
- **Enable SPICE**: Import datasets to SPICE for faster queries
- **Optimize queries**: Use appropriate filters and aggregations
- **Schedule refreshes**: Set up incremental refresh if dataset grows large

## 📞 Support

If you encounter issues:
1. Check AWS CloudTrail logs for QuickSight API calls
2. Verify VPC Flow Logs for network connectivity
3. Review QuickSight service health in AWS Console
4. Check RDS performance insights for query performance

## 🎯 Next Steps After Setup

1. **Create more advanced visualizations** based on business needs
2. **Set up alerts** for unusual patterns or thresholds
3. **Integrate with other data sources** if needed
4. **Optimize dashboard performance** with proper indexing and SPICE configuration
5. **Train users** on dashboard navigation and interpretation