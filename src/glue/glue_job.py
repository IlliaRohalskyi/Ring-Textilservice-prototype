import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame
import pandas as pd
from pyspark.sql.types import *
from pyspark.sql.functions import col, lit, to_date, when, regexp_replace
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import functions as SqlFuncs
from urllib.parse import unquote

# Get job arguments
args = getResolvedOptions(sys.argv, ['JOB_NAME', 's3_input_path'])

# Initialize Glue context and job
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

print(f"🚀 Starting Glue job...")

# Handle URL encoding in S3 path
s3_input_path = args['s3_input_path']
# Decode any URL-encoded characters in the path
s3_input_path_decoded = unquote(s3_input_path)
print(f"📄 Original S3 path: {s3_input_path}")
print(f"📄 Decoded S3 path: {s3_input_path_decoded}")

# Read Excel file directly from S3 using pandas (works in Glue!)
excel_df = pd.read_excel(s3_input_path_decoded, header=1)
print(f"✅ Excel file loaded: {excel_df.shape[0]} rows, {excel_df.shape[1]} columns")

# Drop duplicates at pandas level
excel_df = excel_df.drop_duplicates()
print(f"✅ Duplicates dropped: {excel_df.shape[0]} rows remaining")

# Create schema with proper data types (start with StringType for flexibility)
excel_schema = StructType([StructField(column_name, StringType(), True) for column_name in excel_df.columns])

# Convert to Spark DataFrame
spark_df = spark.createDataFrame(excel_df, schema=excel_schema)
print("✅ Converted to Spark DataFrame")

# Process date column
spark_df = spark_df.withColumn("date", to_date(col("Datum"), "dd.MM.yyyy"))
print("✅ Date column processed")

# Define target table schemas matching the database
target_schemas = [
    {
        "table_name": "overview",
        "schema": {
            "date": "date",
            "tonage": "int", 
            "water_m3": "double",
            "liters_per_kg": "double",
            "electricity_per_kg": "double", 
            "gas_per_kg": "double",
            "gas_plus_elec_per_kg": "double",
            "hours_production": "double",
            "kg_per_hour": "double"
        },
        "column_mapping": {
            "date": "date",
            "tonage": "Gesamt \nTonage",
            "water_m3": "Wasserverbrauch in m³",
            "liters_per_kg": "Liter/kg gesamt", 
            "electricity_per_kg": "Stom / Kg Wäsche",
            "gas_per_kg": "Gas / Kg\nWäsche",
            "gas_plus_elec_per_kg": "Gas+ Stom / Kg Wäsche",
            "hours_production": "Stunden\nProduktion",
            "kg_per_hour": "KG / \nStunde Produktion"
        }
    },
    {
        "table_name": "fleet", 
        "schema": {
            "date": "date",
            "driving_hours": "double",
            "kg_per_hour_driving": "double", 
            "km_driven": "int"
        },
        "column_mapping": {
            "date": "date",
            "driving_hours": "Stunden\nFuhrpark / Verlader",
            "kg_per_hour_driving": "KG / Stunde\n Fuhrpark / Verlader",
            "km_driven": "Gefahrene Km"
        }
    },
    {
        "table_name": "washing_machines",
        "schema": {
            "date": "date",
            "machine_130kg": "int",
            "steps_130kg": "int", 
            "machine_85kg_plus_85kg": "int",
            "machine_85kg_middle": "int",
            "steps_85kg_middle": "int",
            "machine_85kg_right": "int", 
            "steps_85kg_right": "int",
            "electrolux": "int",
            "avg_load_130kg": "double",
            "avg_load_85kg_middle": "double",
            "avg_load_85kg_right": "double"
        },
        "column_mapping": {
            "date": "date", 
            "machine_130kg": "130 KG",
            "steps_130kg": "130 KG\nTakte",
            "machine_85kg_plus_85kg": "85 KG + 85 KG\n ",
            "machine_85kg_middle": "85 KG\nmitte", 
            "steps_85kg_middle": "85 KG mitte\nTakte",
            "machine_85kg_right": "85 kg \nrechts",
            "steps_85kg_right": "85 KG rechts\nTakte",
            "electrolux": "Electrolux",
            "avg_load_130kg": "Ø Beladung 130",
            "avg_load_85kg_middle": "Ø Beladung 85\nmitte", 
            "avg_load_85kg_right": "Ø Beladung 85\nrechts"
        }
    },
    {
        "table_name": "drying",
        "schema": {
            "date": "date",
            "roboter_1": "int",
            "roboter_2": "int",
            "roboter_3": "int", 
            "roboter_4": "int",
            "terry_prep_1": "int",
            "terry_prep_2": "int",
            "terry_prep_3": "int",
            "terry_prep_4": "int",
            "blankets_1": "int",
            "blankets_2": "int", 
            "sum_drying_load": "int",
            "steps_total": "int",
            "kipper": "int",
            "avg_drying_load": "double",
            "sum_drying": "int",
            "steps": "int"
        },
        "column_mapping": {
            "date": "date",
            "roboter_1": "Roboter 1",
            "roboter_2": "Roboter 2", 
            "roboter_3": "Roboter 3 ",
            "roboter_4": "Roboter 4",
            "terry_prep_1": "Frottelege 1 ",
            "terry_prep_2": "Frottelege 2",
            "terry_prep_3": "Frottelege 3",
            "terry_prep_4": "Frottelege 4 ",
            "blankets_1": "Decken 1",
            "blankets_2": "Decken 2",
            "sum_drying_load": "Summe Frottee", 
            "steps_total": "Takte",
            "kipper": "Kipper",
            "avg_drying_load": "Ø Beladung\n Trockner",
            "sum_drying": "Trockner",
            "steps": "Takte"
        }
    }
]
print("✅ Table schemas defined")

