#!/bin/bash
#SBATCH -A wrf-chem
#SBATCH -q debug
#SBATCH -t 30:00
#SBATCH -n 120
##SBATCH --nodes=4
#SBATCH -J calc_analysis
#SBATCH -o log1.out

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
PSLOT=${PSLOT:-"global-workflow-CCPP2-Chem-NRT-clean"}
ROTDIR=${ROTDIR:-""}
CDATE=${CDATE:-"2021062312"}
CASE_CNTL=${CASE_CNTL:-"C96"}
CASE_CNTL_GDAS=${CASE_CNTL_GDAS:-"C768"}
CASE_ENKF=${CASE_ENKF:-"C96"}
CASE_ENKF_GDAS=${CASE_ENKF_GDAS:-"C384"}
NMEM_AERO=${NMEM_AERO:-"20"}
FHR=${FHR:-"06"}
ENSFILE_MISSING=${ENSFILE_MISSING:-"NO"}
#HBO
#METDIR_WCOSS=${METDIR_WCOSS:-"/scratch1/BMC/chem-var/pagowski/junk_scp/wcoss/"}
METDIR_HERA=${METDIR_HERA:-"/scratch1/NCEPDEV/rstprod/com/gfs/prod/"}
#METDIR_WCOSS=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/MISC/test-prepgdasana_ens/data/
METDIR_NRT=${METDIR_NRT:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/gdasAna/"}
CDUMP=${CDUMP:-"gdas"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
CHGRESEXEC_GAU=${CHGRESEXEC_GAU:-"${HOMEgfs}/exec/chgres_recenter_ncio_v16.exe"}

NLN='/bin/ln -sf'
NRM='/bin/rm -rf'
NMV='/bin/mv'
NCP='/bin/cp'

STMP="/scratch2/BMC/gsd-fv3-dev/NCEPDEV/stmp3/$USER/"
export RUNDIR="$STMP/RUNDIRS/$PSLOT"
#HBO
export DATA="$RUNDIR/$CDATE/$CDUMP/prepensana.$$"

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


### Convert gdas ensemble analysis to CASE resolution (L64) and reload modules
echo "SETP1: Convert gdas analysis to CASE resolution (L64) and reload modules"
[[ ! -d ${DATA}/heradata ]] && mkdir -p  ${DATA}/heradata

${NLN} ${CHGRESEXEC_GAU} ./   
${NLN} ${METDIR_HERA}/${CDUMP}.${CYY}${CMM}${CDD}/${CHH}/atmos/${CDUMP}.t${CHH}z.atmanl.nc  ${DATA}/heradata/${CDUMP}.t${CHH}z.atmanl.nc
${NLN} ${METDIR_HERA}/${CDUMP}.${CYY}${CMM}${CDD}/${CHH}/atmos/${CDUMP}.t${CHH}z.sfcanl.nc  ${DATA}/heradata/${CDUMP}.t${CHH}z.sfcanl.nc

. $HOMEgfs/ush/load_fv3gfs16_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status

RES=`echo ${CASE_CNTL} | cut -c2-4`
LONB=$((4*RES))
LATB=$((2*RES))

[[ -e fort.43 ]] && ${NRM} fort.43
[[ -e ref_file.nc ]] && ${NRM} ref_file.nc
#HBO
#${NLN} ${ROTDIR}/${CDUMP}.${GYY}${GMM}${GDD}/${GHH}/gdas.t${GHH}z.atmf0${FHR}.nc.ges ./ref_file.nc
${NLN} /scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/gdasAna/C96/ref_file/gdas.t18z.atmf006.nc.ges ./ref_file.nc
cat > fort.43 <<EOF
&chgres_setup
i_output=$LONB
j_output=$LATB
input_file="heradata/${CDUMP}.t${CHH}z.atmanl.nc"
output_file="heradata/${CDUMP}.t${CHH}z.atmanl.${CASE_CNTL}.nc"
terrain_file="./ref_file.nc"
cld_amt=.F.
ref_file="./ref_file.nc"
/
EOF

#HBO
#ulimit -s unlimited
mpirun -n 1 ./chgres_recenter_ncio_v16.exe ./fort.43
ERR1=$?

if [[ ${ERR1} -eq 0 ]]; then
   echo "chgres_recenter_ncio.exe runs successful and move data."
   OUTDIR=${METDIR_NRT}/${CASE_CNTL}/${CDUMP}.${CYY}${CMM}${CDD}/${CHH}/
   [[ ! -d ${OUTDIR} ]] && mkdir -p ${OUTDIR}
   ${NMV} heradata/${CDUMP}.t${CHH}z.atmanl.${CASE_CNTL}.nc ${OUTDIR}/gdas.t${CHH}z.atmanl.nc
   ${NMV} fort.43 ${OUTDIR}/
else
   echo "chgres_recenter_ncio.exe run failed for and exit."
   exit ${ERR1}
fi

### Convert sfcanl RESTART files to CASE resolution 
echo "STEP2: Convert sfcanl RESTART files to CASE resolution"
export HOMEufs=${HOMEgfs}
export CDATE=${CDATE}
export APRUN='srun --export=ALL -n 120'
export CHGRESEXEC=${CHGRESEXEC:-"${HOMEgfs}/exec/chgres_cube"}
FIXOROG=${HOMEgfs}/fix/fix_fv3_gmted2010
export INPUT_TYPE=gaussian_netcdf
export CRES=`echo ${CASE_CNTL} | cut -c2-4`
export VCOORD_FILE=${HOMEgfs}/fix/fix_am/global_hyblev.l64.txt
export MOSAIC_FILE_INPUT_GRID=${FIXOROG}/${CASE_CNTL_GDAS}/${CASE_CNTL_GDAS}_mosaic.nc
#export OROG_DIR_INPUT_GRID=${FIXOROG}/${CASE_CNTL_GDAS}
#export OROG_FILES_INPUT_GRID=${CASE_CNTL_GDAS}_oro_data.tile1.nc'","'${CASE_CNTL_GDAS}_oro_data.tile2.nc'","'${CASE_CNTL_GDAS}_oro_data.tile3.nc'","'${CASE_CNTL_GDAS}_oro_data.tile4.nc'","'${CASE_CNTL_GDAS}_oro_data.tile5.nc'","'${CASE_CNTL_GDAS}_oro_data.tile6.nc

export MOSAIC_FILE_TARGET_GRID=${FIXOROG}/${CASE_CNTL}/${CASE_CNTL}_mosaic.nc
export OROG_FILES_TARGET_GRID=${CASE_CNTL}_oro_data.tile1.nc'","'${CASE_CNTL}_oro_data.tile2.nc'","'${CASE_CNTL}_oro_data.tile3.nc'","'${CASE_CNTL}_oro_data.tile4.nc'","'${CASE_CNTL}_oro_data.tile5.nc'","'${CASE_CNTL}_oro_data.tile6.nc

export CONVERT_ATM=".false."
export CONVERT_SFC=".true."
export CONVERT_NST=".true."

#export SFC_FILES_INPUT=${CYMD}.${CHH}0000.sfcanl_data.tile1.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile2.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile3.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile4.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile5.nc'","'${CYMD}.${CHH}0000.sfcanl_data.tile6.nc
export SFC_FILES_INPUT=${CDUMP}.t${CHH}z.sfcanl.nc

export COMIN=heradata/

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

   if [ ${ENSFILE_MISSING} = "YES" -a ${CASE_CNTL} = ${CASE_ENKF} ]; then
       echo "WCOSS ensemble file missing and copy control SFC files"
       mem0=1
       while [[ ${mem0} -le ${NMEM_AERO} ]]; do
	   mem1=$(printf "%03d" ${mem0})
	   mem="mem${mem1}"
	   if [ ${ENSFILE_m3SFCANL} = "YES" ]; then
               MEMOUTDIR=${METDIR_NRT}/${CASE_ENKF}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/${mem}/RESTART_m3SFCANL
	   else
               MEMOUTDIR=${METDIR_NRT}/${CASE_ENKF}/enkfgdas.${CYY}${CMM}${CDD}/${CHH}/${mem}/RESTART_6hFcst
	   fi
	   [[ ! -d ${MEMOUTDIR} ]] && mkdir -p ${MEMOUTDIR}
	   ${NCP} ${OUTDIR}/* ${MEMOUTDIR}/
           mem0=$[$mem0+1]
       done
      echo "MISSING=YES" > ${MEMOUTDIR}/../../EnsSFC_MISSING.check
   fi


else
   echo "chgres_cube run  failed for and exit."
   exit ${ERR2}
fi

if [[ ${ERR1} -eq 0 && ${ERR2} -eq 0 ]]; then
   ${NRM} ${DATA}
fi
err=$?
echo $(date) EXITING $0 with return code $err >&2
exit $err

