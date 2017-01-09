#!/bin/bash
#Script for initial requirement for HA Hadoop installtion
#Author: Vinod.N K
#Usage: Hadoop Zookeeper JDK8
#Distro : Linux -Centos, Rhel, and any fedora
#Check whether root user is running the script
  if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
  fi
#setting up hostaname
sed --in-place '/HOSTNAME/d' /etc/sysconfig/network
read -p "Please enter the hostname? :" hostname
sed -i "2 i HOSTNAME=$hostname" /etc/sysconfig/network

# insert/update hosts entry
read -p "Please enter IP Address (Private)? :" ip_address
read -p "Please enter Public domain or host name? :" host_name

# find existing instances in the host file and save the line numbers
matches_in_hosts="$(grep -n $host_name /etc/hosts | cut -f1 -d:)"
host_entry="$ip_address  $hostname    $host_name"
echo "Please enter your password if requested."

if [ ! -z "$matches_in_hosts" ]
then
    echo "Updating existing hosts entry."
    # iterate over the line numbers on which matches were found
    while read -r line_number; do
        # replace the text of each line with the desired host entry
        sudo sed -i '' "${line_number}s/.*/${host_entry} /" /etc/hosts
    done <<< "$matches_in_hosts"
else
    echo "Adding new hosts entry."
    echo "$host_entry" | sudo tee -a /etc/hosts > /dev/null
fi

#Setting up ulimit to max
sed -i /# End of file/d /etc/security/limits.conf
echo "*          soft     core          unlimited
*          hard     core          unlimited
*          soft     nproc          65535
*          hard     nproc          65535
*          soft     nofile         65535
*          hard     nofile         65535
# End of file" >> /etc/security/limits.conf
echo "*          soft     core          unlimited
*          hard     core          unlimited
*          soft     nproc          65535
*          hard     nproc          65535
*          soft     nofile         65535
*          hard     nofile         65535" >> /etc/security/limits.d/90-nproc.conf
sudo sysctl -w fs.file-max=6816768
sudo sysctl -p

#Adding User

read -p "Please Enter the Groupname ? :" group
  if [ "$group_present" == "1" ]; then
       	echo -e "\nGroup $group already present No need to create .. "
       	echo -e "\nGenertaing keys for $user ... "
  else
       	groupadd $group
  fi
read -p "Please Enter the Username :" user
user_present="`cat /etc/passwd | grep $user | grep -v grep | wc -l`"
  if [ "$user_present" == "1" ]; then
       	echo -e "\nUser $user already present No need to create .. "
       	echo -e "\nGenertaing keys for $user ... "
  else
       	adduser $user -G $group
  fi
passwd $user
mkdir /home/$user/.ssh
chmod -R 700 /home/$user/.ssh/
chown -R $user:$group /home/$user/.ssh/

ssh-keygen -b 2048 -f $user -t rsa -v
cat $user.pub >> /home/$user/.ssh/authorized_keys
chmod -R 600 /home/$user/.ssh/authorized_keys
chown -R $user:$group /home/$user/.ssh/
mv $user /home/$user/.ssh/
mv $user.pub /home/$user/.ssh/
read -p "Do you want to add this User to Sudoer(Yes/No)? : " response
sudoers_present="`cat /etc/sudoers | grep $user | grep -v grep | wc -l`"
  if [ "$sudoers_present" -ge "1" ]; then
       	echo -e "\nEntry for user in sudoers already exsist !!"
  else
       	if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
       	then
       	   sudo sed -i "95 i $user   ALL=(ALL)       ALL" /etc/sudoers
       	else
       	    exit
       	fi
  fi
