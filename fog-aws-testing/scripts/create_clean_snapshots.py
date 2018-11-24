#!/usr/bin/python


from functions import *
from settings import *


for os in OSs:
    instance = get_instance("Name","fogtesting-" + os)
    instance.stop()
    wait_until_stopped(instance)
    volume = get_instance_volume(instance)
    create_snapshot(volume,os + "-clean")




