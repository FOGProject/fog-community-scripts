#!/usr/bin/python
from functions import *



now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%p")
# Get header file.
with open(os.path.join(scriptDir,headerHtml), 'r') as content_file:
    dashboard = content_file.read()
dashboard = dashboard + "\n<p>Last updated: " + now + " UTC</p><br>"

# Table opening and columns.
dashboard = dashboard + "\n<table>"
dashboard = dashboard + "\n<tr>"
dashboard = dashboard + "\n<th>OS</th>"
dashboard = dashboard + "\n<th>Branch</th>"
dashboard = dashboard + "\n<th>FOG Status</th>"
dashboard = dashboard + "\n<th>FOG Reason</th>"
dashboard = dashboard + "\n<th>Install Duration</th>"
dashboard = dashboard + "\n<th>Install Output</th>"
dashboard = dashboard + "\n<th>Install Error</th>"
dashboard = dashboard + "\n<th>Apache</th>"
dashboard = dashboard + "\n<th>php-fpm</th>"
dashboard = dashboard + "\n<th>Patch Status</th>"
dashboard = dashboard + "\n<th>Patch Duration</th>"
dashboard = dashboard + "\n<th>Patch Output</th>"
dashboard = dashboard + "\n</tr>"

# Remove statuses dir.
subprocess.call("rm -rf " + statusDir, shell=True)
# Remove web dir.
subprocess.call("rm -rf " + webdir, shell=True)


make_dir(statusDir)
make_dir(webdir)



for branch in branches:
    # Need a unique timestamp for each branch run.
    now = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%p")

    # Restore snapshots
    restore_clean_snapshots()

    # Wait for instances to get ready a bit.
    time.sleep(bootTime)

    # Add identities
    add_ssh_identities()

    # Run updates here.
    threads = []
    for OS in OSs:
        instance = get_instance("Name","fogtesting-" + OS)
        threads.append(Thread(target=update_os,args=(branch,OS,now,instance)))

    complete_threads(threads)

    # Run fog installation tests.
    threads = []
    for OS in OSs:
        instance = get_instance("Name","fogtesting-" + OS)
        threads.append(Thread(target=runTest,args=(branch,OS,now,instance)))

    complete_threads(threads)

    # Here, need to gather the results and write an html file.
    for OS in OSs:
        resultFile = os.path.join(statusDir, OS + "." + branch + ".result")
        with open(resultFile, 'r') as content_file:
            exitCode = content_file.read()

        dashboard = dashboard + "\n<tr>"
        dashboard = dashboard + "\n<td>" + OS + "</td>"
        dashboard = dashboard + "\n<td>" + branch + "</td>"

        # Fog install status.
        if exitCode in codes.keys():
            dashboard = dashboard + "\n<td><img src=\"" + codes[exitCode]["status"] + "\" alt=\"" + codes[exitCode]["status"] + "\"></td>"
            dashboard = dashboard + "\n<td>" + codes[exitCode]["reason"] + "</td>"
        else:
            dashboard = dashboard + "\n<td><img src=\"" + red + "\" alt=\"" + red + "\"></td>"
            dashboard = dashboard + "\n<td>Unknown installation failure, exit code '" + exitCode + "'</td>"

        # Fog install duration.
        if os.path.isfile(os.path.join(statusDir,OS + "." + branch + ".duration")):
            duration = read_file(os.path.join(statusDir,OS + "." + branch + ".duration"))
            dashboard = dashboard + "\n<td>" + duration + "</td>"
        else:
            dashboard = dashboard + "\n<td>NA</td>"


        # fog output log.
        if os.path.isfile(os.path.join(webdir,OS,now + "_output.log")):
            dashboard = dashboard + "\n<td><a href=\"" + http + s3bucket + port + netdir + "/" + OS + "/" + now + "_output.log\">output</td>"
        else:
            dashboard = dashboard + "\n<td>NA</td>"


        # fog error log.
        if os.path.isfile(os.path.join(webdir,OS,now + "_fog_error.log")):
            dashboard = dashboard + "\n<td><a href=\"" + http + s3bucket + port + netdir + "/" + OS + "/" + now + "_fog_error.log\">error</td>"
        else:
            dashboard = dashboard + "\n<td>NA</td>"

        # apache log.
        if os.path.isfile(os.path.join(webdir,OS,now + "_apache.log")):
            dashboard = dashboard + "\n<td><a href=\"" + http + s3bucket + port + netdir + "/" + OS + "/" + now + "_apache.log\">apache</a></td>"
        else:
            dashboard = dashboard + "\n<td>NA</td>"


        # php-fpm log.
        if os.path.isfile(os.path.join(webdir,OS,now + "_php-fpm.log")):
            dashboard = dashboard + "\n<td><a href=\"" + http + s3bucket + port + netdir + "/" + OS + "/" + now + "_php-fpm.log\">php-fpm</a></td>"
        else:
            dashboard = dashboard + "\n<td>NA</td>"


        # Patch results.
        resultFile = os.path.join(statusDir,OS + "." + branch + ".patch_result")
        with open(resultFile, 'r') as content_file:
            exitCode = content_file.read()
        if exitCode == "0":
            dashboard = dashboard + "\n<td><img src=\"" + green + "\" alt=\"green\"></td>"
        elif exitCode == "-1":
            dashboard = dashboard + "\n<td><img src=\"" + orange + "\" alt=\"orange\"></td>"
        else:
            dashboard = dashboard + "\n<td><img src=\"" + red + "\" alt=\"red\"></td>"


        # Patch duration.
        if os.path.isfile(os.path.join(statusDir,OS + "." + branch + ".patch_duration")):
            duration = read_file(os.path.join(statusDir,OS + "." + branch + ".patch_duration"))
            dashboard = dashboard + "\n<td>" + duration + "</td>"
        else:
            dashboard = dashboard + "\n<td>NA</td>"



        # Patch output.
        if os.path.isfile(os.path.join(webdir,OS,now + "_patch_output.log")):
            dashboard = dashboard + "\n<td><a href=\"" + http + s3bucket + port + netdir + "/" + OS + "/" + now + "_patch_output.log\">patch</a></td>"
        else:
            dashboard = dashboard + "\n<td>NA</td>"


        dashboard = dashboard + "\n</tr>"

# Close table.
dashboard = dashboard + "\n</table>"


# Get the footer html.
with open(os.path.join(scriptDir,footerHtml), 'r') as content_file:
    dashboard = dashboard + "\n" + content_file.read()

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



