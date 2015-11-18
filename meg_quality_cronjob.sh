#!/bin/sh
#
# this script executes the meg_quality_cronjob 
Xvfb :3 & 
sleep 5
cd /home/common/meg_quality
nice -19 /bin/matlab2011b -nodesktop -display :3 -r "meg_quality_cronjob"
killall Xvfb
