#!/usr/bin/python


from functions import *


for os in OSs:
    instance = get_instance("Name","fogtesting-" + os)
    snapshot = get_snapshot("Name",os + '-clean')
    if os == "debian9":
        restore_snapshot_to_instance(snapshot,instance,"xvda")
    elif os == "centos7":
        restore_snapshot_to_instance(snapshot,instance,"/dev/sda1")




