#!/bin/ksh
set -x 
sorc_dir=$(pwd)
exec_dir=$(pwd)
mkdir -p $exec_dir
#
#
make_dir=/ptmp/$LOGNAME/sorc/$(basename $sorc_dir)
mkdir -p $make_dir
cd $make_dir
cd $make_dir || exit 99
[ $? -ne 0 ] && exit 8
#
  rm $make_dir/*.o
  rm  $make_dir/*.mod
#
tar -cf- -C$sorc_dir .|tar -xf-
#
CP1=cp
#
 export EXEC="$exec_dir/global_fcst"
#
 export F77=mpxlf95_r
 export F90=mpxlf95_r
#
 make -f Makefile
