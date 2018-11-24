#!/usr/bin/python


from functions import *


for os in OSs:
    instance = get_instance("Name","fogtesting-" + os)
    snapshot = get_snapshot("Name",os + '-clean')
    restore_snapshot_to_instance(snapshot,instance)




