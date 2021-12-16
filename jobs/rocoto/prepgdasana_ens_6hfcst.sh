#!/bin/bash
##SBATCH -A wrf-chem
##SBATCH -q debug
##SBATCH -t 30:00
##SBATCH -n 128
###SBATCH --nodes=4
##SBATCH -J calc_analysis
##SBATCH -o log.out

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
###############################################################
# Source relevant configs
#configs="base"
#for config in $configs; do
#    . $EXPDIR/config.${config}
#    status=$?
#    [[ $status -ne 0 ]] && exit $status
#done
###############################################################
set -x
HOMEgfs=${HOMEgfs:-"/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean"}
HOMEjedi=${HOMEjedi:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/V20210303/build/"}
PSLOT=${PSLOT:-"global-workflow-CCPP2-Chem-NRT-clean"}
ROTDIR=${ROTDIR:-""}
CDATE=${CDATE:-"2021062812"}
CASE_ENKF=${CASE_ENKF:-"C96"}
CASE_ENKF_GDAS=${CASE_ENKF_GDAS:-"C384"}
ENSFILE_MISSING=${ENSFILE_MISSING:-"NO"}
FHR=${FHR:-"06"}
#HBO
METDIR_WCOSS=${METDIR_WCOSS:-"/scratch1/BMC/chem-var/pagowski/junk_scp/wcoss/"}
#METDIR_WCOSS=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/test-prepgdasana_ens/data/
METDIR_HERA=${METDIR_HERA:-"/scratch1/NCEPDEV/rstprod/com/gfs/prod/"}
METDIR_NRT=${METDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/gdasAna/"}
CDUMP=${CDUMP:-"gdas"}
NMEM_AERO=${NMEM_AERO:-"20"}
NMEM_AERO_ENSGRP=${NMEM_AERO_ENSGRP:-"4"}
ENSGRP=${ENSGRP:-"01"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
ANAEXEC=${ANAEXEC:-"${HOMEgfs}/exec/calc_analysis.x"}
#CHGRESEXEC_GAU=${CHGRESEXEC_GAU:-"${HOMEgfs}/exec/chgres_recenter_ncio_Judy_v16.exe"}
CHGRESEXEC_GAU=${CHGRESEXEC_GAU:-"${HOMEgfs}/exec/chgres_recenter_ncio_v16.exe"}
AVESFCVAREXEC=${AVESFCVAREXEC:-"${HOMEgfs}/exec/average_vars.x"}
#HBO
ENSEND=$((NMEM_AERO_ENSGRP * ENSGRP))
ENSBEG=$((ENSEND - NMEM_AERO_ENSGRP + 1))
#ENSBEG=1
#ENSEND=1

NLN='/bin/ln -sf'
NRM='/bin/rm -rf'
NMV='/bin/mv'
NCP='/bin/cp -r'

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
#HBO
export DATA="$RUNDIR/$CDATE/$CDUMP/prepensana.grp${ENSGRP}.$$"

[[ ! -d $DATA ]] && mkdir -p $DATA
cd $DATA || exit 10


CYY=`echo "${CDATE}" | cut -c1-4`
CMM=`echo "${CDATE}" | cut -c5-6`
CDD=`echo "${CDATE}" | cut -c7-8`
CHH=`echo "${CDATE}" | cut -c9-10`
CYMD=${CYY}${CMM}${CDD}

GDATE=$(${NDATE} -${FHR} ${CDATE})
GYY=`echo "${GDATE}" | cut -c1-4`
GMM=`echo "${GDATE}" | cut -c5-6`
GDD=`echo "${GDATE}" | cut -c7-8`
GHH=`echo "${GDATE}" | cut -c9-10`

CDATEP3=$(${NDATE} 3 ${CDATE})
CP3YY=`echo "${CDATEP3}" | cut -c1-4`
CP3MM=`echo "${CDATEP3}" | cut -c5-6`
CP3DD=`echo "${CDATEP3}" | cut -c7-8`
CP3HH=`echo "${CDATEP3}" | cut -c9-10`
CP3YMD=${CP3YY}${CP3MM}${CP3DD}

CDATEM3=$(${NDATE} -3 ${CDATE})
CM3YY=`echo "${CDATEM3}" | cut -c1-4`
CM3MM=`echo "${CDATEM3}" | cut -c5-6`
CM3DD=`echo "${CDATEM3}" | cut -c7-8`
CM3HH=`echo "${CDATEM3}" | cut -c9-10`
CM3YMD=${CM3YY}${CM3MM}${CM3DD}

### STEP 1: Untar SFC files copied from wcoss
#if [ ${ENSFILE_MISSING} = "NO" ]; then
#echo "STEP-1: Untar SFC files copied from wcoss"
#if [ ${ENSGRP} -gt 0 ]; then            
#
#    [[ ! -d ${DATA}/wcossdata ]] && mkdir -p ${DATA}/wcossdata
#    TARFILE=${METDIR_WCOSS}/gg/enkf${CDUMP}.${GDATE}_grp${ENSGRP}.tar
#    tar -xvf ${TARFILE}  --directory ${DATA}/wcossdata
#    ERR1=$?
#    ERR1=0
#
#    if [[ $ERR1 -ne 0 ]]; then
#        echo "Untar SFC file failed and exit"
#        exit $ERR1
#    fi
#else
#    echo "ENSGRP need to be larger than zero to generate ensemble atmos analysis, and exit"
#    exit 1
#fi
#else
#    echo "WCOSS ensemble file missing and skip step 1"
#    ERR1=0
#fi

#if [[ 1 -eq 0 ]]; then
### Step 2 Loop through members to recover ensemble analysis from background and increment files.
echo "STEP-2: Loop through members to recover ensemble analysis from background and increment files"
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

[[ ! -d ${DATA}/heradata ]] && mkdir -p ${DATA}/heradata

mem0=${ENSBEG}
while [[ ${mem0} -le ${ENSEND} ]]; do
    echo ${mem0}
    mem1=`printf %03d ${mem0}`
    mem="mem${mem1}"
    [[ ! -d ${DATA}/heradata/${mem} ]] && mkdir -p ${DATA}/heradata/${mem}
    #METDIR_HERA=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/
    ${NLN} ${METDIR_HERA}/enkf${CDUMP}.${CYY}${CMM}${CDD}/${CHH}/atmos/${mem}/${CDUMP}.t${CHH}z.ratminc.nc ${DATA}/heradata/${mem}/${CDUMP}.t${CHH}z.ratminc.nc.${FHR}
    ${NLN} ${METDIR_HERA}/enkf${CDUMP}.${GYY}${GMM}${GDD}/${GHH}/atmos/${mem}/${CDUMP}.t${GHH}z.atmf0${FHR}.nc ${DATA}/heradata/${mem}/${CDUMP}.t${GHH}z.atmf0${FHR}.nc.${FHR}

[[ -e calc_analysis.nml ]] && ${NRM} calc_analysis.nml
cat > calc_analysis.nml <<EOF
&setup
datapath = './'
analysis_filename = 'heradata/${mem}/gdas.t${CHH}z.ratmanl.${CASE_ENKF_GDAS}.nc'
firstguess_filename = 'heradata/${mem}/gdas.t${GHH}z.atmf0${FHR}.nc'
increment_filename = 'heradata/${mem}/gdas.t${CHH}z.ratminc.nc'
fhr = ${FHR}
use_nemsio_anl = .false.
/
EOF

#ulimit -s unlimited
#HBO
${NLN} ${ANAEXEC}  ./calc_analysis.x
srun --export=ALL -n 127 calc_analysis.x  calc_analysis.nml

ERR2=$?

    if [[ ${ERR2} -eq 0 ]]; then
        echo "calc_analysis.x runs successfully and rename the analysis file."
        OUTDIR=${METDIR_NRT}/${CASE_ENKF}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/${mem}
        [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
        ${NMV} heradata/${mem}/gdas.t${CHH}z.ratmanl.${CASE_ENKF_GDAS}.nc.${FHR} heradata/${mem}/gdas.t${CHH}z.ratmanl.${CASE_ENKF_GDAS}.${mem}.nc
        #${NRM} wcossdata/${mem}/gdas.t${CHH}z.ratminc.nc.${FHR} wcossdata/${mem}/gdas.t${GHH}z.atmf0${FHR}.nc.${FHR}
        ${NMV} calc_analysis.nml ${OUTDIR}/
    else
        echo "calc_analysis.x failed at member ${mem} and exit"
        exit ${ERR2}
    fi
    mem0=$[$mem0+1]
done

### Step 3: Convert gdas ensemble analysis to CASE resolution (L64) and reload modules
echo "SETP-3: Convert gdas ensemble analysis to CASE resolution (L64) and reload modules"
. $HOMEgfs/ush/load_fv3gfs16_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

${NLN} ${CHGRESEXEC_GAU} ./   

RES=`echo ${CASE_ENKF} | cut -c2-4`
LONB=$((4*RES))
LATB=$((2*RES))

mem0=${ENSBEG}
while [[ ${mem0} -le ${ENSEND} ]]; do
    mem1=$(printf "%03d" ${mem0})
    mem="mem${mem1}"
    [[ -e fort.43 ]] && ${NRM} fort.43
    [[ -e ref_file.nc ]] && ${NRM} ref_file.nc
    #HBO
    #${NLN} ${ROTDIR}/enkf${CDUMP}.${GYY}${GMM}${GDD}/${GHH}/${mem}/gdas.t${GHH}z.atmf0${FHR}.nc.ges ./ref_file.nc
    ${NLN} /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/gdasAna/C96/ref_file/gdas.t18z.atmf006.nc.ges ./ref_file.nc
cat > fort.43 <<EOF
&chgres_setup
i_output=$LONB
j_output=$LATB
input_file="heradata/${mem}/gdas.t${CHH}z.ratmanl.${CASE_ENKF_GDAS}.${mem}.nc"
output_file="heradata/${mem}/gdas.t${CHH}z.ratmanl.${mem}.nc"
terrain_file="./ref_file.nc"
cld_amt=.F.
ref_file="./ref_file.nc"
/
EOF

#HBO
#ulimit -s unlimited
mpirun -n 1 ./chgres_recenter_ncio_v16.exe ./fort.43
ERR3=$?

if [[ ${ERR3} -eq 0 ]]; then
   echo "chgres_recenter_ncio.exe runs successful for ${mem} and move data."
   OUTDIR=${METDIR_NRT}/${CASE_ENKF}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/${mem}
   [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
   ${NMV} heradata/${mem}/gdas.t${CHH}z.ratmanl.${mem}.nc ${OUTDIR}/gdas.t${CHH}z.ratmanl.nc
   #if [[ ${mem0} -eq 1 || ${mem0} -eq 2 ]]; then
   #    ${NMV} heradata/${mem}/gdas.t${CHH}z.ratmanl.${CASE_ENKF_GDAS}.${mem}.nc ${OUTDIR}/gdas.t${CHH}z.ratmanl.${CASE_ENKF_GDAS}.${mem}.nc
   #    ${NCP} ${METDIR_HERA}/enkf${CDUMP}.${CYY}${CMM}${CDD}/${CHH}/atmos/${mem}/${CDUMP}.t${CHH}z.ratminc.nc ${OUTDIR}/${CDUMP}.t${CHH}z.ratminc.nc
   #    ${NCP} ${METDIR_HERA}/enkf${CDUMP}.${GYY}${GMM}${GDD}/${GHH}/atmos/${mem}/${CDUMP}.t${GHH}z.atmf0${FHR}.nc ${OUTDIR}/${CDUMP}.t${GHH}z.atmf0${FHR}.nc
   #fi
   ${NMV} fort.43 ${OUTDIR}/
else
   echo "chgres_recenter_ncio.exe run failed for ${mem} and exit."
   exit 1
fi
    mem0=$[$mem0+1]
done
#fi

if [ ${ENSFILE_MISSING} = "NO" ]; then
### Step 4: Convert 6h sfc forecast Gaussian files to CASE resolution 
echo "STEP-4: Convert 6h sfc forecast Gaussian files to CASE resolution"
export HOMEufs=${HOMEgfs}
export CDATE=${CDATE}
export APRUN='srun --export=ALL -n 120'
export CHGRESEXEC=${CHGRESEXEC:-"${HOMEgfs}/exec/chgres_cube"}
FIXOROG=${HOMEgfs}/fix/fix_fv3_gmted2010
export INPUT_TYPE=gaussian_netcdf
export CRES=`echo ${CASE_ENKF} | cut -c2-4`
export VCOORD_FILE=${HOMEgfs}/fix/fix_am/global_hyblev.l64.txt
export MOSAIC_FILE_INPUT_GRID=${FIXOROG}/${CASE_ENKF_GDAS}/${CASE_ENKF_GDAS}_mosaic.nc
#export OROG_DIR_INPUT_GRID=${FIXOROG}/${CASE_ENKF_GDAS}
#export OROG_FILES_INPUT_GRID=${CASE_ENKF_GDAS}_oro_data.tile1.nc'","'${CASE_ENKF_GDAS}_oro_data.tile2.nc'","'${CASE_ENKF_GDAS}_oro_data.tile3.nc'","'${CASE_ENKF_GDAS}_oro_data.tile4.nc'","'${CASE_ENKF_GDAS}_oro_data.tile5.nc'","'${CASE_ENKF_GDAS}_oro_data.tile6.nc

export MOSAIC_FILE_TARGET_GRID=${FIXOROG}/${CASE_ENKF}/${CASE_ENKF}_mosaic.nc
export OROG_FILES_TARGET_GRID=${CASE_ENKF}_oro_data.tile1.nc'","'${CASE_ENKF}_oro_data.tile2.nc'","'${CASE_ENKF}_oro_data.tile3.nc'","'${CASE_ENKF}_oro_data.tile4.nc'","'${CASE_ENKF}_oro_data.tile5.nc'","'${CASE_ENKF}_oro_data.tile6.nc

export CONVERT_ATM=".false."
export CONVERT_SFC=".true."
export CONVERT_NST=".true."

#export SFC_FILES_INPUT=${CM3YMD}.${CM3HH}0000.sfcanl_data.tile1.nc'","'${CM3YMD}.${CM3HH}0000.sfcanl_data.tile2.nc'","'${CM3YMD}.${CM3HH}0000.sfcanl_data.tile3.nc'","'${CM3YMD}.${CM3HH}0000.sfcanl_data.tile4.nc'","'${CM3YMD}.${CM3HH}0000.sfcanl_data.tile5.nc'","'${CM3YMD}.${CM3HH}0000.sfcanl_data.tile6.nc
export SFC_FILES_INPUT=${CDUMP}.t${GHH}z.sfcf006.nc

#for mem0 in ${ENSBEG}..${ENSEND}; do
mem0=${ENSBEG}
while [[ ${mem0} -le ${ENSEND} ]]; do
    mem1=$(printf "%03d" ${mem0})
    mem="mem${mem1}"
    #export COMIN=wcossdata/${mem}/
    #METDIR_HERA=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/
    export COMIN=${METDIR_HERA}/enkf${CDUMP}.${GYY}${GMM}${GDD}/${GHH}/atmos/${mem}

${HOMEgfs}/ush/chgres_cube.sh
ERR4=$?
if [[ ${ERR4} -eq 0 ]]; then
   echo "chgres_cube for 6h sfc fcst runs successful for ${mem} and move data."

   OUTDIR=${METDIR_NRT}/${CASE_ENKF}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/${mem}/RESTART_6hFcst
   [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
       ${NMV} fort.41 ${OUTDIR}/
   for tile in tile1 tile2 tile3 tile4 tile5 tile6; do
       ${NMV} out.sfc.${tile}.nc ${OUTDIR}/${CYMD}.${CHH}0000.sfc_data.${tile}.nc 
   done
else
   echo "chgres_cube run for 6h sfc fcst failed for ${mem} and exit."
   exit ${ERR4}
fi
mem0=$[$mem0+1]
done
else
    echo "WCOSS ensemble sfc file missing and skip steps 4 and 5 and copy from control if CASE_CNTL=CASE_ENKF"
    ERR4=0
fi

if [[ ${ERR1} -eq 0 && ${ERR2} -eq 0 && ${ERR3} -eq 0 && ${ERR4} -eq 0 ]]; then
   ${NRM} ${DATA}
fi
err=$?
echo $(date) EXITING $0 with return code $err >&2
exit $err

