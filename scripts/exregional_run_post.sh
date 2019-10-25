#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Source the variable definitions script and the function definitions
# file.
#
#-----------------------------------------------------------------------
#
. ${SCRIPT_VAR_DEFNS_FP}
. $USHDIR/source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u +x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Set the script name and print out an informational message informing
# the user that we've entered this script.
#
#-----------------------------------------------------------------------
#
script_name=$( basename "${BASH_SOURCE[0]}" )
print_info_msg "\n\
========================================================================
Entering script:  \"${script_name}\"
This is the ex-script for the task that runs the post-processor (UPP) on
the output files corresponding to a specified forecast hour.
========================================================================"
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script/function.  
# Then process the arguments provided to this script/function (which 
# should consist of a set of name-value pairs of the form arg1="value1",
# etc).
#
#-----------------------------------------------------------------------
#
valid_args=( "cycle_dir" "postprd_dir" "fhr_dir" "fhr" )
process_args valid_args "$@"

# If VERBOSE is set to TRUE, print out what each valid argument has been
# set to.
if [ "$VERBOSE" = "TRUE" ]; then
  num_valid_args="${#valid_args[@]}"
  print_info_msg "\n\
The arguments to script/function \"${script_name}\" have been set as 
follows:
"
  for (( i=0; i<${num_valid_args}; i++ )); do
    line=$( declare -p "${valid_args[$i]}" )
    printf "  $line\n"
  done
fi
#
#-----------------------------------------------------------------------
#
# Load modules.
#
#-----------------------------------------------------------------------
#
print_info_msg "$VERBOSE" "\
Starting post-processing for fhr = $fhr hr..."

case $MACHINE in


"WCOSS_C" | "WCOSS" )
#  { save_shell_opts; set +x; } > /dev/null 2>&1
  module purge
  . $MODULESHOME/init/ksh
  module load PrgEnv-intel ESMF-intel-haswell/3_1_0rp5 cfp-intel-sandybridge iobuf craype-hugepages2M craype-haswell
#  module load cfp-intel-sandybridge/1.1.0
  module use /gpfs/hps/nco/ops/nwprod/modulefiles
  module load prod_envir
#  module load prod_util
  module load prod_util/1.0.23
  module load grib_util/1.0.3
  module load crtm-intel/2.2.5
  module list
#  { restore_shell_opts; } > /dev/null 2>&1

# Specify computational resources.
  export NODES=8
  export ntasks=96
  export ptile=12
  export threads=1
  export MP_LABELIO=yes
  export OMP_NUM_THREADS=$threads

  APRUN="aprun -j 1 -n${ntasks} -N${ptile} -d${threads} -cc depth"
  ;;


"THEIA")
  { save_shell_opts; set +x; } > /dev/null 2>&1
  module purge
  module load intel
  module load impi 
  module load netcdf
  module load contrib wrap-mpi
  { restore_shell_opts; } > /dev/null 2>&1
  np=${SLURM_NTASKS}
  APRUN="mpirun -np ${np}"
  ;;


"HERA")
  { save_shell_opts; set +x; } > /dev/null 2>&1
  module purge
  
  module load intel/19.0.4.243
  module load impi/2019.0.4

#  module use /contrib/modulefiles
  module use -a /scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles

# Loading nceplibs modules
  module load sigio/2.1.1
  module load jasper/1.900.1
  module load png/1.2.44
  module load z/1.2.11
  module load sfcio/1.1.1
  module load nemsio/2.2.4
  module load bacio/2.0.3
  module load g2/3.1.1
#  module load xmlparse/v2.0.0
  module load gfsio/1.1.0
  module load ip/3.0.2
  module load sp/2.0.3
  module load w3emc/2.3.1
  module load w3nco/2.0.7
  module load crtm/2.2.5
#  module load netcdf/3.6.3
  module load netcdf/4.7.0
  module load g2tmpl/1.5.1
  module load wrfio/1.1.1

  export NDATE=/scratch3/NCEPDEV/nwprod/lib/prod_util/v1.1.0/exec/ndate

  { restore_shell_opts; } > /dev/null 2>&1
  APRUN="srun"
  ;;


"JET")
  { save_shell_opts; set +x; } > /dev/null 2>&1
  module purge 
  . /apps/lmod/lmod/init/sh 
  module load newdefaults
  module load intel/15.0.3.187
  module load impi/5.1.1.109
  module load szip
  module load hdf5
  module load netcdf4/4.2.1.1
  
  set libdir /mnt/lfs3/projects/hfv3gfs/gwv/ljtjet/lib
  
  export NCEPLIBS=/mnt/lfs3/projects/hfv3gfs/gwv/ljtjet/lib

  module use /mnt/lfs3/projects/hfv3gfs/gwv/ljtjet/lib/modulefiles
  module load bacio-intel-sandybridge
  module load sp-intel-sandybridge
  module load ip-intel-sandybridge
  module load w3nco-intel-sandybridge
  module load w3emc-intel-sandybridge
  module load nemsio-intel-sandybridge
  module load sfcio-intel-sandybridge
  module load sigio-intel-sandybridge
  module load g2-intel-sandybridge
  module load g2tmpl-intel-sandybridge
  module load gfsio-intel-sandybridge
  module load crtm-intel-sandybridge
  
  module use /lfs3/projects/hfv3gfs/emc.nemspara/soft/modulefiles
  module load esmf/7.1.0r_impi_optim
  module load contrib wrap-mpi
  { restore_shell_opts; } > /dev/null 2>&1

  np=${SLURM_NTASKS}
  APRUN="mpirun -np ${np}"
  ;;


