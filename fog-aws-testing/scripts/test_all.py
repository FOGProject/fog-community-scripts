#!/usr/bin/python
import datetime
from threading import Thread
from functions import *
import time
import sys


def runTest(branch,OS,webdir,statusDir,now):
    make_dir(os.path.join(webdir,OS))
    make_dir(statusDir)

    
    # Create hidden file for node - for status reporting.
    # print "Creating " + str(os.path.join(statusDir,OS + "." + branch + ".result"))
    with open(os.path.join(statusDir,OS + "." + branch + ".result"), 'w') as content_file:
        content_file.write("-1") 

    # print  "Kickin tires"
    # Kick the tires a bit, this helps the remote host to 'wake up', and for a network path to be learned by involved routers.
    subprocess.call(timeout + " " + sshTime + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + OS + ' "echo wakeup" > /dev/null 2>&1', shell=True)
    subprocess.call(timeout + " " + sshTime + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + OS + ' "echo get ready" > /dev/null 2>&1', shell=True)

    # print "Scp script to remote box"
    # Scp a script onto the remote box that we will later call.
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + os.path.join(cwd,'installBranch.sh') + " " + OS + ":/root/installBranch.sh", shell=True)

    # print "Starting installer"
    # Start the fog installer.
    subprocess.call(timeout + " " + fogTimeout + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + OS + ' "/root/./installBranch.sh ' + branch + '"', shell=True)

    # print "Getting result file"
    # Get the result file.
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/root/result " + os.path.join(statusDir,OS + "." + branch + ".result"), shell=True)
    # This should send the result code of the attempt to something like /tmp/debian9.master.result

    # print "Getting fog log file"
    # Get the fog log.
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/root/git/fogproject/bin/error_logs/fog_error* " + os.path.join(webdir,OS,now + "_install.log"), shell=True)

    # print "Getting apache logs"
    # Get the apache error logs. Can be in only two places.
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/var/log/httpd/error_log " + os.path.join(webdir,OS,now + "_apache.log") + " > /dev/null 2>&1", shell=True)
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/var/log/apache2/error.log " + os.path.join(webdir,OS,now + "_apache.log") + " > /dev/null 2>&1", shell=True)

    # print "Getting php-fpm logs"
    # Get php-fpm logs. Can be in several places...
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/var/log/php-fpm/www-error.log " + os.path.join(webdir,OS,now + "_php-fpm.log") + " > /dev/null 2>&1", shell=True)
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/var/log/php-fpm/error.log " + os.path.join(webdir,OS,now + "_php-fpm.log") + " > /dev/null 2>&1", shell=True)
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/var/log/php*-fpm.log " + os.path.join(webdir,OS,now + "_php-fpm.log") + " > /dev/null 2>&1", shell=True)

    # print "Getting commit"
    # Get the commit the remote node was using, just as a sainity check.
    subprocess.call(timeout + " " + fogTimeout + " " + ssh + " -o ConnectTimeout=" + sshTimeout + " " + OS + ' "cd /root/git/fogproject;git rev-parse HEAD > /root/commit"', shell=True)
    subprocess.call(timeout + " " + sshTime + " " + scp + " -o ConnectTimeout=" + sshTimeout + " " + OS + ":/root/commit " + os.path.join(statusDir,OS + "." + branch + ".commit"), shell=True)
    # This should send just the commit that was used in the test to something like /tmp/debian9.master.commit

    # print "Reading commit"
    # Read the commit.
    commit = read_file(os.path.join(statusDir,OS + "." + branch + ".commit"))

    # print "Rebuilding log"
    # Rebuild the log file to have information at the top of it.
    log = "Date=" + now + "\n"
    log = log + "Branch=" + branch + "\n"
    log = log + "Commit=" + commit + "\n"
    log = log + "OS=" + OS + "\n"
    log = log + "##### Begin Log #####\n"
    log = log + read_file(os.path.join(webdir,OS,now + "_install.log"))

    # print "Writing log"
    # Write the new log.
    with open(os.path.join(webdir,OS,now + "_install.log"), 'w') as content_file:
        content_file.write(log)

