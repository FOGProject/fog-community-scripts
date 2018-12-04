#!/usr/bin/python
import datetime
from threading import Thread
import subprocess
from functions import *

def runTest(branch,os,webdir,statusDir,now):
    make_dir(webdir)
    make_dir(statusDir)
    
    # Create hidden file for node - for status reporting.
    print "Creating " + os.path.join(statusDir,name + "." + branch)
    with open(os.path.join(statusDir,name + "." + branch), 'w') as content_file:
        content_file.write("-1") 

    print  "Kickin tires"
    # Kick the tires a bit, this helps the remote host to 'wake up', and for a network path to be learned by involved routers.
    subprocess.call(timeout + " " + sshTime + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + os + ' "echo wakeup"', shell=True)
    subprocess.call(timeout + " " + sshTime + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + os + ' "echo get ready"', shell=True)

    print "Scp script to remote box"
    # Scp a script onto the remote box that we will later call.
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + os.path.join(cwd,'installBranch.sh') + " " + os + ":/root/installBranch.sh", shell=True)

    print "Starting installer"
    # Start the fog installer.
    subprocess.call(timeout + " " + fogTimeout + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + os + ' "/root/./installBranch.sh ' + branch + '"', shell=True)

    print "Getting result file"
    # Get the result file.
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + os + ":/root/result " + os.path.join(statusDir,os + "." + branch + ".result"), shell=True)
    # This should send the result code of the attempt to something like /tmp/debian9.master.result

    print "Getting fog log file"
    # Get the fog log.
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + os + ":/root/git/fogproject/bin/error_logs/fog_error* " + os.path.join(webdir,os,now + "_installer.log"), shell=True)

    print "Getting apache logs"
    # Get the apache error logs. Can be in only two places.
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + os + ":/var/log/httpd/error_log " + os.path.join(webdir,os,now + "_apache.log"), shell=True)
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + os + ":/var/log/apache2/error.log " + os.path.join(webdir,os,now + "_apache.log"), shell=True)

    print "Getting php-fpm logs"
    # Get php-fpm logs. Can be in only two places.
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + os + ":/var/log/php-fpm/www-error.log " + os.path.join(webdir,os,now + "_php-fpm.log"), shell=True)
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + os + ":/var/log/php-fpm/error.log " + os.path.join(webdir,os,now + "_php-fpm.log"), shell=True)

    print "Getting commit"
    # Get the commit the remote node was using, just as a sainity check.
    subprocess.call(timeout + " " + fogTimeout + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + os + 'cd /root/git/fogproject;git rev-parse HEAD > /root/commit', shell=True)
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + os + ":/root/commit " + os.path.join(statusDir,os + "." + branch + ".commit"), shell=True)
    # This should send just the commit that was used in the test to something like /tmp/debian9.master.commit

    print "Reading commit"
    # Read the commit.
    commit = read_file(os.path.join(statusDir,os + "." + branch + ".commit"))

    print "Rebuilding log"
    # Rebuild the log file to have information at the top of it.
    log = "Date=" + now + "\n"
    log = log + "Branch=" + branch + "\n"
    log = log + "Commit=" + commit + "\n"
    log = log + "OS=" + os + "\n"
    log = log + "##### Begin Log #####\n"
    log = log + read_file(os.path.join(webdir,os,now + "_installer.log"))

    print "Writing log"
    # Write the new log.
    with open(os.path.join(webdir,os,now + "_installer.log"), 'w') as content_file:
        content_file.write(log)



threads = []
for os in OSs:
    instance = get_instance("Name","fogtesting-" + os)
    snapshot = get_snapshot("Name",os + '-clean')
    if os == "debian9":
        threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"xvda")))
    elif os == "centos7":
        threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"/dev/sda1")))

complete_threads(threads)

now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%p")
# Get initial index.html file.
with open(indexHtml, 'r') as content_file:
    dashboard = content_file.read()
dashboard = dashboard + "<caption>Clean FOG Installation Status, last updated: " + now + "</caption>"

for branch in branches:
    threads = []
    for os in OSs:
        instance = get_instance("Name","fogtesting-" + os)
        snapshot = get_snapshot("Name",os + '-clean')
        if os == "debian9":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"xvda")))
        elif os == "centos7":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"/dev/sda1")))

    complete_threads(threads)

    # Reset threads.
    threads = []
    for os in OSs:
        threads.append(Thread(target=runTest,args=(branch,os,webdir,statusDir,now)))

    complete_threads(threads)

    dashboard = dashboard + "\n<table>"
    dashboard = dashboard + "\n<tr>"
    dashboard = dashboard + "\n<th>OS</th>"
    dashboard = dashboard + "\n<th>Branch</th>"
    dashboard = dashboard + "\n<th>Status</th>"
    dashboard = dashboard + "\n<th>Reason</th>"
    dashboard = dashboard + "\n<th>Fog Log</th>"
    dashboard = dashboard + "\n<th>Apache Log</th>"
    dashboard = dashboard + "\n</tr>"

    # Here, need to gather the results and write an html file.
    for os in OSs:
        statusFile = os.path.join(statusDir, os + "." + branch)
        with open(statusFile, 'r') as content_file:
            exitCode = content_file.read()

        dashboard = dashboard + "\n<tr>"
        dashboard = dashboard + "\n<td>" + os + "</td>"
        dashboard = dashboard + "\n<td>" + branch + "</td>"
        if exitCode in codes.keys():
            dashboard = dashboard + "\n<td>" + codes[exitCode]["status"] + "</td>"
            dashboard = dashboard + "\n<td>" + codes[exitCode]["reason"] + "</td>"
        else:
            dashboard = dashboard + "\n<td>" + red + "</td>"
            dashboard = dashboard + "\n<td>Unknown installation failure, exit code '" + exitCode + "'</td>"
        dashboard = dashboard + "\n<td><a href=\"" + http + domainname + port + netdir + "/" + os + "/" + now + "_fog.log\">Fog log</td>"
        dashboard = dashboard + "\n<td><a href=\"" + http + domainname + port + netdir + "/" + os + "/" + now + "_apache.log\">Apache log</a></td>"
        dashboard = dashboard + "\n</tr>"
    dashboard = dashboard + "\n</table>"

# Write out the dashboard.
newDashboard = os.path.join(webdir,"index.html")
with open(newDashboard, 'w') as content_file:
    content_file.write(dashboard)




