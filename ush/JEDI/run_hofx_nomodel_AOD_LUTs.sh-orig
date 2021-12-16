#!/bin/ksh
set -x

JEDIDir=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
DATA=${DATA:-$pwd/hofx_aod.$$}
ObsDir=${COMIN_OBS:-./}
CDATE=${CDATE:-"2001010100"}
stwindow=${BDATE:-""}
trcr_suffix=${trcr_suffix:-""}
gdatadir=${gdatadir:-""}
hofxdir=${hofxdir:-""}

caseres=${CASE:-C96}
resc=$(echo $caseres |cut -c2-5)
resx=$((resc+1))
resy=$((resc+1))
FieldDir=${JEDIDir}/fv3-jedi/test/Data/fieldsets/
FV3Dir=${JEDIDir}/fv3-jedi/test/Data/fv3files/
JEDIcrtm=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/Little_Endian/
jediexe=${JEDIDir}/bin/fv3jedi_hofx_nomodel.x

# Define some aliases
nrm="/bin/rm -rf"
ncp="/bin/cp -r"
nln="/bin/ln -sf"
nmv="/bin/mv"

# set date format
cyy=$(echo $CDATE | cut -c1-4)
cmm=$(echo $CDATE | cut -c5-6)
cdd=$(echo $CDATE | cut -c7-8)
chh=$(echo $CDATE | cut -c9-10)
cprefix="${cyy}${cmm}${cdd}.${chh}0000"

syy=$(echo $stwindow | cut -c1-4)
smm=$(echo $stwindow | cut -c5-6)
sdd=$(echo $stwindow | cut -c7-8)
shh=$(echo $stwindow | cut -c9-10)
stwindowstr=${syy}-${smm}-${sdd}T${shh}:00:00Z


cd $DATA

# Link fv3 nemelist files
${nln} ${FV3Dir}/fmsmpp.nml          ./fmsmpp.nml
${nln} ${FV3Dir}/field_table         ./field_table.input
${nln} ${FieldDir}/dynamics.yaml     ./dynamics.yaml
${nln} ${FieldDir}/aerosols_gfs.yaml ./aerosols_gfs.yaml
${nln} ${FieldDir}/ufo.yaml          ./ufo.yaml

${nln} ${FV3Dir}/akbk64.nc4          ./akbk.nc

# Link NASA look-up tables
${nln} ${JEDIDir}/geos-aero/test/testinput/geosaod.rc ./geosaod.rc
${nln} ${JEDIDir}/geos-aero/test/testinput/Chem_MieRegistry.rc ./Chem_Registry.rc
${nln} ${JEDIDir}/geos-aero/test/Data ./

# Link observation files
obsstr=${CDATE}
if [ $AODTYPE = "VIIRS" ]; then
    obsfile=${ObsDir}/${obsstr}/VIIRS_AOD_npp.${obsstr}.nc
    sensorid=v.viirs-m_npp
    obsin=aod_viirs_npp_obs_${obsstr}.nc4
    obsout=aod_viirs_npp_hofx_3dvar_LUTs_${obsstr}.nc4
    obsoutproc=aod_viirs_npp_hofx_3dvar_LUTs_${obsstr}
    ${nln} ${obsfile} ${obsin}

    obsfile1=${ObsDir}/${obsstr}/VIIRS_AOD_j01.${obsstr}.nc
    sensorid1=v.viirs-m_npp
    obsin1=aod_viirs_j01_obs_${obsstr}.nc4
    obsout1=aod_viirs_j01_hofx_3dvar_LUTs_${obsstr}.nc4
    obsoutproc1=aod_viirs_j01_hofx_3dvar_LUTs_${obsstr}
    ${nln} ${obsfile1} ${obsin1}
