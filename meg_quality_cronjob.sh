#!/bin/sh
#
# This script executes the "meg_quality_cronjob" script on the DCCN compute cluster.
#

# since this script is started from a cronjob, the path and environment variables are emtpy
# set the correct path and ensure modules are available
source /opt/optenv.sh
module load matlab/R2012b

cd /project/3010102.04/scripts/meg_quality
/opt/cluster/bin/matlab_sub meg_quality_cronjob.m
