#!/bin/ksh -x

###############################################################
## Abstract:
## Create biomass burning emissions for FV3-CHEM
## RUN_ENVIR : runtime environment (emc | nco)
## HOMEgfs   : /full/path/to/workflow
## EXPDIR : /full/path/to/config/files
## CDATE  : current date (YYYYMMDDHH)
## CDUMP  : cycle name (gdas / gfs)
## PDY    : current date (YYYYMMDD)
## cyc    : current cycle (HH)
###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Source relevant configs
export CASE=${CASE_CNTL:-"C96"}
configs="base anal"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done
###############################################################

##########################################
# Source machine runtime environment
##########################################
. $HOMEgfs/env/${machine}.env anal 
status=$?
[[ $status -ne 0 ]] && exit $status

export DATA=${DATA:-${DATAROOT}/${jobid:?}}

mkdir -p $DATA
cd $DATA
###############################################################
# Execute the JJOB
$HOMEgfs/jobs/JJEDI_ANALYSIS
status=$?
[[ $status -ne 0 ]] && exit $status

###############################################################
# Exit cleanly
##########################################
# Remove the Temporary working directory
##########################################
cd $DATAROOT
KEEPDATA="NO"
[[ $KEEPDATA = "NO" ]] && rm -rf $DATA

date
exit 0

