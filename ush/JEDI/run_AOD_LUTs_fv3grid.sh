#!/bin/ksh -x
###############################################################

HOMEgfs=${HOMEgfs:-$NWPROD}
HOMEjedi=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
DATA=${DATA:-${DATAROOT}/hofx_aod.$$}
AODTYPE=${AODTYPE:-"VIIRS"}
NDATE=${NDATE:-"/scratch2/NCEPDEV/nwprod/NCEPLIBS/utils/prod_util.v1.1.0/exec/ndate"}
trcr_suffix=${trcr_suffix:-""}
gdatadir=${gdatadir:-""}
AODEXEC=${AODEXEC:-${HOMEgfs}/exec/gocart_aod_fv3_mpi_LUTs.x}

# Base variables
CDATE=${CDATE:-"2001010100"}
CDUMP=${CDUMP:-"gdas"}
GDUMP=${GDUMP:-"gdas"}
GDATE=$($NDATE -$assim_freq $CDATE)

# Utilities
NCP=${NCP:-"/bin/cp"}
NMV=${NMV:-"/bin/mv"}
NLN=${NLN:-"/bin/ln -sf"}


### Determine cycle and bckg date
cyy=$(echo $CDATE | cut -c1-4)
cmm=$(echo $CDATE | cut -c5-6)
cdd=$(echo $CDATE | cut -c7-8)
chh=$(echo $CDATE | cut -c9-10)
cprefix="${cyy}${cmm}${cdd}.${chh}0000"

gyy=$(echo $GDATE | cut -c1-4)
gmm=$(echo $GDATE | cut -c5-6)
gdd=$(echo $GDATE | cut -c7-8)
ghh=$(echo $GDATE | cut -c9-10)
gprefix="${gyy}${gmm}${gdd}.${ghh}0000"

# other variables

cd $DATA

# Link executables to working director
${NLN} $AODEXEC ./gocart_aod_fv3_mpi_LUTs.x
${NLN} ${HOMEjedi}/geos-aero/test/testinput/geosaod.rc ./geosaod.rc
${NLN} ${HOMEjedi}/geos-aero/test/testinput/Chem_MieRegistry.rc ./Chem_MieRegistry.rc
${NLN} ${HOMEjedi}/geos-aero/test/Data ./

# Determine sensor ID
if [ $AODTYPE = "VIIRS" ]; then
    #sensorIDs="v.viirs-m_npp v.viirs-m_j1"
    sensorIDs="v.viirs-m_npp"
elif [ $AODTYPE = "MODIS-NRT" ]; then
    sensorIDs="v.modis_terra v.modis_aqua"
else
    echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
    exit 1
fi

# Loop all through allfields and sensorIDs
for isensorID in ${sensorIDs}; do
    
    fakbk=${cprefix}.fv_core.res.nc.ges
    for itile in $(seq 1 6); do
        fcore=${cprefix}.fv_core.res.tile${itile}.nc.ges
        ftracer=${cprefix}.fv_tracer.res.tile${itile}.nc${trcr_suffix}
	faod=${cprefix}.fv_aod_LUTs_${isensorID}.res.tile${itile}.nc${trcr_suffix}

cat << EOF > ${DATA}/gocart_aod_fv3_mpi.nl 	
&record_input
 input_dir = "${gdatadir}"
 fname_akbk = "${fakbk}"
 fname_core = "${fcore}"
 fname_tracer = "${ftracer}"
 output_dir = "${gdatadir}"
 fname_aod = "${faod}"
/
&record_model
 Model = "AodLUTs"
/
&record_conf_crtm
 AerosolOption = "aerosols_gocart_default"
 Absorbers = "H2O","O3"
 Sensor_ID = "${isensorID}"
 EndianType = "Big_Endian"
 CoefficientPath = ${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/
 Channels = 4
/
&record_conf_luts
 AerosolOption = "aerosols_gocart_merra_2"
 Wavelengths = 550.
 RCFile = "geosaod.rc"
/
EOF
        cat ${DATA}/gocart_aod_fv3_mpi.nl  
	srun --export=all -n 2  ./gocart_aod_fv3_mpi_LUTs.x
	err=$?
	if [ $err -ne 0 ]; then
  	    echo "gocart_aod_fv3_mpi_LUTs failed an exit!!!"
   	    exit 1
	else
   	    /bin/rm -rf ${DATA}/gocart_aod_fv3_mpi.nl
	fi
        done # end for itile
done # end for isensorID
### 
###############################################################
# Postprocessing
#cd $pwd
#[[ $mkdata = "YES" ]] && rm -rf $DATA

set +x
if [ $VERBOSE = "YES" ]; then
   echo $(date) EXITING $0 with return code $err >&2
fi
exit $err
