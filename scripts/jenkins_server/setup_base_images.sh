#! /bin/bash

make_sles12_raw_image ()
{
/bin/cat > mkimg_sles12.sh <<EOF
#!/bin/bash
mkdir img || exit
mkdir -m 755 img/dev
mknod -m 600 img/dev/console c 5 1
mknod -m 600 img/dev/initctl p
mknod -m 666 img/dev/full c 1 7
mknod -m 666 img/dev/null c 1 3
mknod -m 666 img/dev/ptmx c 5 2
mknod -m 666 img/dev/random c 1 8
mknod -m 666 img/dev/tty c 5 0
mknod -m 666 img/dev/tty0 c 4 0
mknod -m 666 img/dev/urandom c 1 9
mknod -m 666 img/dev/zero c 1 5

test -d /etc/zypp && mkdir -p img/root
test -d /etc/zypp && cp /root/.zypp img/root/.zypp -r
test -d /etc/zypp && zypper --root $PWD/img  -D /etc/zypp/repos.d/ \
--no-gpg-checks -n install -l bash zypper vim
test -d /etc/zypp && cp -a /etc/zypp* /etc/products.d img/etc/

rm -fr img/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
rm -fr img/usr/share/{man,doc,info,gnome/help}
rm -fr img/usr/share/cracklib
rm -fr img/usr/share/i18n
rm -fr img/etc/ld.so.cache
rm -fr img/var/cache/ldconfig/*
EOF
chmod +x mkimg_sles12.sh
sh mkimg_sles12.sh
cd img
tar cf - . | docker import - sles12_raw
cd ..
rm mkimg_sles12.sh
rm -r img
}

make_sles12_base_image ()
{
mkdir sles12_base
cd sles12_base
/bin/cat > Dockerfile <<EOF
# Base image
FROM sles12_raw:latest

# The author
MAINTAINER LoZ Open Source Ecosystem (https://www.ibm.com/developerworks/community/groups/community/lozopensource)

# ssh service set up
RUN zypper install -y openssh && \
	mkdir /var/run/sshd && \
	echo 'root:root123' | chpasswd && \
	sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
	sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile && \
	ssh-keygen -A
#RUN ssh-keygen -q -N '' -t rsa -f /etc/ssh/ssh_host_rsa_key
#RUN ssh-keygen -q -N '' -t dsa -f /etc/ssh/ssh_host_dsa_key

EXPOSE 22

CMD ["/bin/bash"]
EOF
docker build -t sles12 .
cd ..
rm -r sles12_base
}

make_sles12_nodejs_image ()
{
mkdir Node.js
cd Node.js
/bin/cat > Dockerfile <<EOF
# Base image
FROM sles12:latest

# The author
MAINTAINER LoZ Open Source Ecosystem (https://www.ibm.com/developerworks/community/groups/community/lozopensource)

# Install the build dependencies
RUN zypper install -y \
        gcc-c++ \
        git \
        java-1_7_0-openjdk \
        make

# Clone the source code of Node.js from github
# Build and install Node.js
RUN git clone https://github.com/andrewlow/node.git && \
    cd node/ && \
    ./configure && \ 
    make && \
    make install

# Install grunt-cli
CMD ["npm", "install", "-g", "grunt-cli"]
EOF
docker build -t sles12node .
cd ..
rm -r Node.js
}

# Checking if sles12 base image exsits
SLES12_BASE_UP=`docker images | grep '^sles12 '`
if [ "${SLES12_BASE_UP:-null}" = null ] ; then
        echo "Sles12 base images is not built..."
	SLES12_RAW_UP=`docker images | grep '^sles12_raw '`
	if [ "${SLES12_RAW_UP:-null}" = null ] ; then
		echo "Sles12 raw images is not built..."
		make_sles12_raw_image
	fi
	make_sles12_base_image
else
	echo "Good! Sles12 base images is built."
fi

# Checking if sles12 nodejs image exsits
SLES12_NODEJS_UP=`docker images | grep '^sles12node '`
if [ "${SLES12_NODEJS_UP:-null}" = null ] ; then
        echo "Sles12 node.js images is not built..."
        make_sles12_nodejs_image
else
        echo "Good! Sles12 node.js images is built."
fi
