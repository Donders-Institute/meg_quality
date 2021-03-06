#!/bin/sh
#
# This script executes the "meg_quality_cronjob" MATLAB script on the DCCN compute cluster.
#

# since this script is started from a cronjob, the path and environment variables are emtpy
# set the correct path and ensure modules are available
source /opt/optenv.sh
module load matlab/R2020a

# this is where qsub is installed
export PATH=/var/spool/torque/bin:${PATH}

cd /project/3055020.02/code
matlab_sub meg_quality_cronjob.m
