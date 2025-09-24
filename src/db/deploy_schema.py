#!/usr/bin/env python3
"""
Database schema deployment script for Ring Textilservice
Reads and executes schema.sql using psycopg2
"""
import os
import sys
import logging
from pathlib import Path

try:
    import psycopg2
except ImportError:
    print("❌ psycopg2 is required. Install with: pip install psycopg2-binary")
    sys.exit(1)

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

def get_db_config():
    """Get database configuration from environment variables"""
    config = {
        'host': os.getenv('DB_HOST'),
        'port': os.getenv('DB_PORT', '5432'),
        'database': os.getenv('DB_NAME'),
        'user': os.getenv('DB_USER'),
        'password': os.getenv('DB_PASSWORD')
    }
    
    missing = [k for k, v in config.items() if not v]
    if missing:
        logger.error(f"Missing required environment variables: {', '.join(missing)}")
        sys.exit(1)
    
    return config

def connect_db(config, max_retries=3):
    """Connect to PostgreSQL database with retries"""
    for attempt in range(max_retries):
        try:
            logger.info(f"Connecting to database {config['database']}...")
            conn = psycopg2.connect(**config)
            conn.autocommit = True
            logger.info("✅ Database connection successful")
            return conn
        except psycopg2.OperationalError as e:
            logger.warning(f"Connection attempt {attempt + 1} failed: Connection error")
            if attempt == max_retries - 1:
                logger.error("❌ Could not connect to database after all retries")
                raise
            import time
            time.sleep(5)

def execute_schema(conn, schema_file):
    """Execute SQL schema file"""
    if not schema_file.exists():
        logger.error(f"❌ Schema file not found: {schema_file}")
        sys.exit(1)
    
    logger.info(f"📝 Reading schema from {schema_file}")
    schema_sql = schema_file.read_text(encoding='utf-8')
    
    # Split by semicolon and execute each statement
    statements = [stmt.strip() for stmt in schema_sql.split(';') if stmt.strip()]
    
    cursor = conn.cursor()
    try:
        for i, statement in enumerate(statements, 1):
            if statement:
                logger.debug(f"Executing statement {i}/{len(statements)}")
                cursor.execute(statement)
        
        logger.info("✅ Schema applied successfully")
        
        # Verify tables were created
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name
        """)
        
        tables = [row[0] for row in cursor.fetchall()]
        if tables:
            logger.info(f"📋 Created tables: {', '.join(tables)}")
        else:
            logger.warning("⚠️  No tables found after schema execution")
            
    except psycopg2.Error as e:
        logger.error(f"❌ Database error: {e}")
        raise
    finally:
        cursor.close()

def main():
    """Main execution function"""
    # Get current script directory
    script_dir = Path(__file__).parent
    schema_file = script_dir / 'schema.sql'
    
    # Get database configuration
    config = get_db_config()
    
    # Connect and execute schema
    conn = connect_db(config)
    try:
        execute_schema(conn, schema_file)
        logger.info("🎉 Database schema deployment completed successfully!")
    finally:
        conn.close()

if __name__ == '__main__':
    main()