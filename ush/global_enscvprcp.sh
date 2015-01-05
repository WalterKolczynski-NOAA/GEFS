######################### CALLED BY EXENSCQPF ##########################
echo "------------------------------------------------"
echo "Ensemble CQPF -> global_enscvprcp.sh            "
echo "------------------------------------------------"
echo "History: Feb 2004 - First implementation of this new script."
echo "AUTHOR: Yuejian Zhu (wx20yz)"
echo "History: Nov 2014 - Grib2 code conversion."
echo "AUTHOR: Yan Luo (wx22lu)"

### gribin -- input grib file
### indexin -- input grib index file
### gribout -- output grib file

#$GBINDX $1 $2

echo "&namin"       >input
echo "cpgb='$1',cpge='$2',ini=0,ipr=24,isp=24,itu=12"  >>input
echo "/"        >>input

cat input

export pgm=global_enscvprcp
. prep_step

startmsg

$EXECgefs/global_enscvprcp  <input  >> $pgmout 2>errfile
#export err=$?;err_chk

rm input
