import boto3
import time
import sys
import datetime
from settings import *
import os 
from threading import Thread
import subprocess
cwd = os.path.dirname(os.path.realpath(__file__))




ec2resource = boto3.resource('ec2')
ec2client = boto3.client('ec2')


def add_ssh_identities():
    known_hosts_content = ""
    subprocess.call("echo '' > ~/.ssh/known_hosts", shell=True)
    for address in dnsAddresses:
        # Kick the tires a bit, this helps the remote host to 'wake up', and for a network path to be learned by involved routers.
        for i in range(0,7):
            subprocess.call(timeout + " " + sshTime + " " + ssh_keyscan + " -H " + address + " > /dev/null 2>&1", shell=True)
            time.sleep(wait)

        time.sleep(wait)
        subprocess.call(timeout + " " + sshTime + " " + ssh_keyscan + " -H " + address + " >> ~/.ssh/known_hosts 2> /dev/null", shell=True)


def read_file(path):
    if os.path.isfile(path):
        with open(path, 'r') as content_file:
            try:
                return content_file.read()
            except Exception as e:
                return e
    else:
        return "The file '" + path + "' does not exist."


def append_file(path,content):
    try:
        with open(path, 'a') as content_file:
            content_file.write(content)
    except Exception as e:
        print "Exception appending to '" + str(path) + "'"
        print "Exception: " + str(e)
        

def overwrite_file(path,content):
    try:
        with open(path, 'w') as content_file:
            content_file.write(content)
    except Exception as e:
        print "Exception overwriting '" + str(path) + "'"
        print "Exception: " + str(e)




def make_dir(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)


def complete_threads(threads):
    # Start all the threads.
    for x in threads:
        x.start()

    # Wait for all threads to exit.
    for x in threads:
        x.join()


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

def restore_clean_snapshots():
    threads = []
    for OS in OSs:
        instance = get_instance("Name","fogtesting-" + OS)
        snapshot = get_snapshot("Name",OS + '-clean')
        if OS == "debian9":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"xvda")))
        elif OS == "centos7":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"/dev/sda1")))
        elif OS == "rhel7":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"/dev/sda1")))
        elif OS == "fedora29":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"/dev/sda1")))
        elif OS == "arch":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"/dev/sda1")))
        elif OS == "ubuntu18_04":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"/dev/sda1")))

    complete_threads(threads)



def restore_snapshot_to_instance(snapshot,instance,device):
    """
    Stop the instance
    detach and delete the old volume.
    Create a new volume
    Attach the new volume
    Start the instance
    """
    instance.stop(Force=True)
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
    newVolume = ec2client.create_volume(SnapshotId=snapshot.id,AvailabilityZone=zone,VolumeType='standard')
    newVolume = ec2resource.Volume(newVolume["VolumeId"])
    while True:
        newVolume.reload()
        if newVolume.state == "available":
            break
        else:
            time.sleep(wait)
    instance.attach_volume(VolumeId=newVolume.id,Device=device)
    while True:
        newVolume.reload()
        if newVolume.state == "in-use":
            break
        else:
            time.sleep(wait)

    instance.modify_attribute(BlockDeviceMappings=[{'Ebs': {'DeleteOnTermination': True}, 'DeviceName': device}])

    instance.start()
    wait_until_running(instance)





