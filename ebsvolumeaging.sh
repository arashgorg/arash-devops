#!/bin/bash

export JAVA_HOME=/usr
REGION=us-west-2
SNAP_DELETION=/tmp/snap_deletion
VOLUMES_LIST=/tmp/volumes-list.txt

#Retrieve the aging values from config file
AGING_LIST=`cat aging-list.txt`
DAILY_MAX=`echo $AGING_LIST| awk '{print $1}' | awk -F":" '{print $2}'`
WEEKLY_MAX=`echo $AGING_LIST| awk '{print $2}' | awk -F":" '{print $2}'`
MONTHLY_MAX=`echo $AGING_LIST| awk '{print $3}' | awk -F":" '{print $2}'`
YEARLY_MAX=`echo $AGING_LIST| awk '{print $4}' | awk -F":" '{print $2}'`

#Counter used
Count=0
DAILY=0
WEEKLY=0
MONTHLY=0
YEARLY=0
DELETE_FLAG=0

for VOL_INFO in `cat $VOLUMES_LIST`
do
	Count=`expr $Count + 1`

	#Getting the Volume ID and Volume Name into the Separate Variables.
   	VOL_ID=`echo $VOL_INFO | awk -F":" '{print $1}'`
   	VOL_NAME=`echo $VOL_INFO | awk -F":" '{print $2}'`
	
	echo ""
	echo $Count
	echo $VOL_ID
	echo $VOL_NAME
		
	#Getting the Snapshot details of each volume.
	aws --region $REGION ec2 describe-snapshots --query Snapshots[*].[SnapshotId,VolumeId,Description,StartTime] --output text --filters "Name=status,Values=completed" "Name=volume-id,Values=$VOL_ID" > "$Count.txt"

	#Snapshots Retention Period Checking and if it crosses delete them.
    	while read SNAP_INFO
    	do
       		SNAP_ID=`echo $SNAP_INFO | awk '{print $1}'`
       		SNAP_DATE=`echo $SNAP_INFO | awk '{print $4}' | awk -F"T" '{print $1}'`
       		SNAP_TYPE_TEMP=`echo $SNAP_INFO | awk '{print $3}'`
       		SNAP_TYPE=`echo $SNAP_TYPE_TEMP | awk -F"_" '{print $4}'`
      
		#Increment the type counter - if type counter surpases the max allowed, set the delete flag
		if [ "$SNAP_TYPE" = "Daily" ];
		then
			DAILY=`expr $DAILY + 1`
			
			if [ $DAILY -gt $DAILY_MAX ];
			then
				DELETE_FLAG=1
			fi
			
		elif [ "$SNAP_TYPE" = "Weekly" ];
		then
  			WEEKLY=`expr $WEEKLY + 1`
  			
  			if [ $WEEKLY -gt $WEEKLY_MAX ];
			then
				DELETE_FLAG=1
			fi
		elif [ "$SNAP_TYPE" = "Monthly" ];
		then
			MONTHLY=`expr $MONTHLY + 1`
			
			if [ $MONTHLY -gt $MONTHLY_MAX ];
			then
				DELETE_FLAG=1
			fi
		elif [ "$SNAP_TYPE" = "Yearly" ];
		then
			YEARLY=`expr $YEARLY + 1`
			
			if [ $YEARLY -gt $YEARLY_MAX ];
			then
				DELETE_FLAG=1
			fi
		else
			#echo "no tag"
		fi
		
		#If delete flag is set, delete the oldest snapshot
		if [ "$DELETE_FLAG" = "1" ];
		then
			aws ec2 delete-snapshot --snapshot-id $SNAP_ID --region $REGION --output text> /tmp/snap_del
       			echo DELETING $SNAP_INFO >> $SNAP_DELETION			
			DELETE_FLAG=0
		fi

     	done < "$Count.txt"
done

echo >> $SNAP_DELETION


