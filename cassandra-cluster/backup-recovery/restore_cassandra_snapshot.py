#!/usr/bin/env python3 
import boto3
import logging
import os, sys
import paramiko
from paramiko import AutoAddPolicy
from paramiko.ssh_exception import SSHException

keyfile     = '/Users/cdiaz/.ssh/datastax_aws.rsa'
user        =  'centos'
data_dir    =  '/cassandra/data'
keyspaces   = ['baselines']
tables      = ['iot', 'keyvalue']
# keyspaces   = ['resolver']
# tables = ['cluster_ext_consensus_by_clusterid','bib_by_bibid','cluster_by_clusterid','cluster_main_consensus_by_clusterid','cluster_by_cluster_key']

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(AutoAddPolicy())

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

def restore_snapshot(ip, keyspace):
    ssh.connect(
        hostname=ip, 
        username=user, 
        key_filename=keyfile
    )
    logger.info("Restoring keyspace {}".format(keyspace))
    # Find all the tables in the snapshot directory
    cmd = "/usr/bin/find /cassandra/data/{} -name snapshots".format(keyspace)
    try:
        stdin, stdout, stderr = ssh.exec_command(cmd)
    except paramiko.AuthenticationException:
        raise AuthenticationException("Authentication Error!!")
    except paramiko.SSHException as e:
        if str(e) == "No authentication methods available":
            raise AuthenticationException("Authentication Error!!")
        return False
    except Exception:
        return False
    dirs = stdout.readlines()
    if not dirs:
        logger.error("No snapshot found on {}".format(ip))
        raise Exception("Snapshot not found exception.")
    for dir in dirs:
        dir = dir.rstrip("\n")
        clear_dir_cmd = "cd {}/latest/ && sudo rm -rf ../../*.{{db,txt,crc32}}".format(dir)
        stdin, stdout, stderr = ssh.exec_command(clear_dir_cmd)
        cp_cmd = "cd {}/latest/ && sudo cp -p {}/latest/*.db  ../../".format(dir, dir)
        stdin, stdout, stderr = ssh.exec_command(cp_cmd)
        for table in tables:
            refresh_cmd = "nodetool refresh -- {} {}".format(keyspace, table)
            stdin, stdout, stderr = ssh.exec_command(refresh_cmd)
    ssh.close()

# Create a list of all the Casssandra instances
instanceIps = []
for instance in instances: 
    instanceIps.append(instance.private_ip_address)


for ip in instanceIps:
    for keyspace in keyspaces:
        try:
            restore_snapshot(ip, keyspace)
        except:
            logger.error("Snapshot restore failed.")
            sys.exit(1)

    



