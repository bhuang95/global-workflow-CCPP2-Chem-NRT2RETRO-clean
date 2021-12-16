#!/bin/ksh -x

###############################################################
## Abstract:
## Calculate increment of Met. fields for FV3-CHEM
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
configs="base calcinc"
for config in $configs; do
    . $EXPDIR/config.${config}
    status=$?
    [[ $status -ne 0 ]] && exit $status
done

# Source machine runtime environment
. $BASE_ENV/${machine}.env calcinc
status=$?

[[ $status -ne 0 ]] && exit $status

ulimit -s unlimited
###############################################################
CASE=${CASE_CNTL:-"C96"}
ICSDIR=${ICSDIR:-"/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/NRTdata/gdasAna/"}
CALCINCEXEC=${CALCINCEXEC:-$HOMEgfs/exec/calc_increment_ens.x}
export CALCINCNCEXEC=${CALCINCNCEXEC:-$HOMEgfs/exec/calc_increment_ens_ncio.x}
NTHREADS_CALCINC=${NTHREADS_CALCINC:-1}
ncmd=${ncmd:-1}
imp_physics=${imp_physics:-99}
INCREMENTS_TO_ZERO=${INCREMENTS_TO_ZERO:-"'NONE'"}
DO_CALC_INCREMENT=${DO_CALC_INCREMENT:-"YES"}
export ERRSCRIPT=${ERRSCRIPT:-'eval [[ $err = 0 ]]'}

TMPDAY=`$NDATE -$assim_freq $PDY$cyc`
HISDAY=`echo $TMPDAY | cut -c1-8`
HIScyc=`echo $TMPDAY | cut -c9-10`
export cycle="t${cyc}z"

fhr=${assim_freq}
typeset -Z3 fhr

if [ $DO_CALC_INCREMENT = "YES" ]; then

  mkdir -p $DATA
  cd $DATA
  mkdir -p calcinc.$$
  cd calcinc.$$

  if [ $SUFFIX = ".nc" ]; then
    $NCP $CALCINCNCEXEC ./calc_inc.x
  else
    $NCP $CALCINCEXEC ./calc_inc.x
  fi

  # deterministic run first

  export OMP_NUM_THREADS=$NTHREADS_CALCINC
  mkdir -p $ROTDIR/$CDUMP.$PDY/$cyc/$mem/
  $NLN $ROTDIR/$CDUMP.$HISDAY/${HIScyc}/${CDUMP}.t${HIScyc}z.atmf${fhr}$SUFFIX.ges atmges_mem001
  $NLN $ICSDIR/${CASE}/$CDUMP.$PDY/$cyc/$mem/$CDUMP.$cycle.atmanl$SUFFIX atmanl_mem001
  $NLN $ROTDIR/$CDUMP.$PDY/$cyc/$mem/$CDUMP.$cycle.atminc.nc atminc_mem001
  rm calc_increment.nml
  cat > calc_increment.nml << EOF
&setup
  datapath = './'
  analysis_filename = 'atmanl'
  firstguess_filename = 'atmges'
  increment_filename = 'atminc'
  debug = .false.
  nens = $ncmd
  imp_physics = $imp_physics
/
&zeroinc
  incvars_to_zero = $INCREMENTS_TO_ZERO
/
EOF
  cat calc_increment.nml

  APRUN=$(eval echo $APRUN_CALCINC)
  $APRUN ./calc_inc.x
  ERR=$?
  if [[ $ERR != 0 ]]; then
      exit ${ERR}
  fi
  #export ERR=$rc
  #export err=$ERR
  #$ERRSCRIPT || exit 3
  unlink atmges_mem001
  unlink atmanl_mem001
  unlink atminc_mem001
fi

#set +x 
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi

rm -rf ${DATA}/calcinc.$$
exit ${ERR}
###############################################################

###############################################################
# Exit cleanly
