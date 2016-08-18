#!/bin/sh
#
# This script executes the "meg_quality_cronjob" script on the DCCN compute cluster.
#

cd /project/3010102.04/scripts/meg_quality
matlab_sub meg_quality_cronjob.m
