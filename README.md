This directory contains the scripts and results from the automated MEG
quality check that runs every night. If you want to look at the quality
of older data that is not present here any more, please ask Robert.

The data partition of odin (our MEG acquisition computer) is NFS exported
to lap-pre042 (our realtime linux computer).

The cronjob running on lab-pre042 consists of the following

````
11 00 * * * /home/common/meg_quality/meg_quality_cronjob.sh > /dev/null 2>&1
````
