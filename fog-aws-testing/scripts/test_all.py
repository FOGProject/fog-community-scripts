#!/usr/bin/python
import datetime
from threading import Thread
import subprocess
from functions import *

def runTest(branch,os,webdir,statusDir,now):
    subprocess.call(test_script + " " + branch + " " + os + " " + webdir + " " + statusDir + " " + now, shell=True)

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