# Process each table
for schema_obj in target_schemas:
    table_name = schema_obj["table_name"]
    schema = schema_obj["schema"] 
    column_mapping = schema_obj["column_mapping"]
    
    print(f"📊 Processing table: {table_name}")
    
    # Map and cast columns for this table
    selected_cols = []
    for db_col, data_type in schema.items():
        excel_col = column_mapping.get(db_col)
        
        if excel_col and excel_col in spark_df.columns:
            # Cast the column to appropriate type
            if data_type == "int":
                col_expr = col(excel_col).cast(IntegerType()).alias(db_col)
            elif data_type == "double": 
                col_expr = col(excel_col).cast(DoubleType()).alias(db_col)
            elif data_type == "date":
                col_expr = col(excel_col).alias(db_col)
            else:
                col_expr = col(excel_col).cast(StringType()).alias(db_col)
        else:
            # Create null column if mapping not found
            if data_type == "int":
                col_expr = lit(None).cast(IntegerType()).alias(db_col)
            elif data_type == "double":
                col_expr = lit(None).cast(DoubleType()).alias(db_col) 
            elif data_type == "date":
                col_expr = lit(None).cast(DateType()).alias(db_col)
            else:
                col_expr = lit(None).cast(StringType()).alias(db_col)
                
        selected_cols.append(col_expr)
    
    # Create DataFrame for this table
    df_table = spark_df.select(*selected_cols)
    
    # Filter out rows with null dates
    df_table = df_table.filter(col("date").isNotNull())
    
    # Drop duplicates for this table
    df_table = df_table.dropDuplicates()
    
    # Convert Spark DataFrame to Glue DynamicFrame for JDBC operations
    dynamic_frame = DynamicFrame.fromDF(df_table, glueContext, f"{table_name}_frame")
    
    # Write to PostgreSQL using JDBC connection
    print(f"🔄 Writing {table_name} to PostgreSQL...")
    
    # Use Glue's built-in JDBC sink with upsert capability
    glueContext.write_dynamic_frame.from_jdbc_conf(
        frame=dynamic_frame,
        catalog_connection="glue-db-connection",  # This matches your Terraform connection name
        connection_options={
            "dbtable": table_name,
            "database": "ring_textilservice_data"
        },
        transformation_ctx=f"write_{table_name}"
    )
    print(f"✅ {table_name} written to database successfully")

print("🎉 All tables processed successfully!")

# Commit the job - this is critical for proper error handling!
job.commit()
