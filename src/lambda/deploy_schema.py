import json
import boto3
import psycopg2
import logging
import os

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function to deploy database schema
    """
    try:
        logger.info("🚀 Starting database schema deployment...")
        
        # Get database credentials from Secrets Manager
        secrets_client = boto3.client('secretsmanager')
        
        secret_name = os.environ.get('SECRET_NAME', event.get('secret_name', 'ring-textilservice-data-db-credentials'))
        
        logger.info(f"🔑 Retrieving credentials from secret: {secret_name}")
        secret_response = secrets_client.get_secret_value(SecretId=secret_name)
        db_credentials = json.loads(secret_response['SecretString'])
        
        # Extract connection parameters (handle both username/user key variations)
        db_host = db_credentials['host']
        db_port = db_credentials.get('port', 5432)
        db_name = db_credentials['dbname']
        db_user = db_credentials.get('username', db_credentials.get('user', db_credentials.get('USERNAME')))
        db_password = db_credentials['password']
        
        logger.info(f"🔌 Connecting to database {db_name} at {db_host}:{db_port}")
        
        # Connect to PostgreSQL
        conn = psycopg2.connect(
            host=db_host,
            port=db_port,
            database=db_name,
            user=db_user,
            password=db_password,
            connect_timeout=30
        )
        conn.autocommit = True
        
        logger.info("✅ Database connection successful")
        
        # Get schema SQL from event or use embedded schema
        schema_sql = event.get('schema_sql')
        if not schema_sql:
            # Use embedded schema if not provided in event
            schema_sql = get_embedded_schema()
        
        # Execute schema deployment
        cursor = conn.cursor()
        
        logger.info("📝 Executing schema SQL...")
        
        # Execute the entire schema as one block to handle dollar-quoted functions properly
        cursor.execute(schema_sql)
        
        # Verify tables were created
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name
        """)
        
        tables = [row[0] for row in cursor.fetchall()]
        
        cursor.close()
        conn.close()
        
        result = {
            'statusCode': 200,
            'body': {
                'message': 'Database schema deployment completed successfully',
                'tables_created': tables,
                'schema_deployed': True
            }
        }
        
        logger.info(f"🎉 Schema deployed successfully! Created tables: {', '.join(tables)}")
        return result
        
    except Exception as e:
        logger.error(f"❌ Schema deployment failed: {str(e)}")
        return {
            'statusCode': 500,
            'body': {
                'error': str(e),
                'message': 'Database schema deployment failed'
            }
        }