elif [ $AODTYPE = "MODIS-NRT" ]; then
    obsfile=${ObsDir}/${obsstr}/MODIS-NRT_AOD_MOD04_L2.${obsstr}.nc
    sensorid=v.modis_terra
    obsin=aod_nrt_terra_obs_${obsstr}.nc4
    obsout=aod_nrt_terra_hofx_3dvar_LUTs_${obsstr}.nc4
    obsoutproc=aod_nrt_terra_hofx_3dvar_LUTs_${obsstr}
    ${nln} ${obsfile} ${obsin}

    obsfile1=${ObsDir}/${obsstr}/MODIS-NRT_AOD_MYD04_L2.${obsstr}.nc
    sensorid1=v.modis_aqua
    obsin1=aod_nrt_aqua_obs_${obsstr}.nc4
    obsout1=aod_nrt_aqua_hofx_3dvar_LUTs_${obsstr}.nc4
    obsoutproc1=aod_nrt_aqua_hofx_3dvar_LUTs_${obsstr}
    ${nln} ${obsfile1} ${obsin1}
else
    echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
    exit 1
fi

# link cntl/ens bckg/anal fields to ./input
cplrin=${gdatadir}/${cprefix}.coupler.res.ges
cplrout=./coupler.res
${nln} ${cplrin} ${cplrout}

itile=1
while [ ${itile} -le 6 ]; do
    tilestr=`printf %1i $itile`

    corein=${gdatadir}/${cprefix}.fv_core.res.tile${tilestr}.nc.ges
    coreout=./fv_core.res.tile${tilestr}.nc
    ${nln} ${corein} ${coreout}
    
    trcrin=${gdatadir}/${cprefix}.fv_tracer.res.tile${tilestr}.nc${trcr_suffix}
    trcrout=./fv_tracer.res.tile${tilestr}.nc
    ${nln} ${trcrin} ${trcrout}

    itile=$((itile+1))
done

# Link executable
${nln} ${jediexe} ./fv3jedi_hofx_nomodel.x

# Generate the yaml block for AOD observations
if [ $AODTYPE = "VIIRS" ]; then
yamlblock_obs="- obs space:
    name: Aod
    obsdatain:
      obsfile: ${obsin}
    obsdataout:
      obsfile: ${obsout}
    simulated variables: [aerosol_optical_depth]
    channels: 4
  obs operator:
    name: AodLUTs
    Absorbers: [H2O,O3]
    obs options:
      Sensor_ID: ${sensorid}
      EndianType: little_endian
      CoefficientPath: ${JEDIcrtm}
      AerosolOption: aerosols_gocart_merra_2
      RCFile: [geosaod.rc]
  obs error:
    covariance model: diagonal
- obs space:
    name: Aod
    obsdatain:
      obsfile: ${obsin1}
    obsdataout:
      obsfile: ${obsout1}
    simulated variables: [aerosol_optical_depth]
    channels: 4
  obs operator:
    name: AodLUTs
    Absorbers: [H2O,O3]
    obs options:
      Sensor_ID: ${sensorid1}
      EndianType: little_endian
      CoefficientPath: ${JEDIcrtm}
      AerosolOption: aerosols_gocart_merra_2
      RCFile: [geosaod.rc]
  obs error:
    covariance model: diagonal"
elif [ $AODTYPE = "MODIS-NRT" ]; then
yamlblock_obs="- obs space:
    name: Aod
    obsdatain:
      obsfile: ${obsin}
    obsdataout:
      obsfile: ${obsout}
    simulated variables: [aerosol_optical_depth]
    channels: 4
  obs operator:
    name: AodLUTs
    Absorbers: [H2O,O3]
    obs options:
      Sensor_ID: ${sensorid}
      EndianType: little_endian
      CoefficientPath: ${JEDIcrtm}
      AerosolOption: aerosols_gocart_merra_2
      RCFile: [geosaod.rc]
  obs error:
    covariance model: diagonal
