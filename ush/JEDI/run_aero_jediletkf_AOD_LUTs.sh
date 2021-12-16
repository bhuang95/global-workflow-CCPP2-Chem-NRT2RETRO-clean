#!/bin/ksh
set -x

JEDIDir=${HOMEjedi:-$HOMEgfs/sorc/jedi.fd/}
WorkDir=${DATA:-$pwd/analysis.$$}
RotDir=${ROTDIR:-/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/}
ObsDir=${COMIN_OBS:-$COMIN}
ComIn_Ges=${COMIN_GES:-$COMIN}
ComIn_Ges_Ens=${COMIN_GES_ENS:-$COMIN_GES}
validtime=${CDATE:-"2001010100"}
bumptime=${validtime}
prevtime=$($NDATE -$assim_freq $CDATE)
startwin=$($NDATE -3 $CDATE)
res1=${CASE:-"C384"} # no lower case
res=`echo "$res1" | tr '[:upper:]' '[:lower:]'`
resc=$(echo $res1 |cut -c2-5)
resx=$((resc+1))
resy=$((resc+1))
BumpDir=${JEDIDir}/fv3-jedi/test/Data/bump/${CASE}/
FieldDir=${JEDIDir}/fv3-jedi/test/Data/fieldsets/
FV3Dir=${JEDIDir}/fv3-jedi/test/Data/fv3files/
CRTMFix=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/Little_Endian/
jediexe=${JEDIDir}/bin/fv3jedi_letkf.x

cdump=${CDUMP:-"gdas"}
nmem=${NMEM_AERO:-"10"}

#HOMEgfs=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/GSDChem_cycling/global-workflow
#JEDIDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/fv3-bundle/build
#WorkDir=./anal
#FixDir=$HOMEgfs/fix/fix_jedi
#BumpDir=${FixDir}"/bump/"
#RotDir=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data/
#ObsDir=/scratch1/BMC/wrf-chem/pagowski/MAPP_2018/OBS/VIIRS/AOT/thinned_C96/2018041706/
#ComIn_Ges=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data//gdas.20180417/00
#ComIn_Ges_Ens=/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/aero_c96_jedi3densvar/dr-data//enkfgdas.20180417/00
#validtime=2018041706
#bumptime=${validtime}
#prevtime=2018041700
#startwin=2018041703
#res1=C96
#res=c96
#cdump=gdas
#nmem=20

# Define some aliases
ncp="/bin/cp -r"
nmv="/bin/mv -f"
nln="/bin/ln -sf"


# set date format
byy=$(echo $bumptime | cut -c1-4)
bmm=$(echo $bumptime | cut -c5-6)
bdd=$(echo $bumptime | cut -c7-8)
bhh=$(echo $bumptime | cut -c9-10)
locdatestr=${byy}-${bmm}-${bdd}T${bhh}:00:00Z

vyy=$(echo $validtime | cut -c1-4)
vmm=$(echo $validtime | cut -c5-6)
vdd=$(echo $validtime | cut -c7-8)
vhh=$(echo $validtime | cut -c9-10)
datestr=${vyy}-${vmm}-${vdd}T${vhh}:00:00Z

pyy=$(echo $prevtime | cut -c1-4)
pmm=$(echo $prevtime | cut -c5-6)
pdd=$(echo $prevtime | cut -c7-8)
phh=$(echo $prevtime | cut -c9-10)
prevtimestr=${pyy}-${pmm}-${pdd}T${phh}:00:00Z

syy=$(echo $startwin | cut -c1-4)
smm=$(echo $startwin | cut -c5-6)
sdd=$(echo $startwin | cut -c7-8)
shh=$(echo $startwin | cut -c9-10)
startwindow=${syy}-${smm}-${sdd}T${shh}:00:00Z

# Link fv3 nemelist files
workinput=${WorkDir}/input
mkdir -p ${workinput}

