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
answer=yes
while [ "$answer" = yes ]
do
echo "Lets begin to add namenode and datanode to hosts files"
read -p "Please enter IP Address (Private)? :" ip_address
read -p "Enter Public domain or Host name? :" host_name
read -p "Enter the hostname of $ip_address? :" hostna

matches_in_hosts="$(grep -n $host_name /etc/hosts | cut -f1 -d:)"
host_entry="$ip_address $hostna $host_name"
echo "Please enter your password if requested."

if [[ $matches_in_hosts -ge 1 ]];then
    echo "Host present in hostfile"
else
    echo "Adding new hosts entry."
    echo "$host_entry" >> /etc/hosts
fi
read -p "Do you want to add more hosts in hostsfile (Yes/No)? :" answer
if [[ $answer =~ ^([nN][oO]|[nN])$ ]]; then
        echo -e "\nMoving on !!"
  else
        if [[ $answer =~ ^([yY][eE][sS]|[yY])$ ]]
        then
        echo "run the script again"
        fi
  fi
done

#Setting up ulimit to max

sed -i '/# End of file/d' /etc/security/limits.conf

echo "*          soft     core          unlimited
*          hard     core          unlimited
*          soft     nproc          65535
*          hard     nproc          65535
*          soft     nofile         65535
*          hard     nofile         65535
# End of file" >> /etc/security/limits.conf
echo "*          soft     core          unlimited
*          hard     core          unlimited
*          soft     nproc          65535
*          hard     nproc          65535
*          soft     nofile         65535
*          hard     nofile         65535" >> /etc/security/limits.d/90-nproc.conf
sudo sysctl -w fs.file-max=6816768
sudo sysctl -p

#Adding User

read -p "Please Enter the Groupname ? :" group
group_present="`cat /etc/passwd | grep $group | grep -v grep | wc -l`"
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
echo "Thanks for using all worked properly & now please reboot for changes to take place..."
