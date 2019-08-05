#!/bin/sh
#
# This script executes the "meg_quality_cronjob" MATLAB script on the DCCN compute cluster.
#

# since this script is started from a cronjob, the path and environment variables are emtpy
# set the correct path and ensure modules are available
source /opt/optenv.sh
module load matlab/R2012b

# this is where qsub is installed
export PATH=/var/spool/torque/bin:${PATH}

cd /project/3055020.01/scripts/meg_quality
matlab_sub meg_quality_cronjob.m
