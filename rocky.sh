#!/bin/bash
######################################################################
### This script will install Greyhole from the official repository ###
### on RHEL-based systems. It has been tested on Rocky Linux 9.    ###
######################################################################


if [[ $EUID -ne 0 ]]; then
	>&2 echo "You need to execute this script using sudo."
	exit 2
fi

set +x
dnf install -y epel-* 
crb enable
dnf install -y heimdal-devel chkconfig initscripts lm_sensors-libs mysql-server  cifs-utils samba-client samba tar wget  perl-Parse-Yapp patch gcc python-devel gnutls-devel make rpcgen perl-CPAN zlib-devel
dnf install -y php-intl php-mysqlnd php bison flex e2fsprogs-devel
echo | cpan install JSON 
mkdir /greyhole
mkdir /greyhole/lz
mkdir /greyhole/drives
semanage fcontext -a -t samba_share_t "/greyhole/lz(/.*)?"
restorecon -Rv /greyhole/
setsebool -P samba_export_all_rw=1
wget  https://github.com/gboudreau/Greyhole/releases/download/0.15.25/greyhole-0.15.25.tar.gz
tar -xf greyhole-0.15.25.tar.gz
cd ./greyhole-0.15.25
GREYHOLE_INSTALL_DIR=$(pwd)
##################################################
### Here I will download the additional assets ###
### that I have created for Rocky Linux        ###
##################################################
echo "Downloading updated files"
set -x
wget https://github.com/aarondyck/GH-installer/releases/download/v0.1.0/greyhole-smb.systemd
wget https://github.com/aarondyck/GH-installer/releases/download/v0.1.0/build_vfs2.sh
set +x
####################################################
### For the most part, this is the normal manual ###
### installation script from the official docs   ###
####################################################

echo "Installing Greyhole"
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
## install -m 0755 -D -p build_vfs.sh /usr/share/greyhole  ### I don't want to use the existing build_vfs file
install -m 0755 -D -p build_vfs2.sh /usr/share/greyhole/build_vfs.sh   ### This is the updated file 
install -m 0644 -D -p docs/greyhole.1.gz /usr/share/man/man1/
install -m 0644 -D -p docs/greyhole-dfree.1.gz /usr/share/man/man1/
install -m 0644 -D -p docs/greyhole.conf.5.gz /usr/share/man/man5/
LIBDIR=/usr/lib
mkdir "$LIBDIR/greyhole"
install -m 0644 -D -p greyhole-smb.systemd /usr/lib/systemd/system/greyhole.service ##This is the updated service file for Rocky Linux
## cp samba-module/bin/$SMB_VERSION/greyhole-$(uname -m).so "$LIBDIR/greyhole/greyhole-samba${SMB_VERSION//.}.so"
## The samba module doesn't exist - we know this. My script will build it automatically and then install it. 

######################################################
### This will build the samba module using DNF     ###
### for RHEL-based Linux systems. This portion of  ###
### the script is based on build_vfs2.sh.          ###
######################################################
echo "Building Samba module"

ceol=$(tput el)

if [[ -z ${GREYHOLE_VFS_BUILD_DIR} ]]; then
	GREYHOLE_VFS_BUILD_DIR="/usr/share/greyhole/vfs-build"
fi

mkdir -p "${GREYHOLE_VFS_BUILD_DIR}"
cd "${GREYHOLE_VFS_BUILD_DIR}"

###

if [[ -f /usr/bin/python2 ]]; then
	alias python='/usr/bin/python2'
fi
	create_symlink=1
	version=$(/usr/sbin/smbd --version | awk '{print $2}' | awk -F'-' '{print $1}')
M=$(echo "${version}" | awk -F'.' '{print $1}') # major
m=$(echo "${version}" | awk -F'.' '{print $2}') # minor
# shellcheck disable=SC2034
B=$(echo "${version}" | awk -F'.' '{print $3}') # build
echo "Your Samba version is ${version}"
echo
echo "Installing build dependencies..."
echo "- Installing build-essential / gcc (etc.)"
dnf -y install patch gcc python-devel gnutls-devel make rpcgen >/dev/null || true
if [[ ${M} -ge 4 ]]; then
    if [[ ${m} -ge 12 ]]; then
        
            dnf -y install perl-CPAN >/dev/null || true
        
        echo "- Installing Parse::Yapp::Driver perl module"
        # shellcheck disable=SC2034
        PERL_MM_USE_DEFAULT=1
        echo | perl -MCPAN -e 'install Parse::Yapp::Driver' >/dev/null
    fi
    if [[ ${m} -ge 13 ]]; then
        echo "- Installing zlib-devel"
            dnf -y install zlib-devel >/dev/null || true
        
    fi
    if [[ ${m} -ge 14 ]]; then
            echo "- Installing bison & flex"
            dnf -y install bison flex >/dev/null || true
            echo "- Installing JSON perl module"
            cpan install JSON >/dev/null 2>&1
    fi
    if [[ ${m} -ge 15 ]]; then
      echo "- Installing e2fsprogs-devel & heimdal-devel"
      dnf -y install e2fsprogs-devel heimdal-devel >/dev/null || true
    fi
