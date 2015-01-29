#!/bin/ksh
#####################################################################
echo "-----------------------------------------------------"
echo " Script: gefs_prdgen.sh" 
echo " "
echo " Purpose - Perform interpolation and GRIB2 conversion"
echo "           on master GRIB files"
echo "           for one member and one time step."
echo "           Move posted files to /com"
echo "           Alert posted files to DBNet"
echo " "
echo " History - "
echo "    Wobus   - 8/28/07 - New "
echo "    Wobus   - 7/30/10 - move 180-192hr products to pgrbd"
echo "    Hou     - 7/31/14 - adopted for grib2 based processing "
echo "-----------------------------------------------------"
#####################################################################
set -xa

anlflag=$anlflag
ffhr=$ffhr
fhr=$fhr
grid=$gridp5

export WGRIB=${WGRIB:-$EXECutil/wgrib}
export GRBIDX=${GRBIDX:-$EXECutil/grbindex}
export COPYGB=${COPYGB:-$EXECutil/copygb}
export WGRIB2=${WGRIB2:-$EXECutil/wgrib2}
export GRB2IDX=${GRB2IDX:-$EXECutil/grb2index}
export COPYGB2=${COPYGB2:-$EXECutil/copygb2}
export CNVGRIB=${CNVGRIB:-$EXECutil/cnvgrib21}
#export CNVGRIB=${CNVGRIB:-/nco/sib/gribdev/util/exec/cnvgrib21_gfs}

#export ENSADD=${ENSADD:-$USHgefs/global_ensadd.sh}

echo settings in $0 gefsmachine=$gefsmachine
echo settings in $0 WGRIB=$WGRIB
echo settings in $0 WGRIB2=$WGRIB2
echo settings in $0 GRBIDX=$GRBIDX
echo settings in $0 GRB2IDX=$GRB2IDX
echo settings in $0 COPYGB=$COPYGB
echo settings in $0 COPYGB2=$COPYGB2
echo settings in $0 CNVGRIB=$CNVGRIB
#echo settings in $0 ENSADD=$ENSADD

R1=`echo $RUN|cut -c1-3`
R2=`echo $RUN|cut -c4-5`
case $R1 in
  (gec) if (( R2 == 0 )); then 
           (( e1 = 1 ))
	   (( e2 = 2 ))
	fi;;
  (gen) (( e1 = 2 ))
	(( e2 = R2 ));;
  (gep) (( e1 = 3 ))
	(( e2 = R2 ));;
  (*)   (( e1 = 0 ))
	(( e2 = 0 ))
	echo unrecognized RUN=$RUN R1=$R1 R2=$R2 ;;
esac

msg="Starting post for member=$member ffhr=$ffhr"
postmsg "$jlogfile" "$msg"

####################################
# Step I: Create 1x1 pgrb2 files 
####################################
if [[ -s $DATA/pgrb2$ffhr$cfsuffix ]] && \
   [[ -s $DATA/pgrb2i$ffhr$cfsuffix ]] && \
   [[ $overwrite = no ]]; then
   echo `date` 1x1 pgrb2 processing skipped for $RUN $ffhr
else
   $COPYGB2 -g "${grid}" -i0 -x $COMIN/$cyc/master/$RUN.$cycle.master.grb2$ffhr$cfsuffix pgb2file.$ffhr$cfsuffix
   echo `date` pgrb2ap5 1x1 grbfile $ffhr completed

   ######################################################
   # Split the pgb2file into pgrb2ap5, pgrb2bp5 and pgrb2dp5 parts
   ######################################################
   if (( fhr == 0 ))
   then
     hsuffix="00"
   else
     hsuffix="hh"
   fi

#  set +x

   excludestring='180-192hr'

   # begin block removed from background
#  parmlist=$PARMgefs/gefs_pgrba_f${hsuffix}.parm
   parmlist=$PARMgefs/gefs_pgrb2a_f${hsuffix}.parm
   $WGRIB2 -s pgb2file.$ffhr$cfsuffix | \
       grep -F -f $parmlist | \
       grep -v -F $excludestring | \
       $WGRIB2 pgb2file.$ffhr$cfsuffix -s -i -grib pgb2afile.$ffhr$cfsuffix
   if [[ x$fhoroglist != x ]]; then
      for fhorog in $fhoroglist
      do
	if (( fhr == fhorog )); then
	  $WGRIB2 -s pgb2file.$ffhr$cfsuffix | grep 'HGT:sfc' | $WGRIB2 pgb2file.$ffhr$cfsuffix -i -append -grib pgb2afile.$ffhr$cfsuffix
	fi
      done
   fi
   $WGRIB2 -s pgb2afile.$ffhr$cfsuffix > pgb2afile.${ffhr}${cfsuffix}.idx