now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%p")
# Get initial index.html file.
with open(indexHtml, 'r') as content_file:
    dashboard = content_file.read()
dashboard = dashboard + "\n<caption>Clean FOG Installation Status, last updated: " + now + "</caption>"

for branch in branches:
    threads = []
    for OS in OSs:
        instance = get_instance("Name","fogtesting-" + OS)
        snapshot = get_snapshot("Name",OS + '-clean')
        if OS == "debian9":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"xvda")))
        elif OS == "centos7":
            threads.append(Thread(target=restore_snapshot_to_instance,args=(snapshot,instance,"/dev/sda1")))

    complete_threads(threads)

    # Wait for instances to get ready a bit.
    time.sleep(15)

    # Add identities
    add_ssh_identities()

    # Reset threads.
    threads = []
    for OS in OSs:
        threads.append(Thread(target=runTest,args=(branch,OS,webdir,statusDir,now)))

    complete_threads(threads)

    dashboard = dashboard + "\n<table>"
    dashboard = dashboard + "\n<tr>"
    dashboard = dashboard + "\n<th>OS</th>"
    dashboard = dashboard + "\n<th>Branch</th>"
    dashboard = dashboard + "\n<th>Status</th>"
    dashboard = dashboard + "\n<th>Reason</th>"
    dashboard = dashboard + "\n<th>Install Log</th>"
    dashboard = dashboard + "\n<th>Apache Log</th>"
    dashboard = dashboard + "\n<th>php-fpm Log</th>"
    dashboard = dashboard + "\n</tr>"

    # Here, need to gather the results and write an html file.
    for OS in OSs:
        resultFile = os.path.join(statusDir, OS + "." + branch + ".result")
        with open(resultFile, 'r') as content_file:
            exitCode = content_file.read()

        dashboard = dashboard + "\n<tr>"
        dashboard = dashboard + "\n<td>" + OS + "</td>"
        dashboard = dashboard + "\n<td>" + branch + "</td>"

        if exitCode in codes.keys():
            dashboard = dashboard + "\n<td>" + codes[exitCode]["status"] + "</td>"
            dashboard = dashboard + "\n<td>" + codes[exitCode]["reason"] + "</td>"
        else:
            dashboard = dashboard + "\n<td>" + red + "</td>"
            dashboard = dashboard + "\n<td>Unknown installation failure, exit code '" + exitCode + "'</td>"


        if os.path.isfile(os.path.join(webdir,OS,now + "_install.log")):
            dashboard = dashboard + "\n<td><a href=\"" + http + s3bucket + port + netdir + "/" + OS + "/" + now + "_install.log\">Install log</td>"
        else:
            dashboard = dashboard + "\n<td>Could not be retrieved</td>"

        if os.path.isfile(os.path.join(webdir,OS,now + "_apache.log")):
            dashboard = dashboard + "\n<td><a href=\"" + http + s3bucket + port + netdir + "/" + OS + "/" + now + "_apache.log\">Apache log</a></td>"
        else:
            dashboard = dashboard + "\n<td>Could not be retrieved</td>"


        if os.path.isfile(os.path.join(webdir,OS,now + "_php-fpm.log")):
            dashboard = dashboard + "\n<td><a href=\"" + http + s3bucket + port + netdir + "/" + OS + "/" + now + "_php-fpm.log\">php-fpm log</a></td>"
        else:
            dashboard = dashboard + "\n<td>Could not be retrieved</td>"

        dashboard = dashboard + "\n</tr>"
    dashboard = dashboard + "\n</table>"

# Write out the dashboard.
newDashboard = os.path.join(webdir,"index.html")
with open(newDashboard, 'w') as content_file:
    content_file.write(dashboard)

# Sync the dashboard to s3.
subprocess.call(s3cmd + " sync " + webdir + "/ s3://" + s3bucket + " > /dev/null 2>&1", shell=True)



