import json
import boto3
import os

ssm = boto3.client('ssm')
ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    # Extract ECR image details
    detail = event.get('detail', {})
    repository_name = detail.get('repository-name')
    image_tag = detail.get('image-tag', 'latest')
    
    print(f"New image pushed: {repository_name}:{image_tag}")
    
    # Find EC2 instances with AutoDeploy tag
    response = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:AutoDeploy', 'Values': ['true']},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )
    
    instance_ids = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])
    
    if not instance_ids:
        print("No instances found with AutoDeploy tag")
        return {
            'statusCode': 200,
            'body': json.dumps('No instances to deploy')
        }
    
    print(f"Found instances: {instance_ids}")
    
    # Send SSM command to run deployment script
    ssm_response = ssm.send_command(
        InstanceIds=instance_ids,
        DocumentName="AWS-RunShellScript",
        Parameters={
            'commands': [
                'cd /opt/dockpaas',
                'source .env',
                './deploy.sh'
            ]
        },
        Comment=f'DockPaaS deployment for {repository_name}:{image_tag}'
    )
    
    command_id = ssm_response['Command']['CommandId']
    print(f"SSM Command sent: {command_id}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'Deployment triggered',
            'command_id': command_id,
            'instances': instance_ids
        })
    }
