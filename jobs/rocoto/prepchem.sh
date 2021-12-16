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
#configs="base prepchem"
#for config in $configs; do
#    . $EXPDIR/config.${config}
#    status=$?
#    [[ $status -ne 0 ]] && exit $status
#done
###############################################################

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
EMITYPE=${EMITYPE:-"2"}
CDATE=${CDATE:-"2021061500"}
GBBDIR=${GBBDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/GBBEPx/"}
GBBEPx_SHIFT=${GBBEPx_SHIFT:-"FALSE"}
GBBEPx_SHIFT_HR=${GBBEPx_SHIFT_HR:-"0"}
CASE_CNTL=${CASE_CNTL:-"C96"}
CASE_ENKF=${CASE_ENKF:-"C96"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}

NLN='ln -sf'
if [ ${GBBEPx_SHIFT} == "TRUE" ]; then
    GBBEPx_DATE=$(${NDATE} ${GBBEPx_SHIFT_HR} ${CDATE})
else
    GBBEPx_DATE=${CDATE}
fi

CYY=`echo "${CDATE}" | cut -c1-4`
CMM=`echo "${CDATE}" | cut -c5-6`
CDD=`echo "${CDATE}" | cut -c7-8`
CHH=`echo "${CDATE}" | cut -c9-10`


GBBYY=`echo "${GBBEPx_DATE}" | cut -c1-4`
GBBMM=`echo "${GBBEPx_DATE}" | cut -c5-6`
GBBDD=`echo "${GBBEPx_DATE}" | cut -c7-8`
GBBHH=`echo "${GBBEPx_CDATE}" | cut -c9-10`

export RUNDIR="$STMP/RUNDIRS/$PSLOT"
export DATA="$RUNDIR/$CDATE/$CDUMP"
[[ ! -d $DATA ]] && mkdir -p $DATA


if [ ${CASE_CNTL} = ${CASE_ENKF} ]; then
    CASES=${CASE_CNTL}
else
    CASES="${CASE_CNTL} ${CASE_ENKF}"
fi


for CASE in ${CASES}; do

mkdir -p ${DATA}/prep_${CASE}
cd ${DATA}/prep_${CASE}

res=`echo $CASE | cut -c2-4`

for n in $(seq 1 6); do
    tiledir=tile${n}
    EMIINPUT=/scratch1/BMC/gsd-fv3-dev/Haiqin.Li/Develop/emi_${CASE}
    eval $NLN $EMIINPUT/EMI/$CMM/emi_data.tile${n}.nc .
    eval $NLN $EMIINPUT/EMI2/$CMM/emi2_data.tile${n}.nc .
    eval $NLN $EMIINPUT/fengsha/$CMM/dust_data.tile${n}.nc .
    
    if [ $EMITYPE -eq 2 ]; then
      NCGB=${GBBDIR}/${CASE}/
      PUBEMI=/scratch2/BMC/public/data/grids/sdsu/emissions
    
      emiss_date1="${GBBYY}${GBBMM}${GBBDD}" # default value for branch testing      
      print "emiss_date: $emiss_date1"
 
      if [[ -f $NCGB/${emiss_date1}/FIRE_GBBEPx_data.tile${n}.nc ]]; then
        # -orig echo "NetCDF GBBEPx File $DIRGB/${emiss_date1}/FIRE_GBBEPx_data.tile${n}.nc  exists, just link."
        echo "NetCDF GBBEPx File $NCGB/${emiss_date1}/FIRE_GBBEPx_data.tile${n}.nc  exists, just link."
      else
        echo "NetCDF GBBEPx File $NCGB/${emiss_date1}/FIRE_GBBEPx_data.tile${n}.nc  does  not exist, and exit"
	exit 1
      fi
      eval $NLN $NCGB/${emiss_date1}/FIRE_GBBEPx_data.tile${n}.nc .
    fi
done
rc=$?
done # end of CASE loop
if [ $rc -ne 0 ]; then
     echo "error prepchem $rc "
     exit $rc
else
    exit $rc
fi 


###############################################################

###############################################################
# Exit cleanly