def get_embedded_schema():
    """
    Embedded SQL schema - update this when schema.sql changes
    """
    return '''
-- Create tables for Ring Textilservice data processing
-- This script is idempotent - safe to run multiple times

-- Overview table: production metrics
CREATE TABLE IF NOT EXISTS overview (
    date DATE PRIMARY KEY,
    tonage INTEGER,
    water_m3 REAL,
    liters_per_kg REAL,
    electricity_per_kg REAL,
    gas_per_kg REAL,
    gas_plus_elec_per_kg REAL,
    hours_production REAL,
    kg_per_hour REAL
);

-- Fleet table: vehicle and transport metrics
CREATE TABLE IF NOT EXISTS fleet (
    date DATE PRIMARY KEY,
    driving_hours REAL,
    kg_per_hour_driving REAL,
    km_driven INTEGER,
    CONSTRAINT fk_fleet_date FOREIGN KEY (date) REFERENCES overview (date)
);

-- Washing machines table: equipment performance
CREATE TABLE IF NOT EXISTS washing_machines (
    date DATE PRIMARY KEY,
    machine_130kg INTEGER,
    steps_130kg INTEGER,
    machine_85kg_plus_85kg INTEGER,
    machine_85kg_middle INTEGER,
    steps_85kg_middle INTEGER,
    machine_85kg_right INTEGER,
    steps_85kg_right INTEGER,
    electrolux INTEGER,
    avg_load_130kg REAL,
    avg_load_85kg_middle REAL,
    avg_load_85kg_right REAL,
    CONSTRAINT fk_washing_machines_date FOREIGN KEY (date) REFERENCES overview (date)
);

-- Drying table: drying equipment and processes
CREATE TABLE IF NOT EXISTS drying (
    date DATE PRIMARY KEY,
    roboter_1 INTEGER,
    roboter_2 INTEGER,
    roboter_3 INTEGER,
    roboter_4 INTEGER,
    terry_prep_1 INTEGER,
    terry_prep_2 INTEGER,
    terry_prep_3 INTEGER,
    terry_prep_4 INTEGER,
    blankets_1 INTEGER,
    blankets_2 INTEGER,
    sum_drying_load INTEGER,
    steps_total INTEGER,
    kipper INTEGER,
    avg_drying_load REAL,
    sum_drying INTEGER,
    steps INTEGER,
    CONSTRAINT fk_drying_date FOREIGN KEY (date) REFERENCES overview (date)
);

-- =============================================================================
-- STAGING TABLES FOR UPSERT WORKFLOW
-- These tables temporarily hold new data before upserting to main tables
-- =============================================================================

-- Staging table for overview data
CREATE TABLE IF NOT EXISTS overview_staging (
    date DATE,
    tonage INTEGER,
    water_m3 REAL,
    liters_per_kg REAL,
    electricity_per_kg REAL,
    gas_per_kg REAL,
    gas_plus_elec_per_kg REAL,
    hours_production REAL,
    kg_per_hour REAL
);

-- Staging table for fleet data  
CREATE TABLE IF NOT EXISTS fleet_staging (
    date DATE,
    driving_hours REAL,
    kg_per_hour_driving REAL,
    km_driven INTEGER
);

-- Staging table for washing machines data
CREATE TABLE IF NOT EXISTS washing_machines_staging (
    date DATE,
    machine_130kg INTEGER,
    steps_130kg INTEGER,
    machine_85kg_plus_85kg INTEGER,
    machine_85kg_middle INTEGER,
    steps_85kg_middle INTEGER,
    machine_85kg_right INTEGER,
    steps_85kg_right INTEGER,
    electrolux INTEGER,
    avg_load_130kg REAL,
    avg_load_85kg_middle REAL,
    avg_load_85kg_right REAL
);

-- Staging table for drying data
CREATE TABLE IF NOT EXISTS drying_staging (
    date DATE,
    roboter_1 INTEGER,
    roboter_2 INTEGER,
    roboter_3 INTEGER,
    roboter_4 INTEGER,
    terry_prep_1 INTEGER,
    terry_prep_2 INTEGER,
    terry_prep_3 INTEGER,
    terry_prep_4 INTEGER,
    blankets_1 INTEGER,
    blankets_2 INTEGER,
    sum_drying_load INTEGER,
    steps_total INTEGER,
    kipper INTEGER,
    avg_drying_load REAL,
    sum_drying INTEGER,
    steps INTEGER
);

-- =============================================================================
-- UPSERT FUNCTIONS FOR EACH TABLE
-- These functions handle the INSERT ... ON CONFLICT UPDATE logic
-- =============================================================================

CREATE OR REPLACE FUNCTION upsert_overview_data()
RETURNS INTEGER AS $$
DECLARE
    rows_affected INTEGER;
BEGIN
    INSERT INTO overview (date, tonage, water_m3, liters_per_kg, electricity_per_kg, 
                         gas_per_kg, gas_plus_elec_per_kg, hours_production, kg_per_hour)
    SELECT date, tonage, water_m3, liters_per_kg, electricity_per_kg, 
           gas_per_kg, gas_plus_elec_per_kg, hours_production, kg_per_hour
    FROM overview_staging
    ON CONFLICT (date) DO UPDATE SET
        tonage = EXCLUDED.tonage,
        water_m3 = EXCLUDED.water_m3,
        liters_per_kg = EXCLUDED.liters_per_kg,
        electricity_per_kg = EXCLUDED.electricity_per_kg,
        gas_per_kg = EXCLUDED.gas_per_kg,
        gas_plus_elec_per_kg = EXCLUDED.gas_plus_elec_per_kg,
        hours_production = EXCLUDED.hours_production,
        kg_per_hour = EXCLUDED.kg_per_hour;
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    DELETE FROM overview_staging;
    RETURN rows_affected;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upsert_fleet_data()
RETURNS INTEGER AS $$
DECLARE
    rows_affected INTEGER;
BEGIN
    INSERT INTO fleet (date, driving_hours, kg_per_hour_driving, km_driven)
    SELECT date, driving_hours, kg_per_hour_driving, km_driven
    FROM fleet_staging
    ON CONFLICT (date) DO UPDATE SET
        driving_hours = EXCLUDED.driving_hours,
        kg_per_hour_driving = EXCLUDED.kg_per_hour_driving,
        km_driven = EXCLUDED.km_driven;
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    DELETE FROM fleet_staging;
    RETURN rows_affected;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upsert_washing_machines_data()
RETURNS INTEGER AS $$
DECLARE
    rows_affected INTEGER;
BEGIN
    INSERT INTO washing_machines (date, machine_130kg, steps_130kg, machine_85kg_plus_85kg,
                                 machine_85kg_middle, steps_85kg_middle, machine_85kg_right,
                                 steps_85kg_right, electrolux, avg_load_130kg, 
                                 avg_load_85kg_middle, avg_load_85kg_right)
    SELECT date, machine_130kg, steps_130kg, machine_85kg_plus_85kg,
           machine_85kg_middle, steps_85kg_middle, machine_85kg_right,
           steps_85kg_right, electrolux, avg_load_130kg, 
           avg_load_85kg_middle, avg_load_85kg_right
    FROM washing_machines_staging
    ON CONFLICT (date) DO UPDATE SET
        machine_130kg = EXCLUDED.machine_130kg,
        steps_130kg = EXCLUDED.steps_130kg,
        machine_85kg_plus_85kg = EXCLUDED.machine_85kg_plus_85kg,
        machine_85kg_middle = EXCLUDED.machine_85kg_middle,
        steps_85kg_middle = EXCLUDED.steps_85kg_middle,
        machine_85kg_right = EXCLUDED.machine_85kg_right,
        steps_85kg_right = EXCLUDED.steps_85kg_right,
        electrolux = EXCLUDED.electrolux,
        avg_load_130kg = EXCLUDED.avg_load_130kg,
        avg_load_85kg_middle = EXCLUDED.avg_load_85kg_middle,
        avg_load_85kg_right = EXCLUDED.avg_load_85kg_right;
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    DELETE FROM washing_machines_staging;
    RETURN rows_affected;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upsert_drying_data()
RETURNS INTEGER AS $$
DECLARE
    rows_affected INTEGER;
BEGIN
    INSERT INTO drying (date, roboter_1, roboter_2, roboter_3, roboter_4,
                       terry_prep_1, terry_prep_2, terry_prep_3, terry_prep_4,
                       blankets_1, blankets_2, sum_drying_load, steps_total,
                       kipper, avg_drying_load, sum_drying, steps)
    SELECT date, roboter_1, roboter_2, roboter_3, roboter_4,
           terry_prep_1, terry_prep_2, terry_prep_3, terry_prep_4,
           blankets_1, blankets_2, sum_drying_load, steps_total,
           kipper, avg_drying_load, sum_drying, steps
    FROM drying_staging
    ON CONFLICT (date) DO UPDATE SET
        roboter_1 = EXCLUDED.roboter_1,
        roboter_2 = EXCLUDED.roboter_2,
        roboter_3 = EXCLUDED.roboter_3,
        roboter_4 = EXCLUDED.roboter_4,
        terry_prep_1 = EXCLUDED.terry_prep_1,
        terry_prep_2 = EXCLUDED.terry_prep_2,
        terry_prep_3 = EXCLUDED.terry_prep_3,
        terry_prep_4 = EXCLUDED.terry_prep_4,
        blankets_1 = EXCLUDED.blankets_1,
        blankets_2 = EXCLUDED.blankets_2,
        sum_drying_load = EXCLUDED.sum_drying_load,
        steps_total = EXCLUDED.steps_total,
        kipper = EXCLUDED.kipper,
        avg_drying_load = EXCLUDED.avg_drying_load,
        sum_drying = EXCLUDED.sum_drying,
        steps = EXCLUDED.steps;
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    DELETE FROM drying_staging;
    RETURN rows_affected;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- MASTER UPSERT FUNCTION
-- Calls all individual upsert functions in proper order
-- =============================================================================

CREATE OR REPLACE FUNCTION upsert_all_data()
RETURNS TEXT AS $$
DECLARE
    overview_rows INTEGER;
    fleet_rows INTEGER;
    washing_rows INTEGER;
    drying_rows INTEGER;
    result_msg TEXT;
BEGIN
    -- Upsert in order: overview first (parent), then child tables
    overview_rows := upsert_overview_data();
    fleet_rows := upsert_fleet_data();
    washing_rows := upsert_washing_machines_data();
    drying_rows := upsert_drying_data();
    
    result_msg := format('Upsert completed: Overview=%s, Fleet=%s, Washing=%s, Drying=%s rows',
                        overview_rows, fleet_rows, washing_rows, drying_rows);
    
    RAISE NOTICE '%', result_msg;
    RETURN result_msg;
END;
$$ LANGUAGE plpgsql;
    '''