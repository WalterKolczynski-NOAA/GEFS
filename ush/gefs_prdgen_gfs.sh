#!/bin/ksh
#####################################################################
echo "-----------------------------------------------------"
echo " gefs_prdgen_gfs.sh"
echo " originally named exglobal_post_gfs.sh.sms"
echo " and then exgefs_prdgen_gfs.sh.sms"
echo " Feb 06 - Wobus - new script to convert gfs to pgrba"
echo " Jul 11 - Wobus - rename to exgefs_prdgen_gfs.sh.sms"
echo " Oct 14 - Hou -  Createded exgefs_prdgen_gfs_grb2.sh.sms following"
echo "                 exgefs_prdgen_gfs.sh.sms but for grib2 input files"
echo " Jan 15 - Hou -  renamed exgefs_prdgen_gfs.sh.ecf"
echo " April 15 - Hou - moved to ush and renamed gefs_prdgen_gfs.sh"
echo " April 17 - Meng - Simplified to process a single grid $jobgrid=1p0/2p5/0p5"
echo " Jan 18 - Hou - unified for 3-digit forecast hours in file names"
echo "-----------------------------------------------------"
#####################################################################

set -xa

export option1=${option1:-' -set_grib_type same -new_grid_winds earth '}
export option21=${option21:-' -new_grid_interpolation bilinear  -if '}
export option22=${option22:-":(LAND|CSNOW|CRAIN|CFRZR|CICEP|ICSEV):"}
export option23=${option23:-' -new_grid_interpolation neighbor -fi '}
export grid0p25=${grid0p25:-"latlon 0:1440:0.25 90:721:-0.25"}
export grid0p5=${grid0p5:-"latlon 0:720:0.5 90:361:-0.5"}
export grid1p0=${grid1p0:-"latlon 0:360:1.0 90:181:-1.0"}
export grid2p5=${grid2p5:-"latlon 0:144:2.5 90:73:-2.5"}

#export WGRIB=${WGRIB:-$EXECgrib/wgrib}
#export GRBINDEX=${GRBINDEX:-$EXECgrib/grbindex}
#export COPYGB=${COPYGB:-$EXECgrib/copygb}
#export WGRIB2=${WGRIB2:-$EXECgrib/wgrib2}
#export GRB2INDEX=${GRB2INDEX:-$EXECgrib/grb2index}
#export COPYGB2=${COPYGB2:-$EXECgrib/copygb2}
#export CNVGRIB=${CNVGRIB:-$EXECgrib/cnvgrib21_gfs}

export ENSADD=${ENSADD:-$USHgefs/global_ensadd.sh}
export TRANSG=${TRANSG:-$USHgefs/gefs_transfer_gfs.sh}

echo WGRIB=$WGRIB
echo WGRIB2=$WGRIB2
echo COPYGB=$COPYGB
echo COPYGB2=$COPYGB2
echo CNVGRIB=$CNVGRIB
echo GRBINDEX=$GRBINDEX
echo GRB2INDEX=$GRB2INDEX
echo ENSADD=$ENSADD

parm00=$PARMgefs/gefs_pgrb2a_f00.parm
parmhh=$PARMgefs/gefs_pgrb2a_fhh.parm

export GRID=$jobgrid
case $jobgrid in
	1p0) 
		dirsuf=1p0
		filsuf=.1p00.
		filetail=
		grid=${grid1p0}
		;;
	2p5) 
		dirsuf=2p5
		filsuf=.2p50.
		filetail=
		grid=${grid2p5}
		;;
	0p5) 
		dirsuf=p5
		filsuf=.0p50.
		filetail=
		grid=${grid0p5}
		;;
esac

# set variables for ensemble PDS header
(( e1 = 0 ))
(( e2 = 0 ))

############################################################
#  Define Variables:
#  -----------------
#  SHOUR        is the starting forecast hour. normally 0 except for restarts.
#  FHOUR        is the ending forecast hour.
#  FHINC        is the increment hour for each forecast steps.
#  FH           is the current forecast hour.
#  SLEEP_TIME   is the number of seconds to sleep before exiting with error.
#  SLEEP_INT    is the number of seconds to sleep between restrt file checks.
#  restart_file is the name of the file to key off of to kick off post.
############################################################

