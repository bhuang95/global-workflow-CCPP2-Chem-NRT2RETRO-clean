#!/bin/ksh -x
###############################################################
# Source FV3GFS workflow modules
. $HOMEgfs/ush/load_fv3gfs_modules.sh
status=$?
[[ $status -ne 0 ]] && exit $status


export CASE_CNTL=${CASE_CNTL:-"C96"}
export CASE_ENKF=${CASE_ENKF:-"C96"}
###############################################################
# Source relevant configs
configs="base anal"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done


# Source machine runtime environment
. $BASE_ENV/${machine}.env anal 
status=$?
[[ $status -ne 0 ]] && exit $status

### Config ensemble hxaod calculation
export ENSBEG=1
export ENSEND=${NMEM_AERO}
###############################################################
#  Set environment.
export VERBOSE=${VERBOSE:-"NO"}
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXECUTING $0 $* >&2
   set -x
fi

#  Directories.
pwd=$(pwd)
export NWPROD=${NWPROD:-$pwd}
export HOMEgfs=${HOMEgfs:-$NWPROD}
export JEDIUSH=${JEDIUSH:-$HOMEgfs/ush/JEDI/}
export DATA=${DATA:-${DATAROOT}/enkfrecenter.$$}
export RECENTEREXEC=${RECENTEREXEC:-$HOMEgfs/exec/recenter_aeros_mpi.x}

# Base variables
CDATE=${CDATE:-"2001010100"}
CDATEm6=$($NDATE -$assim_freq $CDATE)
CDUMP=${CDUMP:-"gdas"}
GDUMP=${GDUMP:-"gdas"}

CYY=$(echo $CDATE | cut -c1-4)
CMM=$(echo $CDATE | cut -c5-6)
CDD=$(echo $CDATE | cut -c7-8)
CHH=$(echo $CDATE | cut -c9-10)

CYYm6=$(echo $CDATEm6 | cut -c1-4)
CMMm6=$(echo $CDATEm6 | cut -c5-6)
CDDm6=$(echo $CDATEm6 | cut -c7-8)
CHHm6=$(echo $CDATEm6 | cut -c9-10)

cntldir=${ROTDIR}/gdas.${CYYm6}${CMMm6}${CDDm6}/${CHHm6}/
ensmdir=${ROTDIR}/enkfgdas.${CYYm6}${CMMm6}${CDDm6}/${CHHm6}/
tracer_mem_prefix=${CYY}${CMM}${CDD}.${CHH}0000.fv_tracer.res
if  [ $CASE_ENKF = $CASE_CNTL ]; then
    tracer_cntl_prefix=${CYY}${CMM}${CDD}.${CHH}0000.fv_tracer.res
else
    tracer_cntl_prefix=${CYY}${CMM}${CDD}.${CHH}0000.${CASE_ENKF}.fv_tracer.res
fi

# Utilities
export NCP=${NCP:-"/bin/cp"}
export NMV=${NMV:-"/bin/mv"}
export NLN=${NLN:-"/bin/ln -sf"}
export ERRSCRIPT=${ERRSCRIPT:-'eval [[ $err = 0 ]]'}

# other variables
ntiles=${ntiles:-6}

export DATA=${DATA}

mkdir -p $DATA && cd $DATA/

###############################################################
# need to loop through ensemble members if necessary
if [ $ENKF_RECENTER == "TRUE" ]; then
if [ $NMEM_AERO -gt 0 ]; then
  for mem0 in {${ENSBEG}..${ENSEND}}; do
      memstr=mem`printf %03d $mem0`  
      memdir=${ROTDIR}/enkfgdas.${CYYm6}${CMMm6}${CDDm6}/${CHHm6}/${memstr}/RESTART
    # need to generate files for each tile 1-6
    for n in $(seq 1 6); do
        export itile=$n
	mem_tracer=${memdir}/${tracer_mem_prefix}.tile${itile}.nc
	mem_tracer1=${memdir}/${tracer_mem_prefix}.tile${itile}.nc_beforeRecenter
	$NCP ${mem_tracer} ${mem_tracer1}
    done
  done
        
cat << EOF > recenter_aeros_mpi.nl
&recenter_aeros_mpi_nml
 nens = ${NMEM_AERO}
 dircntl = "${cntldir}"
 dirmem = "${ensmdir}"
 filecntl = "${tracer_cntl_prefix}.tile?.nc"
 filemem = "${tracer_mem_prefix}.tile?.nc"
 varnames =  "sulf","bc1","bc2","oc1","oc2","dust1","dust2","dust3","dust4","dust5","seas1","seas2","seas3","seas4","seas5"
/ 
EOF

. ${HOMEjedi}/jedi_module_base.hera
#module load nco ncview ncl
module list
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOMEjedi}/lib/"

	mpirun -np ${NMEM_AERO} ${RECENTEREXEC}

	err=$?

	if  [ $err -ne 0 ]; then
    	    echo "RecenterAeros run failed and exit the program!!!"
    	    exit $err
	else
    	    /bin/rm -r recenter_aerosi_mpi.nl
	fi
fi
fi

###############################################################
# Postprocessing
cd $pwd
mkdata="YES"
[[ $mkdata = "YES" ]] && rm -rf $DATA

set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err