#  $GRB2IDX pgb2afile.$ffhr$cfsuffix pgb2afile.$ffhr$cfsuffix.idx
   # end block removed from background

   # begin block removed from background
#  parmlist=$PARMgefs/gefs_pgrbb_f${hsuffix}.parm
   parmlist2=$PARMgefs/gefs_pgrb2ab_f${hsuffix}.parm
   $WGRIB2 -s pgb2file.$ffhr$cfsuffix | \
       grep -F -f $parmlist2 | \
       grep -v -F -f $parmlist | \
       grep -v -F $excludestring | \
       $WGRIB2 pgb2file.$ffhr$cfsuffix -s -i -grib pgb2bfile.$ffhr$cfsuffix
   $WGRIB2 -s pgb2bfile.$ffhr$cfsuffix > pgb2bfile.${ffhr}${cfsuffix}.idx
#  $GRB2IDX pgb2bfile.$ffhr$cfsuffix pgb2bfile.$ffhr$cfsuffix.idx
   # end block removed from background

#  if test "$CREATE_TIGGE" = 'YES'
#  then
#     if (( fhr == 0 )); then
#       parmlist=${PARMgefs}/gefs_pgrb2c_f00.parm
#     else
#       parmlist=${PARMgefs}/gefs_pgrb2c_fhh.parm
#     fi
##    set +x
#     $WGRIB2 pgb2bfile.$ffhr$cfsuffix | \
#       grep -F -f $parmlist | \
#       $WGRIB2 pgb2bfile.$ffhr$cfsuffix -i -grib pgb2cfile.$ffhr$cfsuffix 
##    set -x
   fi

   # begin block removed from background
   $WGRIB2 -s pgb2file.$ffhr$cfsuffix | \
       grep -v -F -f $parmlist2 | \
       $WGRIB2 pgb2file.$ffhr$cfsuffix -s -i -grib pgb2dfile.$ffhr$cfsuffix
   $WGRIB2 -s pgb2file.$ffhr$cfsuffix | \
       grep -F -f $parmlist2 | \
       grep -F $excludestring | \
       $WGRIB2 pgb2file.$ffhr$cfsuffix -s -i -append -grib pgb2dfile.$ffhr$cfsuffix
   # end block removed from background
#  set -x

   #wait

   if test "$SENDCOM" = 'YES'
   then
      #
      # Save Pressure GRIB/Index files
      #
      mv pgb2afile.$ffhr$cfsuffix $COMOUT/$cyc/pgrb2ap5/${RUN}.${cycle}.pgrb2ap5$ffhr$cfsuffix
      mv pgb2bfile.$ffhr$cfsuffix $COMOUT/$cyc/pgrb2bp5/${RUN}.${cycle}.pgrb2bp5$ffhr$cfsuffix
#     mv pgb2cfile.$ffhr$cfsuffix $COMOUT/$cyc/pgrb2cp5/${RUN}.${cycle}.pgrb2cp5$ffhr$cfsuffix
      mv pgb2dfile.$ffhr$cfsuffix $COMOUT/$cyc/pgrb2dp5/${RUN}.${cycle}.pgrb2dp5$ffhr$cfsuffix
      if [[ "$makegrb1i" = "yes" ]]; then
	mv pgb2afile.$ffhr$cfsuffix.idx $COMOUT/$cyc/pgrb2ap5/${RUN}.${cycle}.pgrb2ap5$ffhr$cfsuffix.idx
	mv pgb2bfile.$ffhr$cfsuffix.idx $COMOUT/$cyc/pgrb2bp5/${RUN}.${cycle}.pgrb2bp5$ffhr$cfsuffix.idx
      fi

      ###############################################################################
      # Send DBNet alerts for PGBA and PGBA2 at 6 hour increments for all forecast hours
      # Do for 00, 06, 12, and 18Z cycles.
      ###############################################################################
      if test "$SENDDBN" = 'YES' -a "$NET" = 'gens' -a ` expr $cyc % 6 ` -eq 0
      then
	if test `echo $RUN | cut -c1-2` = "ge"
	then
	  MEMBER=`echo $RUN | cut -c3-5 | tr '[a-z]' '[A-Z]'`
	  if [[ $fhr -ge 0 && $fhr -le $fhmax && ` expr $fhr % 6 ` -eq 0 && ! -n "$cfsuffix" ]]
	  then
	    $DBNROOT/bin/dbn_alert MODEL ENS_PGBA_$MEMBER $job $COMOUT/$cyc/pgrb2ap5/${RUN}.${cycle}.pgrb2ap5$ffhr$cfsuffix
	    $DBNROOT/bin/dbn_alert MODEL ENS_PGBA_${MEMBER}_WIDX $job $COMOUT/$cyc/pgrb2ap5/${RUN}.${cycle}.pgrb2ap5$ffhr$cfsuffix.idx
	  fi
	fi
      fi

      ###############################################################################
      # Send DBNet alerts for PGBB and PGB2B at 6 hour increments for up to 84 hours
      # Do for 00Z and 12Z only
      ###############################################################################
       if test "$SENDDBN" = 'YES' -a "$NET" = 'gens' -a "$NET" = 'gens'
       then
         if test `echo $RUN | cut -c1-2` = "ge" -a ! -n "$cfsuffix"
	 then
	  MEMBER=`echo $RUN | cut -c3-5 | tr '[a-z]' '[A-Z]'`
	# if [[ $fhr -ge 0 && $fhr -le 84 && ` expr $fhr % 6 ` -eq 0 && ! -n "$cfsuffix" ]]
	# then
	    $DBNROOT/bin/dbn_alert MODEL ENS_PGB2B_$MEMBER $job $COMOUT/$cyc/pgrb2bp5/${RUN}.${cycle}.pgrb2bp5$ffhr$cfsuffix
	    $DBNROOT/bin/dbn_alert MODEL ENS_PGB2B_${MEMBER}_WIDX $job $COMOUT/$cyc/pgrb2bp5/${RUN}.${cycle}.pgrb2bp5$ffhr$cfsuffix.idx
	# fi
         fi

      ###############################################################################
      # Do Not send DBNet alerts for the PGBD files at this time
      ###############################################################################
       fi
   fi