############################################################
# Post Analysis Files before starting the Forecast Post
############################################################
if test -f $COMINgfs/${RUNMEM}.t${cyc}z.master.grb2anl -a ${SHOUR} -eq 0 -a "$jobgrid" != '2p5'; then

	# RLW 20110725 more complete cleanup of temporary files
	rm -f master_grb2file
	rm -f tmpfile
	rm -f pgbafile pgbaifile
	rm -f pgb2afile pgb2aifile

	parmlist=$parm00 
	ln -s $COMINgfs/${RUNMEM}.t${cyc}z.master.grb2anl master_grb2file
	$WGRIB2 -s master_grb2file |grep -F -f $parmlist |$WGRIB2 master_grb2file -i -grib tmpfile
	$WGRIB2 tmpfile $option1 $option21 $option22 $option23 -new_grid $grid pgb2afile
#	$COPYGB2 -g "${grid}" -i0 -x tmpfile pgb2afile
	$GRB2INDEX pgb2afile pgb2aifile
	$ENSADD $e1 $e2 pgb2afile epgbafile
	mv epgbafile pgb2afile

	if test "$SENDCOM" = 'YES'; then
	#
	# Save Pressure GRIB2/Index files
	#
		mv pgb2afile $COMOUT/$cyc/pgrb2a$dirsuf/ge${RUNMEM}.${cycle}.pgrb2a$filsuf\anl
		testfile=$COMOUT/$cyc/pgrb2a$dirsuf/ge${RUNMEM}.${cycle}.pgrb2a$filsuf\anl
		if [[ ! -s $testfile ]]; then
			msg="FATAL ERROR: $testfile WAS NOT WRITTEN"
			echo "`date`    $msg"
			postmsg "$jlogfile" "$msg"
			export err=1
			err_chk
		fi # [[ ! -s $testfile ]]
		if [[ "$makegrb2i" = "yes" ]]; then
			mv pgb2aifile $COMOUT/$cyc/pgrb2a$dirsuf/ge${RUNMEM}.${cycle}.pgrb2a$filsuf\anl.idx
			testfile=$COMOUT/$cyc/pgrb2a$dirsuf/ge${RUNMEM}.${cycle}.pgrb2a$filsuf\anl.idx
			if [[ ! -s $testfile ]]; then
				msg="FATAL ERROR: $testfile WAS NOT WRITTEN"
				echo "`date`    $msg"
				postmsg "$jlogfile" "$msg"
				export err=1
				err_chk
				fi # [[ ! -s $testfile ]]
		fi # [[ "$makegrb2i" = "yes" ]]
		#################################### CHECK DBN ALERTS ###########
		if test "$SENDDBN" = 'YES'; then
			if test "$NET" = 'gens'; then
				MEMBER=GFS
				if [[ "$makepgrb2" = "yes" ]]; then
					$DBNROOT/bin/dbn_alert MODEL ENS_PGB2A_${GRID}_$MEMBER $job $COMOUT/$cyc/pgrb2a$dirsuf/ge${RUNMEM}.${cycle}.pgrb2a$filsuf\anl
				fi
			fi # test "$NET" = 'gens'
		fi # test "$SENDDBN" = 'YES'
	fi # test "$SENDCOM" = 'YES'
fi # test -f $COMINgfs/${RUNMEM}.t${cyc}z.master.grb2anl -a ${SHOUR} -eq 0

SLEEP_LOOP_MAX=`expr $SLEEP_TIME / $SLEEP_INT`

(( fhr=SHOUR))
if (( fhr == 0 )); then
	fhr=00
fi
export fhr

if test $fhr -lt 10 -a $fhr -gt 0; then
	export fhr="0$fhr"
fi

