#!/bin/bash
#Script Final Setup for HA Hadoop installtion
#Author: Vinod.N K
#Usage: Hadoop Zookeeper JDK8
#Distro : Linux -Centos, Rhel, and any fedora
#Check whether hduser user is running the script
while [ $USER  != "hduser" ]
do
        echo "Please login with hduser" 1>&2
        exit 1
done

#Passwordless SSH Configuration before that you  need to add all the server of this cluster and master in one file along with user like below...
# location of file /tmp/destfile
# hduser@public_ip
# hduser@public_ip and so on... 
#
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config && sudo /etc/init.d/sshd restart
sudo mkdir /home/hduser/.ssh
sudo chmod -R 700 /home/hduser/.ssh/
sudo chown -R hduser:hadoop /home/hduser/.ssh/
ssh-keygen -t rsa
cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys
chmod 600 /home/hduser/.ssh/authorized_keys

for dest in $(</tmp/destfile); do
ssh-copy-id -i /home/hduser/.ssh/id_rsa.pub  ${dest}
done 

#Checking whether Java8 Installed or Install.. 
echo "Checing if JDK8 is installed in /apps " 
java_present="`ls /apps | grep java8 | grep -v grep | wc -l`"
  if [ "$java_present" == "1" ]; then
       	echo -e "\n Java already present No need to install .. "
  else
      
      echo -e "\n Please refer my previous scripts.." && exit

  fi

#Checking whether Zookeeper Installed or Install.. 
echo "Lets check weather Zookeeper is running or not"
zoo_present="`ls /apps | grep zookeeper | grep -v grep | wc -l`"
  if [ "$zoo_present" == "1" ]; then
       	echo -e "\n Zookeeper already present No need to install .. "
  else
      
      echo -e "\n Please refer my previous zookeeper install scripts.." && exit

  fi

#Hadoop configration starts from here after checking all needed dependencies...  
cd /apps
sudo wget http://redrockdigimark.com/apachemirror/hadoop/common/hadoop-2.6.5/hadoop-2.6.5.tar.gz

tar -zxvf hadoop-2.6.5.tar.gz
mv hadoop-2.6.5 hadoop
chown -R hduser:hadoop hadoop
mkdir -p /apps/hadoop/data/namenode
mkdir -p /apps/hadoop/data/datanode
chown -R huser:hadoop /apps/hadoop/data

# setting hadoop envirnoment.
echo '#Hadoop Path Setting
export HADOOP_PREFIX=/apps/hadoop
export HADOOP_MAPRED_HOME=$HADOOP_PREFIX
export HADOOP_COMMON_HOME=$HADOOP_PREFIX
export HADOOP_HDFS_HOME=$HADOOP_PREFIX
export YARN_HOME=$HADOOP_PREFIX
export HADOOP_HOME=$HADOOP_PREFIX
export HADOOP_CONF_DIR=/apps/hadoop/etc/hadoop
export PATH=$PATH:$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin
' >> /etc/profile.d/hadoop.sh

#Lets configure now..
sed -i 's/export JAVA_HOME=${JAVA_HOME}/export JAVA_HOME=\/apps\/java8/g' $HADOOP_CONF_DIR/hadoop-env.sh
echo "export HADOOP_LOG_DIR=/apps/hadoop/logs" >> $HADOOP_CONF_DIR/hadoop-env.sh

sed -i '/\(<\/configuration>\)/d' $HADOOP_CONF_DIR/core-site.xml
echo " <property>
  <name>fs.default.name</name>
  <value>hdfs://auto-ha</value>
 </property>
</configuration>" >> /apps/hadoop/etc/hadoop/core-site.xml

sed -i '/\(<\/configuration>\)/d' hdfs-site.xml
echo "<property>
  <name>dfs.replication</name>
  <value>2</value>
 </property>
 <property>
  <name>dfs.name.dir</name>
  <value>file:///apps/hadoop/data/namenode</value>
 </property>
 <property>
  <name>dfs.data.dir</name>
  <value>file:///apps/hadoop/data/datanode</value>
 </property>
 <property>
  <name>dfs.permissions</name>
  <value>false</value>
 </property>
 <property>
  <name>dfs.nameservices</name>
  <value>auto-ha</value>
 </property>
 <property>
  <name>dfs.ha.namenodes.auto-ha</name>
  <value>nn01,nn02</value>
 </property>
 <property>
  <name>dfs.namenode.rpc-address.auto-ha.nn01</name>
  <value>ha-nn01:8020</value>
 </property>
 <property>
  <name>dfs.namenode.http-address.auto-ha.nn01</name>
  <value>ha-nn01:50070</value>
 </property>
 <property>
  <name>dfs.namenode.rpc-address.auto-ha.nn02</name>
  <value>ha-nn02:8020</value>
 </property>
 <property>
  <name>dfs.namenode.http-address.auto-ha.nn02</name>
  <value>ha-nn02:50070</value>
 </property>
 <property>
  <name>dfs.namenode.shared.edits.dir</name>
  <value>file:///mnt/</value>
 </property>
 <property>
  <name>dfs.ha.fencing.methods</name>
  <value>sshfence</value>
 </property>
 <property>
  <name>dfs.ha.fencing.ssh.private-key-files</name>
  <value>/home/hduser/.ssh/id_rsa</value>
 </property>
 <property>
  <name>dfs.ha.automatic-failover.enabled.auto-ha</name>
  <value>true</value>
 </property>
 <property>
   <name>ha.zookeeper.quorum</name>
   <value>ha-nn01.hadoop.lab:2181,ha-nn02.hadoop.lab:2181,ha-nn03.hadoop.lab:2181</value>
 </property>
</configuration>" >> $HADOOP_CONF_DIR/hdfs-site.xml

echo "ha-dn01
ha-dn02" | tee  $HADOOP_CONF_DIR/slaves

#Now lets tarball of whole setup to other server ..

cd /tmp
sudo tar -zxvf apps.tar.gz /apps

echo "Now Your whole setup is ready just copy /tmp/apps.tar.gz to all server "
echo -e "Thanks for using haddop multi node cluster with zookeeper"

