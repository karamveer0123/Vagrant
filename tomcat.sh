#!/bin/bash
echo "===============updating the OS====================="
#dnf update -y
echo "=====================Installing Auto Completion====================="
dnf install bash-completion -y
echo "=====================Installing Java====================="
dnf -y install java-11-openjdk java-11-openjdk-devel
cat > /etc/profile.d/java.sh <<'EOF'
export JAVA_HOME=$(dirname $(dirname $(readlink $(readlink $(which java)))))
export PATH=$PATH:$JAVA_HOME/bin
EOF
source /etc/profile.d/java.sh
java --version
echo "=====================Installing Git and maven====================="
dnf install git -y

dnf install maven -y

echo "=====================Installing memcached====================="
dnf install memcached -y
systemctl start memcached
sudo systemctl enable memcached
sudo systemctl status memcached
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached
systemctl restart memcached

echo "=====================Installing RabbitMQ====================="
dnf -y install centos-release-rabbitmq-38
 sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/CentOS-Messaging-rabbitmq.repo
dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server
systemctl enable --now rabbitmq-server
rabbitmqctl add_user admin admin@123
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
rabbitmq-plugins enable rabbitmq_management

echo "=====================Installing Tomcat====================="
echo "=====================Downloading Package====================="
curl -O https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.93/bin/apache-tomcat-9.0.93.tar.gz
echo "=====================Extracting the Dwonloaded Package====================="
tar zxvf apache-tomcat-9.0.93.tar.gz

echo "=====================Moving package to /usr/libexec/tomcat9====================="
mv apache-tomcat-9.0.93 /usr/libexec/tomcat9

echo "=====================addming tomcat user ====================="
useradd -M -d /usr/libexec/tomcat9 tomcat

echo "=====================assigning the permission====================="
chown -R tomcat. /usr/libexec/tomcat9

echo "=====================Creating tomcat9.service file====================="
cat > /usr/lib/systemd/system/tomcat9.service <<'EOF'
[Unit]
Description=Apache Tomcat 9
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/libexec/tomcat9/bin/startup.sh
ExecStop=/usr/libexec/tomcat9/bin/shutdown.sh
RemainAfterExit=yes
User=tomcat
Group=tomcat

[Install]
WantedBy=multi-user.target
EOF

echo "=====================Disabling SELINUX====================="
sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config
setenforce 0

echo "=====================starting tomcat and enabling it ====================="
systemctl enable --now tomcat9
systemctl stop tomcat9

git clone https://github.com/hkhcoder/vprofile-project.git
cd vprofile-project/
mvn install
rm -rvf /usr/libexec/tomcat9/webapps/ROOT*
cp target/vprofile-v2.war /usr/libexec/tomcat9/webapps/ROOT.war
systemctl start tomcat9.service
