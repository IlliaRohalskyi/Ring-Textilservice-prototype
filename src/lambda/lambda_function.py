import json
import os
import boto3
import logging
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
quicksight = boto3.client('quicksight')

def lambda_handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    AWS Lambda function to refresh QuickSight dataset after Glue processing
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        account_id = os.environ.get('QUICKSIGHT_ACCOUNT_ID')
        dataset_id = os.environ.get('QUICKSIGHT_DATA_SET_ID')
        
        if not account_id or not dataset_id:
            logger.error("Missing required environment variables: QUICKSIGHT_ACCOUNT_ID or QUICKSIGHT_DATA_SET_ID")
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'message': 'Missing required environment variables'
                })
            }
        
        ingestion_id = f"ingestion-{context.aws_request_id}"
        
        response = quicksight.create_ingestion(
            AwsAccountId=account_id,
            DataSetId=dataset_id,
            IngestionId=ingestion_id
        )
        
        logger.info(f"Started QuickSight ingestion: {ingestion_id}")
        logger.info(f"Ingestion response: {response}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'QuickSight dataset refresh initiated successfully',
                'ingestionId': ingestion_id,
                'status': response.get('IngestionStatus', 'INITIATED')
            })
        }
        
    except Exception as e:
        logger.error(f"Error refreshing QuickSight dataset: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'Error refreshing QuickSight dataset',
                'error': str(e)
            })
        }
