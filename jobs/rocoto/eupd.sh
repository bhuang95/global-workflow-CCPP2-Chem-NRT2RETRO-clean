#!/bin/ksh -x

###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Execute the JJOB
#$HOMEgfs/jobs/JGLOBAL_ENKF_UPDATE
export CASE=${CASE_ENKF:-"C96"}
$HOMEgfs/jobs/JGLOBAL_AEROENKF_UPDATE
status=$?
exit $status
