This directory contains the MATLAB code for the automated MEG
quality check that runs every night. If you want to look at the quality
of older data that is not present here any more, please ask Robert.

All MEG data is archived from the MEG acquisition computer to the data
repository and copied to a project directory on our network attached
central storage.

The quality check script is executed from a cronjob on mentat001 (login
node of our compute cluster), which in turn starts the actual quality
analysis as job on the compute cluster.

The cronjob on mentat001 consists of the following

````
16 1 * * * /project/3055020.02/code/meg_quality_cronjob.sh > /dev/null 2>&1

````

In the past we used Xvfb in the shell script to ensure that all figures
draw correctly. That is now not working any more, and the figures are
not created automatically.

