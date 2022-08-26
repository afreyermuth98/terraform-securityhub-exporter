

import boto3
import botocore
import csv
import logging
import sys
import os
from datetime import date

MODULE = sys.modules["__main__"].__file__
LOG_FORMAT = "[%(asctime)s][%(funcName)25s][%(levelname)8s] - %(message)s"
logger = logging.getLogger(MODULE)


_filter = {
    'RecordState': [
        {
            'Value': 'ACTIVE',
            'Comparison': 'EQUALS',
        },
    ],
    'WorkflowStatus': [
        {
            'Value': 'NEW',
            'Comparison': 'EQUALS'
        },
        {
            'Value': 'NOTIFIED',
            'Comparison': 'EQUALS'
        }
    ],
    'ComplianceStatus': [
        {
            'Value': 'FAILED',
            'Comparison': 'EQUALS'
        }
    ],
}

header = ['Severity', 'Title', 'Description']


def lambda_handler(event, context):
    logger.info("Starting lambda")
    client = boto3.client('securityhub')
    s3 = boto3.resource('s3')

    bucket = os.environ["BUCKET"]

    resources = {
        "INFORMATIONAL": 0,
        "LOW": 0,
        "MEDIUM": 0,
        "HIGH": 0,
        "CRITICAL": 0,
    }

    logger.info("Start querying securityhub")

    with open('/tmp/report.csv','w', encoding='UTF-8') as f:
        writer = csv.writer(f)
        # write the header
        writer.writerow(header)
        while True:
            paginator = client.get_paginator('get_findings')
            operation_parameters = {'Filters': _filter, 'MaxResults': 100}
            page_iterator = paginator.paginate(**operation_parameters)
            try:
                for page in page_iterator:
                    for f in page["Findings"]:
                        row = [f["Severity"]["Label"], f["Title"], f["Description"]]
                        writer.writerow(row)
                        resources[f["Severity"]["Label"]] += 1
            except botocore.exceptions.ClientError as err:
                # Handling API limits
                continue
            else:
                break
    logger.info("File successfully written, uploading to S3")
    filename = "securityhub-report-" + str(date.today())
    s3.meta.client.upload_file('/tmp/report.csv', bucket, filename)

    sns_client = boto3.client('sns')
    snsArn = os.environ['SNS_TOPIC_ARN']
    message = "A new security hub report is available in your S3 bucket : " + filename
    
    response = sns_client.publish(
        TopicArn = snsArn,
        Message = message ,
        Subject='Security hub report'
    )
    
