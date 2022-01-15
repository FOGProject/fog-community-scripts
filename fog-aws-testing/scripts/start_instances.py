#!/usr/bin/python3


from functions import *


for os in OSs:
    instance = get_instance("Name","fogtesting-" + os)
    instance.start()



