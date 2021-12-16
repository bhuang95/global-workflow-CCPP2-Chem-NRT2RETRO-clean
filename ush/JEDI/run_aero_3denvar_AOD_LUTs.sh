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
bumplayout=`echo ${layout_anal} | sed 's/,/-/g'`
BumpDir=${BumpDir:-${JEDIDir}/fv3-jedi/test/Data/bump/${CASE}/layout-${bumplayout}-logp-1.5/}
FieldDir=${JEDIDir}/fv3-jedi/test/Data/fieldsets/
FV3Dir=${JEDIDir}/fv3-jedi/test/Data/fv3files/
CRTMFix=${HOMEgfs}/fix/jedi_crtm_fix_20200413/CRTM_fix/Little_Endian/
jediexe=${JEDIDir}/bin/fv3jedi_var.x

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
${nln} ${FV3Dir}/inputpert_4dvar.nml 	${WorkDir}/inputpert_4dvar.nml
${nln} ${FieldDir}/dynamics.yaml     	${WorkDir}/dynamics.yaml
${nln} ${FieldDir}/aerosols_gfs.yaml 	${WorkDir}/aerosols_gfs.yaml
${nln} ${FieldDir}/ufo.yaml          	${WorkDir}/ufo.yaml

${nln} ${FV3Dir}/akbk64.nc4 		${workinput}/akbk.nc

# Link bump directory
mkdir -p ${WorkDir}/bump
${nln} ${BumpDir}/fv3jedi_bumpparameters_nicas_gfs*  ${WorkDir}/bump/ 

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

# Link observations (only for VIIRS or MODIS)
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
    #obsout=aod_viirs_hofx_3dvar_LUTs_${obsstr}.nc4
elif [ $AODTYPE = "MODIS" ]; then
    obsfile=${ObsDir}/${obsstr}/nnr_terra.${obsstr}.nc
    obsfile1=${ObsDir}/${obsstr}/nnr_aqua.${obsstr}.nc
    sensorid=v.modis_terra
    sensorid1=v.modis_aqua
    obsin=aod_nnr_terra_obs_${obsstr}.nc4
    obsin1=aod_nnr_aqua_obs_${obsstr}.nc4
    ${nln} ${obsfile} ${workinput}/${obsin}
    ${nln} ${obsfile1} ${workinput}/${obsin1}
    #obsout=aod_nnr_terra_hofx_3dvar_LUTs_${obsstr}.nc4
    #obsout1=aod_nnr_aqua_hofx_3dvar_LUTs_${obsstr}.nc4
else
    echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
    exit 1
fi

# Link bckg/analysis files
#iproc=0
#while [ ${iproc} -le 5 ]; do
#   procstr=`printf %04d ${iproc}`
#   if [ $AODTYPE = "VIIRS" ]; then
#       hofxout=${analroot}/aod_viirs_hofx_3dvar_LUTs_${obsstr}_${procstr}.nc4
#       hofx=${WorkDir}/aod_viirs_hofx_3dvar_LUTs_${obsstr}_${procstr}.nc4
#       ${nln} ${hofxout} ${hofx}
#   elif [ $AODTYPE = "MODIS" ]; then
#       hofxout=${analroot}/aod_nnr_terra_hofx_3dvar_LUTs_${obsstr}_${procstr}.nc4
#       hofx=${WorkDir}/aod_nnr_terra_hofx_3dvar_LUTs_${obsstr}_${procstr}.nc4
#       ${nln} ${hofxout} ${hofx}
#
#       hofxout1=${analroot}/aod_nnr_aqua_hofx_3dvar_LUTs_${obsstr}_${procstr}.nc4
#       hofx1=${WorkDir}/aod_nnr_aqua_hofx_3dvar_LUTs_${obsstr}_${procstr}.nc4
#       ${nln} ${hofxout1} ${hofx1}
#   else
#       echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
#       exit
#   fi
#
#   iproc=$((iproc+1))
#done

# link deterministic background/analysis
nowfilestr=${vyy}${vmm}${vdd}.${vhh}0000
gesroot=${RotDir}/gdas.${pyy}${pmm}${pdd}/${phh}/
ensgesroot=${RotDir}/enkfgdas.${pyy}${pmm}${pdd}/${phh}/
#ensgestmp=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/VIIRSAOD_JEDILETKF_C96_C96_M20_GBBPEx_yesFRP_IC_201605MODISAOD_201606/dr-data-backup
#ensgesroot=${ensgestmp}/enkfgdas.${pyy}${pmm}${pdd}/${phh}/
workanal=${WorkDir}/analysis
mkdir -p ${workanal}

