#!/bin/bash

scp -r -v -d /root/Scripts/*.* nenad@192.168.1.194:/home/nenad/Scripts-GL-E750
scp -r -v -d /root/Scripts/Old_Scripts/*.* nenad@192.168.1.194:/home/nenad/Scripts-GL-E750/Old_Scripts

