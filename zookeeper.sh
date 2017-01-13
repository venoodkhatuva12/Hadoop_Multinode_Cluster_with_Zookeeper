#!/bin/bash
#Script for zookeeper for HA Hadoop installtion
#Author: Vinod.N K
#Usage: Hadoop Zookeeper JDK8
#Distro : Linux -Centos, Rhel, and any fedora
#Check whether hduser user is running the script
while [ $USER  != "hduser" ]
do
        echo "Please login with hduser" 1>&2
        exit 1
done
echo "Installtion of hadoop with HA Zookeeper Starting"

sudo mkdir /apps && sudo chown -R hduser:hadoop /apps
cd /apps/
sudo wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u111-b14/jdk-8u111-linux-x64.tar.gz"
sudo tar zxvf jdk-8u111-linux-x64.tar.gz && sudo mv jdk1.8.0_111 java8
sudo alternatives --install /usr/bin/java java /apps/java8/bin/java 1
sudo alternatives --config java
sudo alternatives --install /usr/bin/jar jar /apps/java8/bin/jar 1
sudo alternatives --install /usr/bin/javac javac /apps/java8/bin/javac 1
sudo alternatives --set jar /apps/java8/bin/jar
sudo alternatives --set javac /apps/java8/bin/javac
sudo /apps/java8/bin/java -version
sudo java -version
sudo chown -R hduser:hadoop /apps/java8
rm -rf /apps/jdk-8u111-linux-x64.tar.gz

sudo chown hduser:hadoop /etc/profile.d/
sudo echo '#JAVA Path Setting
export JAVA_HOME=/apps/java8
export JRE_HOME=/apps/java8/jre
export PATH=$PATH:$JAVA_HOME/bin/java8:$JRE_HOME/bin
#Zookeeper Path Setting
export ZOOKEEPER_HOME=/apps/zookeeper
export PATH=$PATH:/apps/zookeeper/bin' >> /etc/profile.d/hadoop_path.sh
sudo chmod 755 /etc/profile.d/hadoop_path.sh
source /etc/profile.d/hadoop_path.sh

#Zookeeper Setup starts here
echo "Starting Zookeeper setup & configuration..."
cd /apps
wget http://apache.cs.utah.edu/zookeeper/stable/zookeeper-3.4.9.tar.gz
sudo tar zxvf zookeeper-3.4.9.tar.gz && sudo mv /apps/zookeeper-3.4.9 /apps/zookeeper
sudo chown -R hduser:hadoop /apps/zookeeper

echo "Lets configure Zookeeper setting and add some server in Zookeeper Quorum"
read -p "what is the data directory where the snapshot is stored? : " data_dir
read -p "What is the public or hostname of 1st server for zookeeper quorum? :" server1
read -p "What is the public or hostname of 2nd server for zookeeper quorum? :" server2
read -p "What is the public or hostname of 3rd server for zookeeper quorum? :" server3

sudo echo "tickTime=2000
dataDir=$data_dir
clientPort=2181
initLimit=5
syncLimit=2
server.1=$server1:2888:3888
server.2=$server2:2888:3888
server.3=$server3:2888:3888" >> /apps/zookeeper/conf/zoo.cfg
sudo mkdir $data_dir
read -p "what is the server id? :" srvid
sudo chmod -R 777 $data_dir
sudo echo "$srvid" >> $data_dir/myid
sudo rm -rf /apps/zookeeper-3.4.9.tar.gz

zkServer.sh start
sudo chown -R hduser:hadoop /apps && sudo chmod -R 755 /apps