## Link control bckg/anal files
mkdir -p ${workinput}/ensmean
couplerges=${gesroot}/RESTART/${nowfilestr}.coupler.res.ges
couplergesout=${workinput}/ensmean/coupler.res
rm -rf ${gesroot}/RESTART/*.nc
rm -rf ${gesroot}/RESTART/*.nc.anl_jedi
${nln} ${couplerges} ${couplergesout}

itile=1
while [ ${itile} -le 6 ]; do
   tilestr=`printf %1i $itile`

   tilefile=fv_tracer.res.tile${tilestr}.nc
   tilefileges=${gesroot}/RESTART/${nowfilestr}.${tilefile}.ges
   tilefilegesout=${workinput}/ensmean/${tilefile}
   ${nln} ${tilefileges} ${tilefilegesout}

   tilefileanl=${gesroot}/RESTART/${nowfilestr}.${tilefile}
   tilefileanlout=${workanal}/${nowfilestr}.hyb-3dvar-gfs_aero.${tilefile}
   ${nln} ${tilefileanl} ${tilefileanlout}

   tilefile=fv_core.res.tile${tilestr}.nc
   tilefileges=${gesroot}/RESTART/${nowfilestr}.${tilefile}.ges
   tilefilegesout=${workinput}/ensmean/${tilefile}
   ${nln} ${tilefileges} ${tilefilegesout}

   itile=$((itile+1))
done


## Link ensemble bckg
imem=1
while [ ${imem} -le ${nmem} ]; do
    memstr="mem"`printf %03d $imem`
    mkdir -p ${workinput}/${memstr}
    couplerges=${ensgesroot}/${memstr}/RESTART/${nowfilestr}.coupler.res.ges
    #couplerges=${ensgesroot}/${memstr}/${nowfilestr}.coupler.res.ges
    couplergesout=${workinput}/${memstr}/coupler.res
    ${nln} ${couplerges} ${couplergesout}

    itile=1
    while [ ${itile} -le 6 ]; do
       tilestr=`printf %1i $itile`
    
       tilefile=fv_tracer.res.tile${tilestr}.nc
       tilefileges=${ensgesroot}/${memstr}/RESTART/${nowfilestr}.${tilefile}.ges
       #tilefileges=${ensgesroot}/${memstr}/${nowfilestr}.${tilefile}.ges
       tilefilegesout=${workinput}/${memstr}/${tilefile}
       ${nln} ${tilefileges} ${tilefilegesout}
    
       tilefile=fv_core.res.tile${tilestr}.nc
       tilefileges=${ensgesroot}/${memstr}/RESTART/${nowfilestr}.${tilefile}.ges
       #tilefileges=${ensgesroot}/${memstr}/${nowfilestr}.${tilefile}.ges
       tilefilegesout=${workinput}/${memstr}/${tilefile}
       ${nln} ${tilefileges} ${tilefilegesout}
    
       itile=$((itile+1))
    done
    imem=$((imem+1))
done

# Link executable
${nln} ${jediexe} ${WorkDir}/fv3jedi_var.x


# generate yaml block for background ensembles 
imem=1
rm -rf ${WorkDir}/yamlblock_mem.info
filetype="        - filetype: gfs"
filetrcr="          filename_trcr: fv_tracer.res.nc"
filecplr="          filename_cplr: coupler.res"
filevars="          state variables: *aerovars"
filevars1="          state variables: &aerovars [sulf,bc1,bc2,oc1,oc2,
                                                 dust1,dust2,dust3,dust4,dust5,
                                                 seas1,seas2,seas3,seas4,seas5]"

while [ ${imem} -le ${nmem} ]; do
   memstr="mem`printf %03d ${imem}`"
   filemem="          datapath: ./input/${memstr}/"
   echo "${filetype}" >> ${WorkDir}/yamlblock_mem.info
   if [ ${imem} -eq 1 ];then
      echo "${filevars1}" >> ${WorkDir}/yamlblock_mem.info
   else
      echo "${filevars}" >> ${WorkDir}/yamlblock_mem.info
   fi

   echo "${filemem}" >> ${WorkDir}/yamlblock_mem.info
   echo "${filetrcr}" >> ${WorkDir}/yamlblock_mem.info
   echo "${filecplr}" >> ${WorkDir}/yamlblock_mem.info
   imem=$((imem+1))
done

yamlblock_mem=`cat ${WorkDir}/yamlblock_mem.info`

# Generate the yaml block for AOD observations

if [ $AODTYPE = "VIIRS" ]; then
yamlblock_obs="  - obs space:
      name: Aod
      obsdatain:
        obsfile: ./input/${obsin}
      #obsdataout:
      #  obsfile: ${obsout}
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
      covariance model: diagonal"
  #- obs space:
  #    name: Aod
  #    obsdatain:
  #      obsfile: ./input/${obsin1}
  #    #obsdataout:
  #    #  obsfile: ${obsout1}
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
  #    covariance model: diagonal"
elif [ $AODTYPE = "MODIS" ]; then
yamlblock_obs="  - obs space:
      name: Aod
      obsdatain:
        obsfile: ./input/${obsin}
      #obsdataout:
      #  obsfile: ${obsout}
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
  - obs space:
      name: Aod
      obsdatain:
        obsfile: ./input/${obsin1}
      #obsdataout:
      #  obsfile: ${obsout1}
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
      covariance model: diagonal"
else
    echo "AODTYBE must be VIIRS or MODIS; exit this program now!"
    exit 1
fi


# Create yaml file
cat << EOF > ${WorkDir}/hyb-3dvar_gfs_aero.yaml
cost function:
  background:
    filetype: gfs
    datapath: ./input/ensmean/
    filename_core: fv_core.res.nc
    filename_trcr: fv_tracer.res.nc
    filename_cplr: coupler.res
    state variables: [T,DELP,sphum,
                      sulf,bc1,bc2,oc1,oc2,
                      dust1,dust2,dust3,dust4,dust5,
                      seas1,seas2,seas3,seas4,seas5]
  background error:
    covariance model: hybrid
    components:
    - covariance:
        covariance model: ID
        date: '${datestr}'
      weight: 
        value: 0.00
    - covariance:
        covariance model: ensemble
        members:
${yamlblock_mem}
        localization:
          localization variables: *aerovars
          localization method: BUMP
          bump:
            prefix: ./bump/fv3jedi_bumpparameters_nicas_gfs
            method: loc
            strategy: common
            load_nicas: 1
            mpicom: 2
            verbosity: main
            io_keys: ["common"]
            io_values: ["fixed_2500km_1.5"]
      weight:
        value: 1.00
  observations:
${yamlblock_obs}
  cost type: 3D-Var
  analysis variables: *aerovars 
  window begin: '${startwindow}'
  window length: PT6H
  geometry:
    nml_file_mpp: fmsmpp.nml
    trc_file: field_table.input
    akbk: ./input/akbk.nc
    layout: [${layout_anal}]
    io_layout: [${io_layout_anal}]
    npx: ${resx}
    npy: ${resy}
    npz: 64
    ntiles: 6
    fieldsets:
      - fieldset: ./dynamics.yaml
      - fieldset: ./aerosols_gfs.yaml
      - fieldset: ./ufo.yaml
final:
  diagnostics:
    departures: oman
output:
  filetype: gfs
  datapath: ./analysis/
  filename_core: hyb-3dvar-gfs_aero.fv_core.res.nc
  filename_trcr: hyb-3dvar-gfs_aero.fv_tracer.res.nc
  filename_cplr: hyb-3dvar-gfs_aero.coupler.res
  first: PT0H
  frequency: PT1H
variational:
  minimizer:
    algorithm: DRIPCG
  iterations:
  - ninner: 80
    gradient norm reduction: 1e-10
    test: on
    geometry:
      trc_file: field_table.input
      akbk: ./input/akbk.nc
      layout: [${layout_anal}]
      io_layout: [${io_layout_anal}]
      npx: ${resx}
      npy: ${resy}
      npz: 64
      ntiles: 6
      fieldsets:
        - fieldset: ./dynamics.yaml
        - fieldset: ./aerosols_gfs.yaml
        - fieldset: ./ufo.yaml
    diagnostics:
      departures: ombg
EOF

exit 0