echo `date` pgrb2ap5 0.5x0.5 sendcom $ffhr completed
#fi

  case $gefsmachine in
    (wcoss)
      fmakegb1=1
    ;;
    (zeus)
      fmakegb1=0
    ;;
  esac
 if (( fmakegb1 == 1 )); then
######################################
# Step II: Create GRIBA files
#####################################
if [[ -s $COMOUT/$cyc/pgrbap5/${RUN}.${cycle}.pgrbap5$ffhr$cfsuffix ]] && \
   [[ -s $COMOUT/$cyc/pgrbap5/${RUN}.${cycle}.pgrbap5i$ffhr$cfsuffix ]] && \
   [[ $overwrite = no ]]; then
   echo `date` 1x1 pgrbap5 processing skipped for $RUN $ffhr
else
   FILEA=$COMIN/$cyc/pgrb2ap5/${RUN}.${cycle}.pgrb2ap5$ffhr$cfsuffix
   $CNVGRIB -g21 $FILEA pgbafile.$ffhr$cfsuffix
   $GRBIDX pgbafile.$ffhr$cfsuffix pgbaifile.$ffhr$cfsuffix
#  $WGRIB -s pgbafile.$ffhr$cfsuffix > pgbaifile.${ffhr}${cfsuffix}.idx
#  $ENSADD $e1 $e2 pgbafile.$ffhr$cfsuffix pgbaifile.$ffhr$cfsuffix epgbafile.$ffhr$cfsuffix
#  echo after ADDING
#  ls -lt  pgbafile.$ffhr$cfsuffix pgbaifile.$ffhr$cfsuffix epgbafile.$ffhr$cfsuffix
   if [[ "$addgrb1id" = "yes" ]]; then
     mv epgbafile.$ffhr$cfsuffix pgbafile.$ffhr$cfsuffix
#  echo after MVING
#  ls -lt  pgbafile.$ffhr$cfsuffix pgbaifile.$ffhr$cfsuffix epgbafile.$ffhr$cfsuffix
     if [[ "$makegrb1i" = "yes" ]]; then
       $GRBIDX pgbafile.$ffhr$cfsuffix pgbaifile.$ffhr$cfsuffix
     fi

   if test "$SENDCOM" = 'YES'
   then
     #
     # Save Pressure GRIB/Index files
     #
     mv pgbafile.$ffhr$cfsuffix $COMOUT/$cyc/pgrbap5/${RUN}.${cycle}.pgrbap5$ffhr$cfsuffix
     mv pgbaifile.${ffhr}${cfsuffix} $COMOUT/$cyc/pgrbap5/${RUN}.${cycle}.pgrbap5i${ffhr}${cfsuffix}

     if test "$SENDDBN" = 'YES'
     then
       if test "$NET" = 'gens'
       then
         if test `echo $RUN | cut -c1-2` = "ge" -a ! -n "$cfsuffix"
         then
           MEMBER=`echo $RUN | cut -c3-5 | tr '[a-z]' '[A-Z]'`
           $DBNROOT/bin/dbn_alert MODEL ENS_PGBA_$MEMBER $job $COMOUT/$cyc/pgrbap5/${RUN}.${cycle}.pgrbap5$ffhr$cfsuffix
             $COMOUT/$cyc/pgrbap5/${RUN}.${cycle}.pgrbap5i${ffhr}${cfsuffix}
         fi
       fi
     fi
   fi
   fi
