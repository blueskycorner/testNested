import json
import os
import boto3

print('Loading function')

SCHEDULING_TAG = 'SCHEDULING'
SCHEDULING_TAG_VALUE = os.environ[SCHEDULING_TAG]
ec2client = boto3.client('ec2')

def list_instances_by_tag_value(tagkey, tagvalue):
    # When passed a tag key, tag value this will return a list of InstanceIds that were found.

    response = ec2client.describe_instances(
        Filters=[
            {
                'Name': 'tag:'+tagkey,
                'Values': [tagvalue]
            }
        ]
    )
    instancelist = []
    for reservation in (response["Reservations"]):
        for instance in reservation["Instances"]:
            instancelist.append(instance["InstanceId"])
    return instancelist

def lambda_handler(event, context):
    print("Looking for SCHEDULING tag with value: " + SCHEDULING_TAG_VALUE)
    instancelist = list_instances_by_tag_value(SCHEDULING_TAG, SCHEDULING_TAG_VALUE)
    if (len(instancelist) > 0):
        ec2client.start_instances(InstanceIds=instancelist)
    
    
    return instancelist  # Returns the instances list involved
