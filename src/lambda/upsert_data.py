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
    Lambda function to perform upsert operations from staging tables to main tables
    and provide detailed logging for debugging
    """
    try:
        logger.info("🚀 Starting database upsert operations...")
        
        # Get database credentials from Secrets Manager
        secrets_client = boto3.client('secretsmanager')
        
        # Get secret name from environment variable
        secret_name = os.environ.get('SECRET_NAME')
        if not secret_name:
            raise ValueError("SECRET_NAME environment variable not set")
        
        logger.info(f"🔑 Retrieving credentials from secret: {secret_name}")
        secret_response = secrets_client.get_secret_value(SecretId=secret_name)
        db_credentials = json.loads(secret_response['SecretString'])
        
        # Extract connection parameters
        db_host = db_credentials['host']
        db_port = db_credentials.get('port', 5432)
        db_name = db_credentials['dbname']
        db_user = db_credentials['username']
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
        
        cursor = conn.cursor()
        
        # Define upsert functions and their corresponding tables
        upsert_functions = [
            {
                'function': 'upsert_overview_data',
                'staging_table': 'overview_staging',
                'main_table': 'overview'
            },
            {
                'function': 'upsert_fleet_data', 
                'staging_table': 'fleet_staging',
                'main_table': 'fleet'
            },
            {
                'function': 'upsert_washing_machines_data',
                'staging_table': 'washing_machines_staging', 
                'main_table': 'washing_machines'
            },
            {
                'function': 'upsert_drying_data',
                'staging_table': 'drying_staging', 
                'main_table': 'drying'
            }
        ]
        
        total_rows_processed = 0
        
        # Process each upsert function
        for upsert_config in upsert_functions:
            function_name = upsert_config['function']
            staging_table = upsert_config['staging_table']
            main_table = upsert_config['main_table']
            
            logger.info(f"\n📊 Processing table: {main_table}")
            
            # Check if staging table exists and has data
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {staging_table}")
                staging_count = cursor.fetchone()[0]
                logger.info(f"📋 Staging table {staging_table} has {staging_count} rows")
                
                if staging_count == 0:
                    logger.info(f"⏭️ Skipping {main_table} - no data in staging table")
                    continue
            except Exception as e:
                logger.info(f"⏭️ Skipping {main_table} - staging table {staging_table} doesn't exist or error: {e}")
                continue
            
            # Log BEFORE state of main table
            cursor.execute(f"SELECT COUNT(*) FROM {main_table}")
            before_count = cursor.fetchone()[0]
            logger.info(f"📊 BEFORE: {main_table} has {before_count} rows")
            
            # Get column names for mapping row data
            cursor.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{main_table}' ORDER BY ordinal_position")
            columns = [row[0] for row in cursor.fetchall()]
            
            # Log first row of main table (if exists)
            cursor.execute(f"SELECT * FROM {main_table} ORDER BY date LIMIT 1")
            first_row_before = cursor.fetchone()
            if first_row_before:
                first_row_dict = dict(zip(columns, first_row_before))
                logger.info(f"📝 BEFORE - First row of {main_table}: {first_row_dict}")
            else:
                logger.info(f"📝 BEFORE - {main_table} is empty")
            
            # Call the stored upsert function
            logger.info(f"🔄 Calling stored function: {function_name}()")
            cursor.execute(f"SELECT {function_name}()")
            rows_affected = cursor.fetchone()[0]
            
            total_rows_processed += rows_affected
            logger.info(f"✅ Upserted {rows_affected} rows for {main_table}")
            
            # Log AFTER state of main table
            cursor.execute(f"SELECT COUNT(*) FROM {main_table}")
            after_count = cursor.fetchone()[0]
            logger.info(f"📊 AFTER: {main_table} has {after_count} rows (change: {after_count - before_count:+d})")
            
            # Log first row of main table after upsert
            cursor.execute(f"SELECT * FROM {main_table} ORDER BY date LIMIT 1")
            first_row_after = cursor.fetchone()
            if first_row_after:
                first_row_dict_after = dict(zip(columns, first_row_after))
                logger.info(f"📝 AFTER - First row of {main_table}: {first_row_dict_after}")
                
                # Compare first row before and after
                if first_row_before and first_row_after:
                    if first_row_before == first_row_after:
                        logger.info("🔄 First row unchanged (as expected for duplicate data)")
                    else:
                        logger.info("🔄 First row changed (data update detected)")
            
            # Verify staging table is empty after upsert (should be cleared by the function)
            cursor.execute(f"SELECT COUNT(*) FROM {staging_table}")
            staging_count_after = cursor.fetchone()[0]
            logger.info(f"📋 Staging table {staging_table} after upsert: {staging_count_after} rows (should be 0)")
        
        cursor.close()
        conn.close()
        
        result = {
            'statusCode': 200,
            'body': {
                'message': 'Database upsert operations completed successfully',
                'total_rows_processed': total_rows_processed,
                'tables_processed': [config['main_table'] for config in upsert_functions]
            }
        }
        
        logger.info(f"🎉 Upsert completed! Total rows processed: {total_rows_processed}")
        return result
        
    except Exception as e:
        logger.error(f"❌ Upsert operations failed: {str(e)}")
        # Re-raise the exception to make Step Functions fail properly
        raise RuntimeError(f"Database upsert operations failed: {str(e)}")

