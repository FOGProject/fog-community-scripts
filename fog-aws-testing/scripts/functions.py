import boto3
import time
from settings import *


ec2resource = boto3.resource('ec2')
ec2client = boto3.client('ec2')

def get_instance(name,value):
    # This assumes one match
    # Only for instances that are not terminated.
    response = ec2client.describe_instances(
       Filters=[
            {
                'Name': 'tag:' + name,
                'Values': [value]
            },
            {
                'Name':'instance-state-name',
                'Values':['pending','running','shutting-down','stopping','stopped']
            }
       ]
    )
    instance = ec2resource.Instance(response["Reservations"][0]["Instances"][0]["InstanceId"])
    return instance

def get_instance_volume(instance):
    # This assumes one volume.
    volume = ec2resource.Volume(instance.block_device_mappings[0]["Ebs"]["VolumeId"])
    return volume


def wait_until_stopped(instance):
    while True:
        instance.reload()
        if instance.state["Name"] == "stopped":
            break
        else:
            time.sleep(wait)
    return

def wait_until_running(instance):
    while True:
        instance.reload()
        if instance.state["Name"] == "running":
            break
        else:
            time.sleep(wait)
    return


def create_snapshot(volume,name_tag):
    snapshot = volume.create_snapshot()
    snapshot.create_tags(
        Tags=[
            {
                'Key': 'Name',
                'Value': name_tag
            }
        ]
    )
    while True:
        snapshot.reload()
        if snapshot.state == "completed":
            break
        else:
            time.sleep(wait)
    return snapshot

def delete_snapshots(name,value):
    # This deletes all matching snapshots.
    response = ec2client.describe_snapshots(
       Filters=[
            {
                'Name': 'tag:' + name,
                'Values': [value]
            }
       ]
    )
    for snapshotDict in response["Snapshots"]:
        snapshot = ec2resource.Snapshot(snapshotDict["SnapshotId"])
        snapshot.delete()

def get_snapshot(name,value):
    # Assumes one match.
    response = ec2client.describe_snapshots(
       Filters=[
            {
                'Name': 'tag:' + name,
                'Values': [value]
            }
       ]
    )
    snapshot = ec2resource.Snapshot(response["Snapshots"][0]["SnapshotId"])
    return snapshot


def restore_snapshot_to_instance(snapshot,instance):
    """
    Stop the instance
    detach and delete the old volume.
    Create a new volume
    Attach the new volume
    Start the instance
    """
    instance.stop()
    wait_until_stopped(instance)
    oldVolume = get_instance_volume(instance)
    oldVolume.detach_from_instance(Force=True)
    while True:
        oldVolume.reload()
        if oldVolume.state == "available":
            break
        else:
            time.sleep(wait)

    oldVolume.delete()
    newVolume = ec2client.create_volume(SnapshotId=snapshot.id,AvailabilityZone=zone)
    newVolume = ec2resource.Volume(newVolume["VolumeId"])
    while True:
        newVolume.reload()
        if newVolume.state == "available":
            break
        else:
            time.sleep(wait)
    instance.attach_volume(VolumeId=newVolume.id,Device='/dev/sda1')
    while True:
        newVolume.reload()
        print newVolume.state
        if newVolume.state == "in-use":
            break
        else:
            time.sleep(wait)
    instance.start()
    wait_until_running(instance)





