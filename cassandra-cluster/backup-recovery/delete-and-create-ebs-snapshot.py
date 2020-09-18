#!/usr/bin/env python3 
import boto3
import logging
import os, sys

logging.basicConfig(level=os.environ.get('LOG_LEVEL', 'INFO'))

ec2 = boto3.client('ec2', region_name='us-east-1')
logger = logging.getLogger(__name__)

# Get all snapshots
snapshots = ec2.describe_snapshots(
    Filters=[{'Name': 'tag:Name', 'Values': ['data-vol-*']}],
    OwnerIds=["self"]
)['Snapshots']

snapshotIds = []
for snapshot in snapshots:
    logger.debug("Deleting snapshot: {0}".format(snapshot['SnapshotId']))
    response = ec2.delete_snapshot(
        SnapshotId=snapshot['SnapshotId'],
        DryRun=False
    )
    logger.debug(response)
 


# Find all the cassandra instances based on the tag
instances = ec2.describe_instances(
    Filters=[{'Name': 'tag:node_type', 'Values': ['cassandra']}]
)['Reservations']



# Create a list of all the Casssandra instances
instanceIds = []
for instance in instances: 
    instanceIds.append(instance['Instances'][0]['InstanceId'])

if not instanceIds:
    logger.error("Could not find instances to snapshot.")
    sys.exit(1)

logger.info("Instances to snapshot: {0}".format(instanceIds))

# Find all the volumes attached to these instances
volumes = ec2.describe_volumes(
    Filters=[{'Name': 'attachment.instance-id', 'Values': instanceIds},
             {'Name': 'tag:Name', 'Values': ['data-vol-*']}
            ]
)['Volumes']

logger.debug(volumes)

# Did we find any volumes?
if not volumes:
    logger.error("Could not find any volumes to snapshot.")
    sys.exit(1)

# Loop through all the volumes, get their tags and then 
# create a snapshot and apply the volume tags to the snapshot
for volume in volumes:
    logger.debug("Starting snapshot for {0}".format(volume['VolumeId']))
    logger.debug("Adding the following tags to the sanpshot {0}".format(volume['Tags']))
    try:
        snapshot = ec2.create_snapshot(
            VolumeId=volume['VolumeId'], 
            Description='testSnapshot',
            TagSpecifications=[
                {
                    'ResourceType': 'snapshot',
                    'Tags': volume['Tags']
                },
            ],
            DryRun=False
        )
        logger.debug(snapshot)
    except:
 
