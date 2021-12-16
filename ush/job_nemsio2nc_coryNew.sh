#!/bin/bash
#SBATCH -J sig2nc_run 
#SBATCH -A chem-var
#SBATCH --open-mode=truncate
#SBATCH -o log.sig2nc
#SBATCH -e log.sig2nc
#SBATCH --nodes=1
#SBATCH -q debug
#SBATCH -t 00:30:00

#utility location on github
#https://github.com/CoryMartin-NOAA/nemsio2nc

set -x

utildir=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/coldstartIC/metAna-V15/scripts/NEMSIO2NC-CoryNew/nemsio2nc
utilbuild=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/coldstartIC/metAna-V15/scripts/NEMSIO2NC-CoryNew/build
utilexec=${utilbuild}/bin/nemsioatm2nc

atmsne=/scratch2/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expRuns/global-workflow-CCPP2-Chem-NRT-clean/dr-data/downloadHpss/coldstartIC/metAna-V15/gdas-2019072006-nemsio/gdas.20190720/00/gdas.t00z.atmanl.nemsio	

atmsnc=./gdas.t00z.atmanl.nc

module use ${utildir}/modulefiles
module load hera.gnu

${utilexec} ${atmsne} ${atmsnc}



