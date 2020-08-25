#!/usr/bin/env python3 
import boto3
import logging
import os

logging.basicConfig(level=os.environ.get('LOG_LEVEL', 'INFO'))

ec2 = boto3.resource('ec2', region_name='us-east-1')

logger = logging.getLogger(__name__)

# Find all the cassandra instances based on the tag
instances = ec2.instances.filter(
    Filters=[{'Name': 'tag:node_type', 'Values': ['cassandra']}]
)

# Create a list of all the Casssandra instances
instanceIds = []
for instance in instances: 
    instanceIds.append(instance.id)

# Find all the volumes attached to these instances
volumes = ec2.volumes.filter(
    Filters=[{'Name': 'attachment.instance-id', 'Values': instanceIds},
             {'Name': 'tag:Name', 'Values': ['data-vol-*']}
            ]
)

# Loop through all the volumes, get their tags and then 
# create a snapshot and apply the volume tags to the snapshot
for volume in volumes:
    logger.info("Starting snapshot for {0}".format(volume.id))
    logger.info("Adding the following tags to the sanpshot {0}".format(volume.tags))
    snapshot = ec2.create_snapshot(
        VolumeId=volume.id, 
        Description='testSnapshot',
        TagSpecifications=[
            {
                'ResourceType': 'snapshot',
                'Tags': volume.tags
            },
        ],
        DryRun=False
        #logger.info("Created snapshot id: {0} with tags: ")
    )