#! /bin/ksh

echo "$(date -u) begin ${.sh.file}"

set -xa
if [[ ${STRICT:-NO} == "YES" ]]; then
	# Turn on strict bash error checking
	set -eu
fi

export HOMEgfs=${HOMEgfs:-${HOMEgefs}}
export USHgfs=$HOMEgfs/ush
export FIXgfs=$HOMEgfs/fix
export FIXfv3=${FIXfv3:-$FIXgfs/fix_fv3_gmted2010}

cd $DATA
rm -rf mpmd_cmdfile*
for mem in $memberlist; do
	mkdir -p $GESOUT/init/$mem
	mkdir -p $COMOUT/init/$mem
	echo "$USHgefs/gefs_atmos_prep.sh $mem" >> mpmd_cmdfile
done

chmod 755 mpmd_cmdfile
export MP_HOLDTIME=1000

export MP_CMDFILE=mpmd_cmdfile
export SCR_CMDFILE=$MP_CMDFILE  # Used by mpiserial on Theia
export MP_LABELIO=yes
export MP_INFOLEVEL=3
export MP_STDOUTMODE=unordered
export MP_PGMMODEL=mpmd

#############################################################
$APRUN_MPMD
export err=$?
if [[ $err != 0 ]]; then
	echo "FATAL ERROR in ${.sh.file}: One or more atmos_prep jobs in $MP_CMDFILE failed!"
	exit $err
fi
#############################################################

echo "$(date -u) end ${.sh.file}"

exit $err