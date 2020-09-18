#!/usr/bin/env python3 
import boto3
import logging
import os, sys

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

if not instanceIds:
    logger.error("Could not find instances to snapshot.")
    sys.exit(1)

logger.info("Instances to snapshot: {0}".format(instanceIds))

# Find all the volumes attached to these instances
volumes = ec2.volumes.filter(
    Filters=[{'Name': 'attachment.instance-id', 'Values': instanceIds},
             {'Name': 'tag:Name', 'Values': ['data-vol-*']}
            ]
)
logger.debug(volumes)

# Did we find any volumes?
if not volumes:
    logger.error("Could not find any volumes to snapshot.")
    sys.exit(1)


# Loop through all the volumes, get their tags and then 
# create a snapshot and apply the volume tags to the snapshot
for volume in volumes:
    logger.info("Starting snapshot for {0}".format(volume.id))
    logger.debug("Adding the following tags to the sanpshot {0}".format(volume.tags))
    try:
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

        )
        logger.debug(snapshot)
    except:
        logger.error("Encountered an error while trying to create the EBS snapshot: {}".format(snapshot))
        sys.exit(1)

