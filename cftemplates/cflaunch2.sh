#!/bin/bash

export JAVA_HOME=/usr
REGION=us-west-2

CF_LIST=cflist2.txt

#Check whether the CF list file is available or not?
if [ -f $CF_LIST ];
then
    	for CF_INFO in `cat $CF_LIST`
    	do
		echo "LAUNCHING: $CF_INFO"
		CF_NAME_TRIM=`echo $CF_INFO | awk -F"." '{print $1}'`


		if [ $CF_NAME_TRIM = "saltmaster2" ]
		then
			#Creating the stack
      			aws cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name $CF_NAME_TRIM --template-body file://$CF_INFO
      			
      			echo "	Wait 50s"
      			sleep 50
      			MASTER_PUBLIC_IP=`aws ec2 describe-instances --query "Reservations[*].Instances[*].PublicIpAddress" --output text`
      			echo "  MASTER PUBLIC IP: $MASTER_PUBLIC_IP"
      			
      			echo "  Wait 40s"
      			sleep 40
      			
      			PRIVATE_IP=`aws ec2 describe-instances --query "Reservations[*].Instances[*].PrivateIpAddress" --output text`
      			
      			
			
      		else
      			aws cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name $CF_NAME_TRIM --template-body file://$CF_INFO --parameters '[{"ParameterKey":"PrivateCustomIP","ParameterValue":"'$PRIVATE_IP'"}]'
      			
      			echo "	Wait 70s"
      			sleep 70
      			
      			MINION_PUBLIC_IP=`aws ec2 describe-instances --query "Reservations[*].Instances[*].PublicIpAddress" --output text`
      			echo "  MINION PUBLIC IP: $MINION_PUBLIC_IP"
		fi
		
    	done
else
   	echo "CF list file is not available : $CF_LIST Exiting."
   	exit 1
fi