- obs space:
    name: Aod
    obsdatain:
      obsfile: ${obsin1}
    obsdataout:
      obsfile: ${obsout1}
    simulated variables: [aerosol_optical_depth]
    channels: 4
  obs operator:
    name: AodLUTs
    Absorbers: [H2O,O3]
    obs options:
      Sensor_ID: ${sensorid1}
      EndianType: little_endian
      CoefficientPath: ${JEDIcrtm}
      AerosolOption: aerosols_gocart_merra_2
      RCFile: [geosaod.rc]
  obs error:
    covariance model: diagonal"
else
    echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
    exit 1
fi

# Create the yaml file for hofx_nomodel 
rm -rf ${DATA}/hofx_nomodel_AOD_LUTs.yaml
cat << EOF > ${DATA}/hofx_nomodel_AOD_LUTs.yaml
window begin: '${stwindowstr}'
window length: PT6H
forecast length: PT6H
geometry:
  nml_file_mpp: ./fmsmpp.nml
  trc_file: ./field_table.input
  akbk: akbk.nc
  layout: [${layout_hofx}]
  io_layout: [${io_layout_hofx}]
  npx: ${resx}
  npy: ${resy}
  npz: 64
  ntiles: 6
  fieldsets:
    - fieldset: ./dynamics.yaml
    - fieldset: ./aerosols_gfs.yaml
    - fieldset: ./ufo.yaml
state:
  filetype: gfs
  datapath: ./
  filename_core: fv_core.res.nc
  filename_trcr: fv_tracer.res.nc
  filename_cplr: coupler.res
  state variables: [T,DELP,sphum,
                    sulf,bc1,bc2,oc1,oc2,
                    dust1,dust2,dust3,dust4,dust5,
                    seas1,seas2,seas3,seas4,seas5]
observations:
${yamlblock_obs}
prints:
  frequency: PT3H
EOF

srun --export=all -n ${ncore_hofx} ./fv3jedi_hofx_nomodel.x "./hofx_nomodel_AOD_LUTs.yaml" "./hofx_nomodel_AOD_LUTs.run"
err=$?

nprocs=$((ncore_hofx-1))
if [ $err -eq 0 ]; then
    if [ $AODTYPE = "VIIRS" ]; then
        iproc=0

        while [ ${iproc} -le ${nprocs} ]; do

	   if [ ${iproc} -lt 10 ]; then
	       iprocstr=000${iproc}
	   elif [ ${iproc} -lt 100 ]; then
	       iprocstr=00${iproc}
           elif [ ${iproc} -lt 1000 ]; then
	       iprocstr=0${iproc}
	   else
	       echo "Too many cores for hofx calculation (less than 1000) and exit! "
	       exit 1
	   fi

           ${nmv} ./${obsoutproc}_${iprocstr}.nc4  ${hofxdir}/${obsoutproc}_${iprocstr}.nc4${trcr_suffix}     		  
           ${nmv} ./${obsoutproc1}_${iprocstr}.nc4  ${hofxdir}/${obsoutproc1}_${iprocstr}.nc4${trcr_suffix}     		  

	   ((iproc=iproc+1))
	done
    elif [ $AODTYPE = "MODIS-NRT" ]; then

        iproc=0
        while [ ${iproc} -le ${nprocs} ]; do
	   if [ ${iproc} -lt 10 ]; then
	       iprocstr=000${iproc}
	   elif [ ${iproc} -lt 100 ]; then
	       iprocstr=00${iproc}
           elif [ ${iproc} -lt 1000 ]; then
	       iprocstr=0${iproc}
	   else
	       echo "Too many cores for hofx calculation (less than 1000) and exit! "
	       exit 1
	   fi

           ${nmv} ./${obsoutproc}_${iprocstr}.nc4  ${hofxdir}/${obsoutproc}_${iprocstr}.nc4${trcr_suffix}     		  
           ${nmv} ./${obsoutproc1}_${iprocstr}.nc4  ${hofxdir}/${obsoutproc1}_${iprocstr}.nc4${trcr_suffix}     		  

	   ((iproc=iproc+1))
	done
    fi
fi

exit $err