############################################################
# Loop Through the Post Forecast Files 
############################################################
while test $fhr -le $FHOUR; do
	###############################
	# Start Looping for the 
	# existence of the restart files
	###############################
	#set +x
	set -x
	export pgm="postcheck"
	ic=1

	while [ $ic -le $SLEEP_LOOP_MAX ]; do
		if test -f $COMINgfs/${RUNMEM}.t${cyc}z.master.grb2f$fhr; then
			found=yes
			break
		else
			ic=`expr $ic + 1`
			sleep $SLEEP_INT
		fi # test -f $COMINgfs/${RUNMEM}.t${cyc}z.master.grb2f$fhr
		if (( fhr > 180 )) && (( fhr % 12 == 6 )); then
			if (( ic > 2 )) && (( ic < SLEEP_LOOP_MAX )); then
				echo fhr=$fhr not expected
				found=no
				break
			fi # (( ic > 2 )) && (( ic < SLEEP_LOOP_MAX ))
		fi # (( fhr > 180 )) && (( fhr % 12 == 6 ))
		###############################
		# If we reach this point assume
		# fcst job never reached restart 
		# period and error exit
		###############################
		if [ $ic -eq $SLEEP_LOOP_MAX ]; then
			export err=9
			err_chk
		fi # [ $ic -eq $SLEEP_LOOP_MAX ]
	done # while [ $ic -le $SLEEP_LOOP_MAX ]
	#set -x

	if [[ "$found" = yes ]]; then
		rm -f master_grb2file
		rm -f tmpfile
		rm -f pgbafile pgbaifile
		rm -f pgb2afile pgb2aifile

		msg="Starting prdgen for fhr=$fhr"
		postmsg "$jlogfile" "$msg"

		if [ $fhr -eq 0 ]; then
			#     parmlist=$PARMgefs/gefs_pgrb2a_f00.parm
			parmlist=$parm00 
		else
			#     parmlist=$PARMgefs/gefs_pgrb2a_fhh.parm
			parmlist=$parmhh 
		fi # [ $fhr -eq 0 ]

		ln -s $COMINgfs/${RUNMEM}.t${cyc}z.master.grb2f${fhr} master_grb2file

		$WGRIB2 -s master_grb2file |grep -F -f $parmlist |$WGRIB2 master_grb2file -i -grib tmpfile
		if [[ x$fhoroglist != x ]]; then
			for fhorog in $fhoroglist; do
				if (( fhr == fhorog )); then
					$WGRIB2 -s master_grb2file |grep 'HGT:surface' |$WGRIB2 master_grb2file -i -append -grib tmpfile 
				fi
			done # for fhorog in $fhoroglist
		fi # [[ x$fhoroglist != x ]]

		#$COPYGB2 -g "${grid}" -i0 -x tmpfile pgb2afile
		$WGRIB2 tmpfile $option1 $option21 $option22 $option23 -new_grid $grid pgb2afile
		$GRB2INDEX pgb2afile pgb2aifile
		$ENSADD $e1 $e2 pgb2afile epgbafile
		mv epgbafile pgb2afile
    		if test $fhr -lt 100; then
 			pgfhr=0$fhr
    		else
 			pgfhr=$fhr
    		fi

		$TRANSG  pgrb2a$dirsuf pgrb2a$filsuf

		if test $SENDCOM = "YES"; then
			if test $fhr -lt 100; then
				pad="0"
			else
				pad=""
			fi
			echo "$PDY$cyc$pad$fhr" > $COMOUT/$cyc/misc/gfs/ge${RUNMEM}.t${cyc}z.control.$fhr$jobgrid
		fi # test $SENDCOM = "YES"
	fi # [[ "$found" = yes ]]
	# if not found, come here to increment

	if [[ $jobgrid == 0p5 ]] && [[ $fhr == $fhmaxh ]]; then
		FHINC=6
	fi 
	export fhr=`expr $fhr + $FHINC`
	if test $fhr -lt 10; then
		export fhr="0$fhr"
	fi
done # while test $fhr -le $FHOUR

cat $pgmout

########################################################

echo `date` $0 end
msg='ENDED NORMALLY.'
postmsg "$jlogfile" "$msg"

################## END OF SCRIPT #######################
