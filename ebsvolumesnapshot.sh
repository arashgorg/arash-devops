#!/bin/bash

export JAVA_HOME=/usr
REGION=us-west-2

VOLUMES_LIST=/tmp/volumes-list.txt
SNAPSHOT_INFO=/tmp/snapshot_info.txt
DATE=`date +%Y-%m-%d`
SNAP_CREATION=/tmp/snap_creation

export CURRENT_TIME_1=`date +"%m.%d.%y"`
export CURRENT_TIME_2=`date`
export TEMP_CURRENT_TIME=(`echo $CURRENT_TIME_1 | tr '.' ' '`)
export MONTH=${TEMP_CURRENT_TIME[0]}
export DAY=${TEMP_CURRENT_TIME[1]}
export YEAR=${TEMP_CURRENT_TIME[2]}
export DAY_OF_WEEK_TEMP=(`echo $CURRENT_TIME_2 | tr ' ' ' '`)
export DAY_WEEK=${DAY_OF_WEEK_TEMP[0]}

if [[ "$DAY" = "01" ]] && [[ "$MONTH" = "01" ]] && [[ "$YEAR" = "01" ]];
then
	SNAP_TYPE="Yearly"
elif [ "$DAY" = "01" ];
then
  	SNAP_TYPE="Monthly"
elif [ "$DAY_WEEK" = "Fri" ];
then
	SNAP_TYPE="Weekly"
else
	SNAP_TYPE="Daily"
fi

echo $SNAP_TYPE

echo "List of Snapshots Creation Status" > $SNAP_CREATION

#Check whether the volumes list file is available or not?

if [ -f $VOLUMES_LIST ];
then

	#Creating Snapshot for each volume using for loop
    	for VOL_INFO in `cat $VOLUMES_LIST`
    	do

		#Getting the Volume ID and Volume Name into the Separate Variables.

      		VOL_ID=`echo $VOL_INFO | awk -F":" '{print $1}'`
      		VOL_NAME=`echo $VOL_INFO | awk -F":" '{print $2}'`

		#Creating the Snapshot of the Volumes with Proper Description.

      		DESCRIPTION="${VOL_NAME}_SNAPSHOT_${DATE}_${SnapType}"
      		aws ec2 create-snapshot --volume-id $VOL_ID --description "$DESCRIPTION" --region $REGION &>> $SNAP_CREATION
    	done
else
   	echo "Volumes list file is not available : $VOLUMES_LIST Exiting."
	AIL_LIST
   	exit 1
fi

echo >> $SNAP_CREATION
echo >> $SNAP_CREATION