"ODIN")
  APRUN="srun -n 1"
  ;;


esac
#
#-----------------------------------------------------------------------
#
# Remove any files from previous runs and stage necessary files in fhr_dir.
#
#-----------------------------------------------------------------------
#
rm_vrfy -f fort.*
cp_vrfy $FIXupp/nam_micro_lookup.dat ./eta_micro_lookup.dat
cp_vrfy $FIXupp/postxconfig-NT-fv3sar.txt ./postxconfig-NT.txt
cp_vrfy $FIXupp/params_grib2_tbl_new ./params_grib2_tbl_new
cp_vrfy ${EXECDIR}/ncep_post .
#
#-----------------------------------------------------------------------
#
# Get the cycle date and hour (in formats of yyyymmdd and hh, respect-
# ively) from CDATE.
#
#-----------------------------------------------------------------------
#
yyyymmdd=${CDATE:0:8}
hh=${CDATE:8:2}
cyc=$hh
tmmark="tm$hh"
#
#-----------------------------------------------------------------------
#
# Create a text file (itag) containing arguments to pass to the post-
# processing executable.
#
#-----------------------------------------------------------------------
#
dyn_file="${cycle_dir}/dynf0${fhr}.nc"
phy_file="${cycle_dir}/phyf0${fhr}.nc"

#POST_TIME=$( ${NDATE} +${fhr} ${CDATE} )
POST_TIME=$( date --utc --date "${yyyymmdd} ${hh} UTC + ${fhr} hours" "+%Y%m%d%H" )
POST_YYYY=${POST_TIME:0:4}
POST_MM=${POST_TIME:4:2}
POST_DD=${POST_TIME:6:2}
POST_HH=${POST_TIME:8:2}

cat > itag <<EOF
${dyn_file}
netcdf
grib2
${POST_YYYY}-${POST_MM}-${POST_DD}_${POST_HH}:00:00
FV3R
${phy_file}

 &NAMPGB
 KPO=47,PO=1000.,975.,950.,925.,900.,875.,850.,825.,800.,775.,750.,725.,700.,675.,650.,625.,600.,575.,550.,525.,500.,475.,450.,425.,400.,375.,350.,325.,300.,275.,250.,225.,200.,175.,150.,125.,100.,70.,50.,30.,20.,10.,7.,5.,3.,2.,1.,
 /
EOF
#
#-----------------------------------------------------------------------
#
# Copy the UPP executable to fhr_dir and run the post-processor.
#
#-----------------------------------------------------------------------
#
${APRUN} ./ncep_post < itag || print_err_msg_exit "\
Call to executable to run post for forecast hour $fhr returned with non-
zero exit code."
#
#-----------------------------------------------------------------------
#
# Move (and rename) the output files from the work directory to their
# final location (postprd_dir).  Then delete the work directory. 
#
#-----------------------------------------------------------------------
#
if [ -n "${PREDEF_GRID_NAME}" ]; then 

  grid_name="${PREDEF_GRID_NAME}"

else 

  grid_name="${GRID_GEN_METHOD}"

  if [ "${GRID_GEN_METHOD}" = "GFDLgrid" ]; then
    stretch_str="S$( printf "%s" "${stretch_fac}" | sed "s|\.|p|" )"
    refine_str="RR${refine_ratio}"
    grid_name="${grid_name}_${CRES}_${stretch_str}_${refine_str}"
  elif [ "${GRID_GEN_METHOD}" = "JPgrid" ]; then
    nx_T7_str="NX$( printf "%s" "${nx_T7}" | sed "s|\.|p|" )"
    ny_T7_str="NY$( printf "%s" "${ny_T7}" | sed "s|\.|p|" )"
    a_grid_param_str="A$( printf "%s" "${a_grid_param}" | sed "s|-|mns|" | sed "s|\.|p|" )"
    k_grid_param_str="K$( printf "%s" "${k_grid_param}" | sed "s|-|mns|" | sed "s|\.|p|" )"
    grid_name="${grid_name}_${nx_T7_str}_${ny_T7_str}_${a_grid_param_str}_${k_grid_param_str}"
  fi

fi

mv_vrfy BGDAWP.GrbF${fhr} ${postprd_dir}/HRRR.t${cyc}z.bgdawp${fhr}.${tmmark}
mv_vrfy BGRD3D.GrbF${fhr} ${postprd_dir}/HRRR.t${cyc}z.bgrd3d${fhr}.${tmmark}

#Link output for transfer to Jet

START_DATE=`echo "${CDATE}" | sed 's/\([[:digit:]]\{2\}\)$/ \1/'`
basetime=`date +%y%j%H%M -d "${START_DATE}"`
ln_vrfy -fs ${postprd_dir}/HRRR.t${cyc}z.bgdawp${fhr}.${tmmark} \
            ${postprd_dir}/BGDAWP_${basetime}${fhr}00
ln_vrfy -fs ${postprd_dir}/HRRR.t${cyc}z.bgrd3d${fhr}.${tmmark} \
            ${postprd_dir}/BGRD3D_${basetime}${fhr}00

rm_vrfy -rf ${fhr_dir}
#
#-----------------------------------------------------------------------
#
# Print message indicating successful completion of script.
#
#-----------------------------------------------------------------------
#
print_info_msg "\n\
========================================================================
Post-processing for forecast hour $fhr completed successfully.
Exiting script:  \"${script_name}\"
========================================================================"
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the beginning of this script/func-
# tion.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1

