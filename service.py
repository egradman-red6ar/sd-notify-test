#!/usr/bin/python3

import sys
import os
import logging
import signal
import time
import argparse
import sdnotify

my_name = os.path.basename(sys.argv[0])

logging.basicConfig(
    stream=sys.stdout,
    level=logging.DEBUG,
)
log = logging.getLogger(my_name)

log.info("starting")
log.info("sleeping 6s for initialization")
time.sleep(6)
log.info("fully started")

n = sdnotify.SystemdNotifier()
n.notify("READY=1")

i = 0
while True:
    log.info(f"loop {i}")
    i+=1
    time.sleep(5)




