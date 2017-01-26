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
12 1 * * * /project/3055020.01/scripts/meg_cleanup.sh 
16 1 * * * /project/3055020.01/scripts/meg_quality.sh 

````

The use of Xvfb in the shell script is to ensure that all figures draw
correctly. We had cases where a figure would not be saved to disk
correctly due to the setup of making the figures without an actual
(virtual) graphical terminal.

