#!/bin/bash

export JAVA_HOME=/usr
REGION=us-west-2

CF_LIST=cflist.txt

#Check whether the CF list file is available or not?
if [ -f $CF_LIST ];
then
    	for CF_INFO in `cat $CF_LIST`
    	do
		echo "LAUNCHING: $CF_INFO"
		CF_NAME_TRIM=`echo $CF_INFO | awk -F"." '{print $1}'`


		if [ $CF_NAME_TRIM = "aws-exe-cf" ];
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
      		fi
	done
else
   	echo "CF list file is not available : $CF_LIST Exiting."
   	exit 1
fi


# aws cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name AWS-EXE-VPC --template-body file://create-aws-exe-vpc.template
# Elastic IP: 52.26.65.199
# Root Device: /dev/xvda
# Volume ID vol: vol-8bfe0c7c
# Delete All dG

# aws s3 cp s3://cf-templates-4cmmx6wny0hn-us-west-2/salt/IMAG0125.jpg /var/www/html/football.jpg
# ami-08bfac69

#apt-get install rsync

# aws ec2 detach-volume --volume-id vol-6a58a49d
# aws ec2 create-snapshot --volume-id vol-6a58a49d
# aws ec2 create-volume --availability-zone us-west-2a --size 1 --snapshot snap-cc01329d --volume-type gp2

# aws ec2 describe-images --image-id ami-6989a659

# aws ec2 create-volume --size 1 --region us-west-2 --availability-zone us-west-2a --volume-type standard

# aws ec2 attach-volume --volume-id vol-5041bda7 --instance-id i-a8a2ef6c --device /dev/sdf

# aws ec2 attach-volume --volume-id vol-17b44be0 --instance-id i-a8a2ef6c --device /dev/sdh

# aws ec2 describe-volumes --volume-id vol-7f946b88

# volume that is root originally: vol-6a58a49d

# lsblk    df - h    see what's mounted

# mkfs -t ext3 /dev/xvdf   (create file system)
#echo "/dev/xvdf /newone ext3 noatime 0 0" >> /etc/fstab   (entry for mounts)
#mkdir /newone
#mount /newone
#sudo rsync -aHAXxSP / /newone

#/dev/xvdf /newone ext3 noatime 0 0 (/newone/etc/fstab)

#to attach root device use /dev/xvda   (not /dev/sda)

#df -T   (what file system in use)


#e2fsck -f /dev/xvda1

#SESSSION
#EIP: 52.27.74.88
#df -T: ext4
# Root device main original: vol-89e8117e
# 1G Volume: vol-4bbe47bc
# Snapshot of root:       new volume of root: 

#echo "/dev/xvdf /MyRoot ext4 defaults 1 1" >> /etc/fstab
#echo "/dev/xvdg /MyNew ext4 noatime 0 0" >> /etc/fstab
#rsync -aHAXxSP /MyRoot /MyNew


#resize2fs -M -p /dev/xvdg1

#aws cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name saltmaster3 --template-body file://saltmaster3.template
#aws cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name TEST2 --template-body file://test2.template
#aws cloudformation create-stack --capabilities CAPABILITY_IAM --stack-name MAIN --template-body file://aws-exe-cf-min.template