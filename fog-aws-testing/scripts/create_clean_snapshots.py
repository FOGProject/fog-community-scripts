#!/usr/bin/python
from threading import Thread
from functions import *

def create_clean_snapshot(os,instance):
    instance.stop()
    wait_until_stopped(instance)
    volume = get_instance_volume(instance)
    create_snapshot(volume,os + "-clean")

threads = []
for os in OSs:
    delete_snapshots("Name", os + "-clean")
    threads.append(Thread(target=delete_snapshots,args=("Name", os + "-clean")))

complete_threads(threads)

threads = []
for os in OSs:
    instance = get_instance("Name","fogtesting-" + os)
    threads.append(Thread(target=create_clean_snapshot,args=(os,instance)))

complete_threads(threads)



