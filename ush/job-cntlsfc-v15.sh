#!/bin/bash
#SBATCH -A wrf-chem
#SBATCH -q debug
#SBATCH -t 30:00
#SBATCH -n 120
##SBATCH --nodes=4
#SBATCH -J calc_analysis
#SBATCH -o log1.out

###############################################################
## This script is based on the cycled DA workflow run. To make
## less changes in this script, copy UFS_UTIL/exec/chgres_cube to 
## ${HOMEgfs}/exec and UFS_UTIL/ush/chgres_cube.sh to ${HOMEgfs}/ush. 
###############################################################
set -x
# Directory of fix files on Line 
HOMEgfs=/home/Bo.Huang/JEDI-2020/GSDChem_cycling/global-workflow-CCPP2-Chem-NRT-clean
CDATE=2019072000
CASE_CNTL=C96
CASE_CNTL_GDAS=C768
#Directory of Input SFC NEMSIO DATA
METDIR_HERA=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/coldstartIC/metAna-V15/gdas-2019072006-nemsio
#Directory of OUTPUT SFC 6-TILE NC DATA
METDIR_NRT=`pwd`
CDUMP=gdas
NDATE=/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate
export DATA=`pwd`/tmpdir

NLN='/bin/ln -sf'
NRM='/bin/rm -rf'
NMV='/bin/mv'
NCP='/bin/cp'

[[ ! -d $DATA ]] && mkdir -p $DATA
cd $DATA || exit 10

CYY=`echo "${CDATE}" | cut -c1-4`
CMM=`echo "${CDATE}" | cut -c5-6`
CDD=`echo "${CDATE}" | cut -c7-8`
CHH=`echo "${CDATE}" | cut -c9-10`
CYMD=${CYY}${CMM}${CDD}

. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
### Convert sfcanl RESTART files to CASE resolution 

export HOMEufs=${HOMEgfs}
export CDATE=${CDATE}
export APRUN='srun --export=ALL -n 120'
export CHGRESEXEC=${CHGRESEXEC:-"${HOMEgfs}/exec/chgres_cube"}
FIXOROG=${HOMEgfs}/fix/fix_fv3_gmted2010
export INPUT_TYPE=gaussian_nemsio
export CRES=`echo ${CASE_CNTL} | cut -c2-4`
export VCOORD_FILE=${HOMEgfs}/fix/fix_am/global_hyblev.l64.txt
export MOSAIC_FILE_INPUT_GRID=${FIXOROG}/${CASE_CNTL_GDAS}/${CASE_CNTL_GDAS}_mosaic.nc
export MOSAIC_FILE_TARGET_GRID=${FIXOROG}/${CASE_CNTL}/${CASE_CNTL}_mosaic.nc
export OROG_FILES_TARGET_GRID=${CASE_CNTL}_oro_data.tile1.nc'","'${CASE_CNTL}_oro_data.tile2.nc'","'${CASE_CNTL}_oro_data.tile3.nc'","'${CASE_CNTL}_oro_data.tile4.nc'","'${CASE_CNTL}_oro_data.tile5.nc'","'${CASE_CNTL}_oro_data.tile6.nc

export CONVERT_ATM=".false."
export CONVERT_SFC=".true."
export CONVERT_NST=".true."

#export SFC_FILES_INPUT=${CYMD}.${CHH}0000.sfcanl_data.tile1.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile2.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile3.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile4.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile5.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile6.nc
export SFC_FILES_INPUT=${CDUMP}.t${CHH}z.sfcanl.nemsio

export COMIN=./

${NLN} ${METDIR_HERA}/${CDUMP}.${CYY}${CMM}${CDD}/${CHH}/${CDUMP}.t${CHH}z.sfcanl.nemsio  ${DATA}/${CDUMP}.t${CHH}z.sfcanl.nemsio

${HOMEgfs}/ush/chgres_cube.sh
ERR2=$?
if [[ ${ERR2} -eq 0 ]]; then
   echo "chgres_cube runs successful and move data."

   OUTDIR=${METDIR_NRT}/${CASE_CNTL}/gdas.${CYY}${CMM}${CDD}/${CHH}/RESTART
   [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
       ${NMV} fort.41 ${OUTDIR}/
   for tile in tile1 tile2 tile3 tile4 tile5 tile6; do
       ${NMV} out.sfc.${tile}.nc ${OUTDIR}/${CYMD}.${CHH}0000.sfc_data.${tile}.nc 
   done
   ${NRM} ${DATA}
else
   echo "chgres_cube run  failed for and exit."
   exit ${ERR2}
fi

err=$?
echo $(date) EXITING $0 with return code $err >&2
exit $err