fi

###########################################
# STEP III: Create GRIBB files
###########################################
if [[ -s $COMOUT/$cyc/pgrbbp5/${RUN}.${cycle}.pgrbbp5$ffhr$cfsuffix ]] && \
   [[ -s $COMOUT/$cyc/pgrbbp5/${RUN}.${cycle}.pgrbbp5i$ffhr$cfsuffix ]] && \
   [[ $overwrite = no ]]; then
   echo `date` 1x1 pgrbbp5 processing skipped for $RUN $ffhr
else
   FILEB=$COMIN/$cyc/pgrb2bp5/${RUN}.${cycle}.pgrb2bp5$ffhr$cfsuffix
   $CNVGRIB -g21 $FILEB pgbbfile.$ffhr$cfsuffix
   $GRBIDX pgbbfile.$ffhr$cfsuffix pgbbifile.$ffhr$cfsuffix
#  $WGRIB -s pgbbfile.$ffhr$cfsuffix > pgbbfile.${ffhr}${cfsuffix}.idx
#  $ENSADD $e1 $e2 pgbbfile.$ffhr$cfsuffix pgbbifile.$ffhr$cfsuffix epgbbfile.$ffhr$cfsuffix
   if [[ "$addgrb1id" = "yes" ]]; then
     mv epgbbfile.$ffhr$cfsuffix pgbbfile.$ffhr$cfsuffix
     if [[ "$makegrb1i" = "yes" ]]; then
       $GRBIDX pgbbfile.$ffhr$cfsuffix pgbbifile.$ffhr$cfsuffix
     fi

   if test "$SENDCOM" = 'YES'
   then
      #
      # Save Pressure GRIB/Index files
      #
      mv pgbbfile.$ffhr$cfsuffix $COMOUT/$cyc/pgrbbp5/${RUN}.${cycle}.pgrbbp5$ffhr$cfsuffix
      mv pgbbfile.${ffhr}${cfsuffix}.idx $COMOUT/$cyc/pgrbbp5/${RUN}.${cycle}.pgrbbp5i${ffhr}${cfsuffix}

      #if test "$SENDDBN" = 'YES'
      #then
        #if test "$NET" = 'gens'
        #then
          #if test `echo $RUN | cut -c1-2` = "ge" -a ! -n "$cfsuffix"
          #then
            #MEMBER=`echo $RUN | cut -c3-5 | tr '[a-z]' '[A-Z]'`
            #$DBNROOT/bin/dbn_alert MODEL ENS_PGB2B_$MEMBER $job $COMOUT/$cyc/pgrb2bp5/${RUN}.${cycle}.pgrb2bp5$ffhr$cfsuffix
            #$DBNROOT/bin/dbn_alert MODEL ENS_PGB2B_${MEMBER}_WIDX $job \
            #       $COMOUT/$cyc/pgrbbp5/${RUN}.${cycle}.pgrbbp5i$ffhr${cfsuffix}
            
            #if test "$CREATE_TIGGE" = 'YES'
            #then
            #  $DBNROOT/bin/dbn_alert MODEL ENS_PGB2C_$MEMBER $job $COMOUT/$cyc/pgrb2cp5/${RUN}.${cycle}.pgrb2cp5$ffhr$cfsuffix
            #fi
          #fi
        #fi
      #fi
   fi
   fi
fi

###############################
# STEP IV: Create GRIBD files
###############################
if [[ -f $COMOUT/$cyc/pgrbdp5/${RUN}.${cycle}.pgrbdp5$ffhr$cfsuffix ]] && \
   [[ -f $COMOUT/$cyc/pgrbdp5/${RUN}.${cycle}.pgrbdp5i$ffhr$cfsuffix ]] && \
   [[ $overwrite = no ]]; then
   echo `date` 1x1 pgrbdp5 processing skipped for $RUN $ffhr
else

   FILED=$COMIN/$cyc/pgrb2dp5/${RUN}.${cycle}.pgrb2dp5$ffhr$cfsuffix

   $CNVGRIB -g21 $FILED pgbdfile.$ffhr$cfsuffix

   if test "$SENDCOM" = 'YES'
   then
      #
      # Save Pressure GRIB/Index files
      #
      mv pgbdfile.$ffhr$cfsuffix $COMOUT/$cyc/pgrbdp5/${RUN}.${cycle}.pgrbdp5$ffhr$cfsuffix
   fi
fi

 fi #(0=1 for ZEUS, skip grib2 files)
########################################################
echo `date` $sname $member $partltr $cfsuffix $fsuffix 1x1 GRIB end on machine=`uname -n`
msg='ENDED NORMALLY.'
postmsg "$jlogfile" "$msg"

################## END OF SCRIPT #######################