${nln} ${FV3Dir}/fmsmpp.nml 		${WorkDir}/fmsmpp.nml
${nln} ${FV3Dir}/input_gfs_${res}.nml 	${WorkDir}/input_gfs.nml
${nln} ${FV3Dir}/field_table 		${WorkDir}/field_table.input
${nln} ${FV3Dir}/inputpert_4dvar.nml	${WorkDir}/inputpert_4dvar.nml
${nln} ${FieldDir}/dynamics.yaml        ${WorkDir}/dynamics.yaml
${nln} ${FieldDir}/aerosols_gfs.yaml    ${WorkDir}/aerosols_gfs.yaml
${nln} ${FieldDir}/ufo.yaml             ${WorkDir}/ufo.yaml

${nln} ${FV3Dir}/akbk64.nc4             ${workinput}/akbk.nc

# Link crtm files (only for VIIRS and MODIS)
mkdir -p ${WorkDir}/crtm/
coeffs="AerosolCoeff.bin CloudCoeff.bin  v.viirs-m_npp.SpcCoeff.bin v.viirs-m_npp.TauCoeff.bin v.modis_terra.SpcCoeff.bin  v.modis_terra.TauCoeff.bin v.modis_aqua.SpcCoeff.bin v.modis_aqua.TauCoeff.bin"

for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}/${coeff} ${WorkDir}/crtm/${coeff}
done

coeffs=`ls ${CRTMFix}/NPOESS.* | awk -F "/" '{print $NF}'`
for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}/${coeff} ${WorkDir}/crtm/${coeff}
done

coeffs=`ls ${CRTMFix}/USGS.* | awk -F "/" '{print $NF}'`
for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}/${coeff} ${WorkDir}/crtm/${coeff}
done

coeffs=`ls ${CRTMFix}/FASTEM6.* | awk -F "/" '{print $NF}'`
for coeff in ${coeffs}; do
    ${nln} ${CRTMFix}/${coeff} ${WorkDir}/crtm/${coeff}
done

# Link NASA look-up tables
${nln} ${JEDIDir}/geos-aero/test/testinput/geosaod.rc ${WorkDir}/geosaod.rc
${nln} ${JEDIDir}/geos-aero/test/testinput/Chem_MieRegistry.rc ${WorkDir}/Chem_Registry.rc
${nln} ${JEDIDir}/geos-aero/test/Data ${WorkDir}/

# link observations
obsstr=${validtime}
if [ $AODTYPE = "VIIRS" ]; then
    obsfile=${ObsDir}/${obsstr}/VIIRS_AOD_npp.${obsstr}.nc
    obsfile1=${ObsDir}/${obsstr}/VIIRS_AOD_j01.${obsstr}.nc
    sensorid=v.viirs-m_npp
    sensorid1=v.viirs-m_npp
    obsin=aod_viirs_npp_obs_${obsstr}.nc4
    obsin1=aod_viirs_j01_obs_${obsstr}.nc4
    ${nln} ${obsfile} ${workinput}/${obsin}
    ${nln} ${obsfile1} ${workinput}/${obsin1}
elif [ $AODTYPE = "MODIS" ]; then
    obsfile=${ObsDir}/nnr_terra.${obsstr}.nc
    obsfile1=${ObsDir}/nnr_aqua.${obsstr}.nc
    sensorid=v.modis_terra
    sensorid1=v.modis_aqua
    obsin=aod_nnr_terra_obs_${obsstr}.nc4
    obsin1=aod_nnr_aqua_obs_${obsstr}.nc4
    ${nln} ${obsfile} ${workinput}/${obsin}
    ${nln} ${obsfile1} ${workinput}/${obsin1}
else
    echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
    exit
fi

# Link ensemble member backgrounds/analyses
nowfilestr=${vyy}${vmm}${vdd}.${vhh}0000
ensgesroot=${RotDir}/enkfgdas.${pyy}${pmm}${pdd}/${phh}/
workanal=${WorkDir}/analysis
mkdir -p ${workanal}