fi
echo

echo "Compiling Greyhole VFS module for samba-${version}... "

if [[ -z ${GREYHOLE_INSTALL_DIR} ]]; then
	echo "  Downloading Greyhole source code"
	set +e
	GH_VERSION=$(greyhole --version 2>&1 | grep version | head -1 | awk '{print $3}' | 
 awk -F',' '{print $1}')
	rm -f "greyhole-${GH_VERSION}.tar.gz"
	curl -LOs "https://github.com/gboudreau/Greyhole/releases/download/${GH_VERSION}/greyhole-${GH_VERSION}.tar.gz" 2>&1
	set -e
	if [[ -f "greyhole-${GH_VERSION}.tar.gz" && "${GH_VERSION}" != "%VERSION%" ]]; then
		GREYHOLE_INSTALL_DIR="$(pwd)/greyhole-${GH_VERSION}"
		rm -rf "${GREYHOLE_INSTALL_DIR}"
		tar zxf "greyhole-${GH_VERSION}.tar.gz" && rm -f "greyhole-${GH_VERSION}.tar.gz"
	else
		GREYHOLE_INSTALL_DIR="$(pwd)/Greyhole-master"
		rm -rf "${GREYHOLE_INSTALL_DIR}"
		curl -LOs "https://github.com/gboudreau/Greyhole/archive/master.zip"
		unzip -q master.zip && rm master.zip
	fi
fi

if [[ ! -d samba-${version} ]]; then
	echo "  Downloading Samba source code"
	curl -LOs "http://samba.org/samba/ftp/stable/samba-${version}.tar.gz" && tar zxf "samba-${version}.tar.gz" && rm -f "samba-${version}.tar.gz"
fi

cd "samba-${version}" || true
NEEDS_CONFIGURE=
if [[ ! -f source3/modules/vfs_greyhole.c ]]; then
	NEEDS_CONFIGURE=1
fi
set +e

if ! grep -i vfs_greyhole source3/wscript >/dev/null; then
	NEEDS_CONFIGURE=1
fi
if [[ -f .greyhole_needs_configures ]]; then
	NEEDS_CONFIGURE=1
fi
set -e

rm -f source3/modules/vfs_greyhole.c source3/bin/greyhole.so bin/default/source3/modules/libvfs*greyhole.so
if [[ -f "${GREYHOLE_INSTALL_DIR}/samba-module/vfs_greyhole-samba-${M}.${m}.c" ]]; then
  ln -s "${GREYHOLE_INSTALL_DIR}/samba-module/vfs_greyhole-samba-${M}.${m}.c" source3/modules/vfs_greyhole.c
else
  ln -s "${GREYHOLE_INSTALL_DIR}/samba-module/vfs_greyhole-samba-${M}.x.c" source3/modules/vfs_greyhole.c
fi

if [[ ${M} -eq 3 ]]; then
	cd source3
fi

if [[ "${NEEDS_CONFIGURE}" = "1" ]]; then
	echo "  Running 'configure'"
	touch .greyhole_needs_configures
	set +e
	if [[ ${M} -eq 3 ]]; then
    ./configure >gh_vfs_build.log 2>&1 &
    PROC_ID=$!
  else
    if [[ -f "${GREYHOLE_INSTALL_DIR}/samba-module/wscript-samba-${M}.${m}.patch" ]]; then
      patch -p1 < "${GREYHOLE_INSTALL_DIR}/samba-module/wscript-samba-${M}.${m}.patch" >/dev/null
    else
      patch -p1 < "${GREYHOLE_INSTALL_DIR}/samba-module/wscript-samba-${M}.x.patch" >/dev/null
    fi
    CONF_OPTIONS="--enable-debug --disable-symbol-versions --without-acl-support --without-ldap --without-ads --without-pam --without-ad-dc"
    if [[ ${m} -ge 7 ]]; then
      CONF_OPTIONS=${CONF_OPTIONS}' --disable-python'
    fi
    if [[ ${m} -ge 13 ]]; then
      CONF_OPTIONS=${CONF_OPTIONS}' --with-shared-modules=!vfs_snapper'
    fi
    if [[ ${m} -ge 10 ]]; then
      CONF_OPTIONS=${CONF_OPTIONS}' --without-json --without-libarchive'
    elif [[ ${m} -ge 9 ]]; then
      CONF_OPTIONS=${CONF_OPTIONS}' --without-json-audit --without-libarchive'
    fi
    if [[ ${m} -ge 15 && ! -f /sbin/apk && ! -f /bin/yum ]]; then
      CONF_OPTIONS=${CONF_OPTIONS}' --with-system-heimdalkrb5'
    fi
    if [[ ${m} -ge 21 ]]; then
      CONF_OPTIONS=${CONF_OPTIONS}'  --without-ldb-lmdb'
    fi
    echo "./configure ${CONF_OPTIONS}" > gh_vfs_build.log
    # shellcheck disable=SC2086
    ./configure ${CONF_OPTIONS} >>gh_vfs_build.log 2>&1 &
    PROC_ID=$!
		sleep 15
	fi

	while kill -0 "$PROC_ID" >/dev/null 2>&1; do
		sleep 1
    echo -en "\r${ceol}    Progress: "
    echo -n "$(tail -n 1 gh_vfs_build.log)"
	done
	echo -en "\r${ceol}"
	if ! wait "$PROC_ID"; then
	  echo
	  echo "Configuring Samba failed."
	  echo "Hint : install the required dependencies. See step 3 in https://raw.githubusercontent.com/gboudreau/Greyhole/master/INSTALL"
	  echo
	  echo "cat $(pwd)/gh_vfs_build.log :"
	  cat gh_vfs_build.log
	  exit 4
  fi
  rm -rf .greyhole_needs_configures

	set -e

	if [[ ${M} -eq 3 ]]; then
    patch -p1 < "${GREYHOLE_INSTALL_DIR}/samba-module/Makefile-samba-${M}.${m}.patch" >/dev/null
  fi
