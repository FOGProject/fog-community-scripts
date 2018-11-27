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
    instance = get_instance("Name","fogtesting-" + os)
    threads.append(Thread(target=create_clean_snapshot,args=(os,instance)))

# Start all the threads.
for x in threads:
    x.start()

# Wait for all threads to exit.
for x in threads:
    x.join()



