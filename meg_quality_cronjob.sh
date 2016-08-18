#!/bin/sh
#
# This script executes the "meg_quality_cronjob" script.
#
# The use of Xvfb in the shell script is to ensure that all figures draw
# correctly. We had cases where a figure would not be saved to disk
# correctly due to the setup of making the figures without an actual
# (virtual) graphical terminal.
#

Xvfb :3 & 
sleep 5
cd /project/3010102.04/scripts/meg_quality
nice -19 /bin/matlab2011b -nodesktop -display :3 -r "meg_quality_cronjob"
killall Xvfb
