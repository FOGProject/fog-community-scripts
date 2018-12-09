#!/usr/bin/python
from functions import *



now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%p")
# Get initial index.html file.
with open(os.path.join(scriptDir,indexHtml), 'r') as content_file:
    dashboard = content_file.read()
dashboard = dashboard + "\n<caption>Clean FOG Installation Status, last updated: " + now + "</caption>"

# Table opening and columns.
dashboard = dashboard + "\n<table>"
dashboard = dashboard + "\n<tr>"
dashboard = dashboard + "\n<th>OS</th>"
dashboard = dashboard + "\n<th>Branch</th>"
dashboard = dashboard + "\n<th>Status</th>"
dashboard = dashboard + "\n<th>Reason</th>"
dashboard = dashboard + "\n<th>Duration</th>"
dashboard = dashboard + "\n<th>Output Log</th>"
dashboard = dashboard + "\n<th>Fog Error Log</th>"
dashboard = dashboard + "\n<th>Apache Log</th>"
dashboard = dashboard + "\n<th>php-fpm Log</th>"
dashboard = dashboard + "\n</tr>"

# Remove statuses dir.
subprocess.call("rm -rf " + statusDir, shell=True)
# Remove web dir.
subprocess.call("rm -rf " + webdir, shell=True)


for branch in branches:

    # Restore snapshots
    restore_clean_snapshots()

    # Wait for instances to get ready a bit.
    time.sleep(60)

    # Add identities
    add_ssh_identities()

    # Reset threads.
    threads = []
    for OS in OSs:
        instance = get_instance("Name","fogtesting-" + OS)
        threads.append(Thread(target=runTest,args=(branch,OS,webdir,statusDir,now,instance)))

    complete_threads(threads)

    # Here, need to gather the results and write an html file.
    for OS in OSs:
        resultFile = os.path.join(statusDir, OS + "." + branch + ".result")
        with open(resultFile, 'r') as content_file:
            exitCode = content_file.read()

        dashboard = dashboard + "\n<tr>"
        dashboard = dashboard + "\n<td>" + OS + "</td>"
        dashboard = dashboard + "\n<td>" + branch + "</td>"

        if exitCode in codes.keys():
            dashboard = dashboard + "\n<td><img src=\"" + codes[exitCode]["status"] + "\" alt=\"" + codes[exitCode]["status"] + "\"></td>"
            dashboard = dashboard + "\n<td>" + codes[exitCode]["reason"] + "</td>"
        else:
            dashboard = dashboard + "\n<td><img src=\"" + red + "\" alt=\"" + red + "\"></td>"
            dashboard = dashboard + "\n<td>Unknown installation failure, exit code '" + exitCode + "'</td>"


        if os.path.isfile(os.path.join(statusDir,OS + "." + branch + ".duration")):
            duration = read_file(os.path.join(statusDir,OS + "." + branch + ".duration"))
            dashboard = dashboard + "\n<td>" + duration + "</td>"
        else:
            dashboard = dashboard + "\n<td>Could not be retrieved</td>"



        if os.path.isfile(os.path.join(webdir,OS,now + "_output.log")):
            dashboard = dashboard + "\n<td><a href=\"" + http + s3bucket + port + netdir + "/" + OS + "/" + now + "_output.log\">Output log</td>"
        else:
            dashboard = dashboard + "\n<td>Could not be retrieved</td>"


        if os.path.isfile(os.path.join(webdir,OS,now + "_fog_error.log")):
            dashboard = dashboard + "\n<td><a href=\"" + http + s3bucket + port + netdir + "/" + OS + "/" + now + "_fog_error.log\">Install log</td>"
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

# Close table.
dashboard = dashboard + "\n</table>"


# Write out the dashboard.
newDashboard = os.path.join(webdir,"index.html")
with open(newDashboard, 'w') as content_file:
    content_file.write(dashboard)

# Ensure the little color dots are in the web dir.
if not os.path.isfile(os.path.join(webdir,green)):
    subprocess.call("cp " + os.path.join(scriptDir,green) + " " + os.path.join(webdir,green), shell=True)

if not os.path.isfile(os.path.join(webdir,orange)):
    subprocess.call("cp " + os.path.join(scriptDir,orange) + " " + os.path.join(webdir,orange), shell=True)

if not os.path.isfile(os.path.join(webdir,red)):
    subprocess.call("cp " + os.path.join(scriptDir,red) + " " + os.path.join(webdir,red), shell=True)

# Sync the dashboard to s3.
subprocess.call(s3cmd + " sync " + webdir + "/ s3://" + s3bucket + " > /dev/null 2>&1", shell=True)