imem=0
while [ ${imem} -le ${nmem} ]; do
    memstr="mem"`printf %03d $imem`
    if [ ${imem} -eq 0 ]; then
       memstr1="ensmean"
    else
       memstr1=${memstr}
    fi
    mkdir -p ${workinput}/${memstr}
    mkdir -p ${workanal}/${memstr}
    rm -rf ${ensgesroot}/${memstr1}/RESTART/*.nc
    rm -rf ${ensgesroot}/${memstr1}/RESTART/*.nc.anl_jedi
    couplerges=${ensgesroot}/${memstr1}/RESTART/${nowfilestr}.coupler.res.ges
    couplergesout=${workinput}/${memstr}/coupler.res
    ${nln} ${couplerges} ${couplergesout}

    itile=1
    while [ ${itile} -le 6 ]; do
       tilestr=`printf %1i $itile`
    
       tilefile=fv_tracer.res.tile${tilestr}.nc
       tilefileges=${ensgesroot}/${memstr1}/RESTART/${nowfilestr}.${tilefile}.ges
       tilefilegesout=${workinput}/${memstr}/${tilefile}
       ${nln} ${tilefileges} ${tilefilegesout}

       tilefileanl=${ensgesroot}/${memstr1}/RESTART/${nowfilestr}.${tilefile}
       tilefileanlout=${workanal}/${memstr}/${nowfilestr}.letkf_aero.fv_tracer.res.tile${tilestr}.nc
       ${nln} ${tilefileanl} ${tilefileanlout}
    
       tilefile=fv_core.res.tile${tilestr}.nc
       tilefileges=${ensgesroot}/${memstr1}/RESTART/${nowfilestr}.${tilefile}.ges
       tilefilegesout=${workinput}/${memstr}/${tilefile}
       ${nln} ${tilefileges} ${tilefilegesout}

       itile=$((itile+1))
    done
    imem=$((imem+1))
done

# Define executable to run
${nln} ${jediexe} ${WorkDir}/fv3jedi_letkf.x 

# Generate yaml block for background ensembles 
rm -rf ${WorkDir}/yamlblock_mem.info
filetype="    - filetype: gfs"
filecore="      filename_core: fv_core.res.nc"
filetrcr="      filename_trcr: fv_tracer.res.nc"
filecplr="      filename_cplr: coupler.res"
filevars1="      state variables: &aerovars [T,DELP,sphum,
                                  sulf,bc1,bc2,oc1,oc2,
                                  dust1,dust2,dust3,dust4,dust5,
                                  seas1,seas2,seas3,seas4,seas5]"
filevars="      state variables: *aerovars"

imem=1
while [ ${imem} -le ${nmem} ]; do
   memstr="mem`printf %03d ${imem}`"
   filemem="      datapath: ./input/${memstr}/"
   echo "${filetype}" >> ${WorkDir}/yamlblock_mem.info
   if [ ${imem} -eq 1 ];then
      echo "${filevars1}" >> ${WorkDir}/yamlblock_mem.info
   else
      echo "${filevars}" >> ${WorkDir}/yamlblock_mem.info
   fi

   echo "${filemem}" >> ${WorkDir}/yamlblock_mem.info
   echo "${filecore}" >> ${WorkDir}/yamlblock_mem.info
   echo "${filetrcr}" >> ${WorkDir}/yamlblock_mem.info
   echo "${filecplr}" >> ${WorkDir}/yamlblock_mem.info
   imem=$((imem+1))
done

yamlblock_mem=`cat ${WorkDir}/yamlblock_mem.info`

# Generate the yaml block for AOD observations

if [ $AODTYPE = "VIIRS" ]; then
yamlblock_obs="- obs space:
    name: Aod
    distribution: InefficientDistribution
    #distribution: Halo
    obsdatain:
      obsfile: ./input/${obsin}
    simulated variables: [aerosol_optical_depth]
    channels: 4
  obs operator:
    name: AodLUTs
    Absorbers: [H2O,O3]
    obs options:
      Sensor_ID: ${sensorid}
      EndianType: little_endian
      CoefficientPath: ./crtm/
      AerosolOption: aerosols_gocart_merra_2
      RCFile: [geosaod.rc]
  obs error:
    covariance model: diagonal
  obs localization:
    localization method: Gaspari-Cohn
    #search method: kd_tree
    lengthscale: 2500e3
    #max_nobs: 1000"
#- obs space:
#    name: Aod
#    distribution: InefficientDistribution
#    obsdatain:
#      obsfile: ./input/${obsin1}
#    simulated variables: [aerosol_optical_depth]
#    channels: 4
#  obs operator:
#    name: AodLUTs
#    Absorbers: [H2O,O3]
#    obs options:
#      Sensor_ID: ${sensorid1}
#      EndianType: little_endian
#      CoefficientPath: ./crtm/
#      AerosolOption: aerosols_gocart_merra_2
#      RCFile: [geosaod.rc]
#  obs error:
#    covariance model: diagonal
#  obs localization:
#    localization method: Gaspari-Cohn
#    lengthscale: 2500e3
#    #max_nobs: 1000"

elif [ $AODTYPE = "MODIS" ]; then
yamlblock_obs="- obs space:
    name: Aod
    distribution: InefficientDistribution
    obsdatain:
      obsfile: ./input/${obsin}
    simulated variables: [aerosol_optical_depth]
    channels: 4
  obs operator:
    name: AodLUTs
    Absorbers: [H2O,O3]
    obs options:
      Sensor_ID: ${sensorid}
      EndianType: little_endian
      CoefficientPath: ./crtm/
      AerosolOption: aerosols_gocart_merra_2
      RCFile: [geosaod.rc]
  obs error:
    covariance model: diagonal
  obs localization:
    localization method: Gaspari-Cohn
    lengthscale: 2500e3
    #max_nobs: 1000
- obs space:
    name: Aod
    distribution: InefficientDistribution
    obsdatain:
      obsfile: ./input/${obsin1}
    simulated variables: [aerosol_optical_depth]
    channels: 4
  obs operator:
    name: AodLUTs
    Absorbers: [H2O,O3]
    obs options:
      Sensor_ID: ${sensorid1}
      EndianType: little_endian
      CoefficientPath: ./crtm/
      AerosolOption: aerosols_gocart_merra_2
      RCFile: [geosaod.rc]
  obs error:
    covariance model: diagonal
  obs localization:
    localization method: Gaspari-Cohn
    lengthscale: 2500e3
    #max_nobs: 1000"
else
    echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
    exit 1
fi

# Create yaml file
cat << EOF > ${WorkDir}/jediletkf_gfs_aero.yaml
geometry:
  nml_file_mpp: fmsmpp.nml
  trc_file: field_table.input
  akbk: ./input/akbk.nc
  layout: [${layout_eupd}]
  io_layout: [${io_layout_eupd}]
  npx: ${resx}
  npy: ${resy}
  npz: 64
  ntiles: 6
  fieldsets:
    - fieldset: ./dynamics.yaml
    - fieldset: ./aerosols_gfs.yaml
    - fieldset: ./ufo.yaml
    
window begin: &date '${startwindow}'
window length: PT6H

background:
  date: *date
  members:
${yamlblock_mem}

observations:
${yamlblock_obs}

prints:
  frequency: PT3H

driver: 
  do posterior observer: false
  save posterior ensemble: true
  save posterior mean: true

local ensemble DA:
  solver: LETKF
  inflation:
    rtps: 0.5
    rtpp: 0.6
    mult: 1.1

output:
  filetype: gfs
  datapath: ./analysis/mem%{member}%/
  filename_core: letkf_aero.fv_core.res.nc
  filename_trcr: letkf_aero.fv_tracer.res.nc
  filename_cplr: letkf_aero.coupler.res
  first: PT0H
  frequency: PT1H
  date: *date
EOF


exit 0
