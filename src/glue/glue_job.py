import sys
import os
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql.functions import col, lit, to_date
import pyspark.pandas as ps

# Retrieve Glue job name argument
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

if "EXCEL_PATH" not in os.environ or not os.environ["EXCEL_PATH"]:
  raise Exception("Missing required environment variable: EXCEL_PATH")

excel_path = os.environ["EXCEL_PATH"]

# Read Excel with headers starting at second row
df = ps.read_excel(excel_path, header=1)
df_spark = df.to_spark()

target_schemas = [
    {"table_name": "table_A", "schema": {"id": "int", "name": "string", "date": "string"}},
    {"table_name": "table_B", "schema": {"id": "int", "email": "string", "date": "string"}}
]

for schema_obj in target_schemas:
    schema = schema_obj["schema"]
    table = schema_obj["table_name"]

    # Prepare and cast columns, filling missing with nulls
    selected_cols = [
        col(col_name).cast(col_type).alias(col_name) if col_name in df_spark.columns
        else lit(None).cast(col_type).alias(col_name)
        for col_name, col_type in schema.items()
    ]
    df_clean = df_spark.select(*selected_cols)

    # Validate and filter rows with valid date format
    df_clean = df_clean.withColumn("date", to_date(col("date"), "dd-MM-yyyy"))
    df_clean = df_clean.filter(col("date").isNotNull())

    # Create a temporary view for MERGE SQL
    temp_view = f"temp_{table}"
    df_clean.createOrReplaceTempView(temp_view)

    # Construct MERGE statement for upsert
    merge_sql = f"""
    MERGE INTO {table} AS target
    USING {temp_view} AS source
    ON target.date = source.date AND target.id = source.id
    WHEN MATCHED THEN
      UPDATE SET {', '.join([f'target.{c} = source.{c}' for c in schema.keys() if c not in ['id', 'date']])}
    WHEN NOT MATCHED THEN
      INSERT ({', '.join(schema.keys())})
      VALUES ({', '.join([f'source.{c}' for c in schema.keys()])})
    """

    # Execute the merge query
    spark.sql(merge_sql)
