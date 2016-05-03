#! /bin/bash

install_docker_compose ()
{
zypper install -y git libxslt-devel libxml2-devel python-setuptools libpipeline-devel python-lxml python-xml
easy_install pip
mkdir docker-compose
cd docker-compose
git clone --branch 1.5.2 https://github.com/docker/compose.git
cd compose
pip install -r requirements.txt
pip install -r requirements-dev.txt
python setup.py install
cd ../..
rm -r docker-compose
}

# Checking if docker daemon is running
DOCKER_RUNNING=`ps aux | grep -v grep | grep 'docker daemon'`
if [ "${DOCKER_RUNNING:-null}" = null ] ; then 
	echo "Docker is not running..."
	if [ ! -x /usr/bin/docker  ] ; then
		wget ftp://ftp.unicamp.br/pub/linuxpatch/s390x/suse/sles12/docker/docker-1.9.1-sles12-20151127.tar.gz
		tar -xvzf docker-1.9.1-sles12-20151127.tar.gz
		cp ./docker-1.9.1-sles12-20151127/docker /usr/bin
	fi
	docker daemon -g ${DOCKER_DAEMON_DIRECTORY} --insecure-registry ${REGISTRY}:${REGISTRY_PORT} -H tcp://0.0.0.0:4243 -H unix:///var/run/docker.sock &
	disown
else
	echo "Good! Docker daemon is running."
fi

# Checking if docker-compose is installed
if [ ! -x /usr/bin/docker-compose ] ; then
	echo "Docker-compose is not installed, install now..."
	install_docker_compose
else
	echo "Good! Docker-compose is installed."
fi 
