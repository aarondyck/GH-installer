######################################################################
### This script will install Greyhole from the official repository ###
### on RHEL-based systems. It has been tested on Rocky Linux 9.    ###
######################################################################

#!/bin/bash

set -x
dnf install -y epel-*
crb enable
dnf install -y heimdal-devel chkconfig initscripts lm_sensors-libs mysql-server php-mysqlnd cifs-utils samba-client samba tar wget php perl-Parse-Yapp
mkdir /greyhole
mkdir /greyhole/lz
mkdir /greyhole/drives
mkdir /greyhole/drives/drive01
mkdir /greyhole/drives/drive02
semanage fcontext -a -t samba_share_t "/greyhole/lz(/.*)?"
restorecon -Rv /greyhole/
setsebool -P samba_export_all_rw=1
wget  https://github.com/aarondyck/Greyhole/releases/download/greyhole-rocky_v0.16.00.00/greyhole-rocky_v0.16.00.00.tar.gz
tar -xf greyhole-rocky_v0.16.00.00.tar.gz
cd ./Greyhole-greyhole-rocky_v0.16.00.00
mkdir ./updates
GREYHOLE_INSTALL_DIR=`pwd`
mkdir -p /var/spool/greyhole
mkdir -p /var/spool/greyhole
chmod 777 /var/spool/greyhole
mkdir -p /usr/share/greyhole
install -m 0755 -D -p greyhole /usr/bin
install -m 0755 -D -p greyhole-dfree /usr/bin
install -m 0755 -D -p greyhole-php /usr/bin
install -m 0755 -D -p greyhole-dfree.php /usr/share/greyhole
install -m 0644 -D -p schema-mysql.sql /usr/share/greyhole
install -m 0644 -D -p greyhole.example.conf /usr/share/greyhole
install -m 0644 -D -p greyhole.example.conf /etc/greyhole.conf
install -m 0644 -D -p logrotate.greyhole /etc/logrotate.d/greyhole
install -m 0644 -D -p greyhole.cron.d /etc/cron.d/greyhole
install -m 0755 -D -p greyhole.cron.weekly /etc/cron.weekly/greyhole
install -m 0755 -D -p greyhole.cron.daily /etc/cron.daily/greyhole
cp -r web-app /usr/share/greyhole/web-app
install -m 0755 -D -p scripts-examples/greyhole_file_changed.sh /usr/share/greyhole/scripts-examples
install -m 0755 -D -p scripts-examples/greyhole_idle.sh /usr/share/greyhole/scripts-examples
install -m 0755 -D -p scripts-examples/greyhole_notify_error.sh /usr/share/greyhole/scripts-examples
install -m 0755 -D -p scripts-examples/greyhole_send_fsck_report.sh /usr/share/greyhole/scripts-examples
install -m 0755 -D -p scripts-examples/greyhole_sysadmin_notification.sh /usr/share/greyhole/scripts-examples
install -m 0644 -D -p USAGE /usr/share/greyhole
## install -m 0755 -D -p build_vfs.sh /usr/share/greyhole

install -m 0644 -D -p docs/greyhole.1.gz /usr/share/man/man1/
install -m 0644 -D -p docs/greyhole-dfree.1.gz /usr/share/man/man1/
install -m 0644 -D -p docs/greyhole.conf.5.gz /usr/share/man/man5/
LIBDIR=/usr/lib
mkdir "$LIBDIR/greyhole"
cp samba-module/bin/$SMB_VERSION/greyhole-$(uname -m).so "$LIBDIR/greyhole/greyhole-samba${SMB_VERSION//.}.so"
install -m 0644 -D -p greyhole-smb.systemd /usr/lib/systemd/system/greyhole.service