def runTest(branch,OS,webdir,statusDir,now,instance):
    make_dir(os.path.join(webdir,OS))
    make_dir(statusDir)
    commandsLog = os.path.join(statusDir,OS + "." + branch + ".remote_commands")
    if os.path.isfile(commandsLog):
        os.remove(commandsLog)
    
    # Create hidden file for node - for status reporting.
    with open(os.path.join(statusDir,OS + "." + branch + ".result"), 'w') as content_file:
        content_file.write("-1") 

    # print  "Kickin tires"
    # Kick the tires a bit, this helps the remote host to 'wake up', and for a network path to be learned by involved routers.
    command = timeout + " " + sshTime + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + OS + ' "echo wakeup" > /dev/null 2>&1'
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)
    command = timeout + " " + sshTime + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + OS + ' "echo get ready" > /dev/null 2>&1'
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)

    # print "Scp script to remote box"
    # Scp a script onto the remote box that we will later call.
    command = timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + os.path.join(cwd,'installBranch.sh') + " " + OS + ":/root/installBranch.sh"
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)

    # Get starting time
    d1 = datetime.datetime.now()


    # print "Starting installer"
    # Start the fog installer.
    command = timeout + " " + fogTimeout + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + OS + ' "/root/./installBranch.sh ' + branch + '"'
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)

    # Get ending time.
    d2 = datetime.datetime.now()

    # Calculate duration.
    duration = d2 - d1
    duration = str(datetime.timedelta(seconds=duration.total_seconds()))
    # Write duration to file.
    with open(os.path.join(statusDir,OS + "." + branch + ".duration"), 'w') as content_file:
        content_file.write(duration)


    # print "Getting result file"
    # Get the result file.
    command = timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/root/result " + os.path.join(statusDir,OS + "." + branch + ".result")
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)
    # This should send the result code of the attempt to something like /tmp/debian9.master.result


    # print "Getting output file"
    # Get the output file.
    command = timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/root/output " + os.path.join(webdir,OS,now + "_output.log")
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)


    # print "Getting fog log file"
    # Get the fog log.
    command = timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/root/git/fogproject/bin/error_logs/fog_error* " + os.path.join(webdir,OS,now + "_fog_error.log")
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)


    # print "Getting apache logs"
    # Get the apache error logs. Can be in only two places.
    command = timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/var/log/httpd/error_log " + os.path.join(webdir,OS,now + "_apache.log") + " > /dev/null 2>&1"
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)
    command = timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/var/log/apache2/error.log " + os.path.join(webdir,OS,now + "_apache.log") + " > /dev/null 2>&1"
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)

    # print "Getting php-fpm logs"
    # Get php-fpm logs. Can be in several places...
    command = timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/var/log/php-fpm/www-error.log " + os.path.join(webdir,OS,now + "_php-fpm.log") + " > /dev/null 2>&1"
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)
    command = timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/var/log/php-fpm/error.log " + os.path.join(webdir,OS,now + "_php-fpm.log") + " > /dev/null 2>&1"
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)
    command = timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/var/log/php*-fpm.log " + os.path.join(webdir,OS,now + "_php-fpm.log") + " > /dev/null 2>&1"
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)

    # print "Getting commit"
    # Get the commit the remote node was using, just as a sainity check.
    command = timeout + " " + sshTime + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + OS + ' "cd /root/git/fogproject;git rev-parse HEAD > /root/commit"'
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)
    command = timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/root/commit " + os.path.join(statusDir,OS + "." + branch + ".commit")
    append_file(commandsLog,command + "\n")
    subprocess.call(command, shell=True)
    # This should send just the commit that was used in the test to something like /tmp/debian9.master.commit

    # Kill the instance.
    instance.stop(Force=True)


    # print "Reading commit"
    # Read the commit.
    commit = read_file(os.path.join(statusDir,OS + "." + branch + ".commit"))


    # print "Rebuilding log"
    # Rebuild the log file to have information at the top of it.
    log = "Date=" + now + "\n"
    log = log + "Branch=" + branch + "\n"
    log = log + "Commit=" + commit # The commit comes back with a line feed in it.
    log = log + "OS=" + OS + "\n"
    log = log + "##### Begin Log #####\n"
    log = log + read_file(os.path.join(webdir,OS,now + "_fog_error.log"))

    # print "Writing log"
    # Write the new log.
    with open(os.path.join(webdir,OS,now + "_fog_error.log"), 'w') as content_file:
        content_file.write(log)