fi
echo "  Applying patches (if any)..."
if [[ "${M}.${m}" = "4.11" ]]; then
    curl -sLo "${GREYHOLE_INSTALL_DIR}/smb411-nsstest.patch" "https://gist.githubusercontent.com/gboudreau/778cc1299362cb15a3ea74686cf77794/raw/d578c0a3599cc27d1fe3bc4da015fb4e5aa4652d/smb411-nsstest.patch"
fi
shopt -s nullglob
for f in "${GREYHOLE_INSTALL_DIR}/"*.patch; do
    echo -n "  - "
    patch -p1 -i "$f" || true
done
echo '#include <sys/types.h>' > file.txt
sed -i '/#include <stdbool.h>/r file.txt' -- lib/tevent/tevent.h
rm -f file.txt

echo "  Compiling Samba"
set +e
make -j >gh_vfs_build.log 2>&1 &
PROC_ID=$!
while kill -0 "$PROC_ID" >/dev/null 2>&1; do
	sleep 1
  echo -en "\r${ceol}    Progress: "
  echo -n "$(tail -n 1 gh_vfs_build.log)"
done
echo -en "\r${ceol}"
if ! wait "$PROC_ID"; then
  echo
  echo "Compiling Samba failed."
  echo
  echo "cat $(pwd)/gh_vfs_build.log :"
  cat gh_vfs_build.log
  exit 5
fi
echo

V=$(echo "${version}" | awk -F'.' '{print $1$2}')
GREYHOLE_COMPILED_MODULE="$(pwd)/greyhole-samba${V}.so"
export GREYHOLE_COMPILED_MODULE

if [[ ${M} -eq 3 ]]; then
	COMPILED_MODULE="source3/bin/greyhole.so"
else
	COMPILED_MODULE=$(ls -1 "$(pwd)"/bin/default/source3/modules/libvfs*greyhole.so)
fi

if [[ ! -f ${COMPILED_MODULE} ]]; then
	>&2 echo "Failed to compile Greyhole VFS module."
  echo
  echo "cat $(pwd)/gh_vfs_build.log :"
  cat gh_vfs_build.log
	exit 3
fi

set -e

cp "${COMPILED_MODULE}" "${GREYHOLE_COMPILED_MODULE}"

echo "Greyhole VFS module successfully compiled into ${GREYHOLE_COMPILED_MODULE}"

if [[ ${create_symlink} -eq 1 ]]; then
	echo
  echo "Creating the required symlink in the Samba VFS library folder."
  if [[ -d /usr/lib/x86_64-linux-gnu/samba/vfs ]]; then
    LIBDIR=/usr/lib/x86_64-linux-gnu
  elif [[ -d /usr/lib64/samba/vfs ]]; then
    LIBDIR=/usr/lib64
  elif [[ -d /usr/lib/aarch64-linux-gnu/samba/vfs/ ]]; then
		LIBDIR=/usr/lib/aarch64-linux-gnu
  else
    LIBDIR=/usr/lib
  fi
  rm -f ${LIBDIR}/samba/vfs/greyhole.so
  ln -s "${GREYHOLE_COMPILED_MODULE}" ${LIBDIR}/samba/vfs/greyhole.so
  echo "Done."
  echo
fi



######################################################



