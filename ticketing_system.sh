#!/bin/bash

# YouTube:  https://www.youtube.com/@linuxnetworkinghelp
#
# Please Subscribe ===

useradd -r -d /opt/otrs -c 'OTRS User' otrs
usermod -a -G www-data otrs

cd /opt/
wget https://download.znuny.org/releases/otrs-6.0.9.tar.gz
tar -xzvf otrs-6.0.9.tar.gz
mv otrs-6.0.9 otrs && chown -R otrs:otrs otrs

apt-get update
apt-get install -y nginx fcgiwrap mariadb-client mariadb-server
apt-get install -y libnet-ldap-perl libio-socket-ssl-perl libpdf-api2-perl
apt-get install -y libsoap-lite-perl libgd-text-perl libgd-graph-perl
apt-get install -y libcrypt-ssleay-perl libencode-hanextra-perl libmail-imapclient-perl libtemplate-perl
apt-get install -y libxml-libxml-perl libxml-libxslt-perl libpdf-api2-simple-perl libauthen-ntlm-perl
apt-get install -y libyaml-libyaml-perl libtemplate-perl libcrypt-eksblowfish-perl
apt-get install -y libarchive-zip-perl libdbi-perl libdbd-mysql-perl libnet-dns-perl
apt-get install -y libnet-dns-perl libtext-csv-xs-perl libjson-xs-perl libdatetime-perl

cat <<'EOF' >/etc/mysql/mariadb.conf.d/50-otrs_config.cnf
[mysql]
max_allowed_packet=256M
[mysqldump]
max_allowed_packet=256M

[mysqld]
innodb_file_per_table
innodb_log_file_size = 256M
max_allowed_packet=256M
character-set-server  = utf8
collation-server      = utf8_general_ci
EOF

mysql_secure_installation
service mysql restart

echo "CREATE DATABASE otrs CHARACTER SET utf8;
CREATE USER 'otrs'@'localhost' IDENTIFIED BY 'some-pass';
GRANT ALL PRIVILEGES ON otrs.* TO 'otrs'@'localhost';" 


systemctl enable mariadb nginx fcgiwrap
systemctl start fcgiwrap
chmod 766 /var/run/fcgiwrap.socket

cp /opt/otrs/Kernel/Config.pm.dist /opt/otrs/Kernel/Config.pm
/opt/otrs/bin/otrs.SetPermissions.pl --otrs-user=www-data --web-group=www-data

/opt/otrs/bin/otrs.CheckModules.pl

cd /opt/otrs/var/cron
for foo in *.dist; do cp $foo `basename $foo .dist`; done
/opt/otrs/bin/otrs.SetPermissions.pl --otrs-user=www-data --web-group=www-data
/opt/otrs/bin/Cron.sh start otrs
su -c "/opt/otrs/bin/otrs.Daemon.pl start" -s /bin/bash otrs
su -c "/opt/otrs/bin/otrs.Daemon.pl status" -s /bin/bash otrs



#-=====   http://<server_ip>/otrs/   ===
