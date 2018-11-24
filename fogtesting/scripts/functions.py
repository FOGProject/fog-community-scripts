import boto3
import json




def get_instance_id(tag,value):
    # This assumes one match
    ec2 = boto3.client('ec2')
    response = ec2.describe_instances(
       Filters=[
            {
                'Name': 'tag:' + tag,
                'Values': [value]
            }
        ],
       MaxResults=5,
    )
    return response["Reservations"][0]["Instances"][0]["InstanceId"]


