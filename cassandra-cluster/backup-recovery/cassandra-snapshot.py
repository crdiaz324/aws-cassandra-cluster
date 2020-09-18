#!/usr/bin/env python3 
import boto3
import logging
import os, sys
from pssh.exceptions import AuthenticationException, UnknownHostException, ConnectionErrorException
from pssh.clients import ParallelSSHClient

snapshot_cmd='nodetool clearsnapshot -t latest && nodetool snapshot -t latest'

logging.basicConfig(level=os.environ.get('LOG_LEVEL', 'INFO'))

ec2 = boto3.resource('ec2', region_name='us-east-1')
logger = logging.getLogger(__name__)

# Find all the cassandra instances based on the tag
instances = ec2.instances.filter(
    Filters=[
        {'Name': 'tag:node_type', 
        'Values': ['cassandra']
        },
        {
            'Name': 'instance-state-name',
            'Values': ['running']
        }
    ]
)


# Create a list of all the Casssandra instances
instanceIps = []
for instance in instances: 
    instanceIps.append(instance.private_ip_address)

client = ParallelSSHClient(
    instanceIps, 
    pkey=os.path.expanduser('~/.ssh/datastax_aws.rsa'),
    user='centos'
)
try:
    output = client.run_command(snapshot_cmd, return_list=True)
except (AuthenticationException, UnknownHostException, ConnectionErrorException) as e:
    print("While connecting: {}".format(e))

if not output:
    logger.error("No instances found.")
    sys.exit(1)


for host_output in output:
    for line in host_output.stdout:
        logger.info(line)






    


