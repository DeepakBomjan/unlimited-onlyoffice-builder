#!/bin/bash

export PRODUCT_VERSION="$1"
export BUILD_NUMBER="$2"
BUILDER_HOME=/root

## Prepare build environment
export TZ=Etc/UTC
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
apt-get -y update && \
    apt-get -y install python \
                       python3 \
                       sudo
rm /usr/bin/python && ln -s /usr/bin/python2 /usr/bin/python


echo "Building docserver..."

git clone https://github.com/ONLYOFFICE/document-server-package.git

git clone https://github.com/ONLYOFFICE/build_tools.git

cd ${BUILDER_HOME}/document-server-package/
cat << EOF >> Makefile

deb_dependencies: \$(DEB_DEPS)

EOF

make deb_dependencies

cd ${BUILDER_HOME}/document-server-package/deb/build/

apt-get -qq build-dep -y ./

cd ${BUILDER_HOME}/document-server-package

make deb



## Apply patch
echo "Applying patches..."
cd ${BUILDER_HOME}/build_tools
git apply ${BUILDER_HOME}/patches/build_tools.patch

cd ${BUILDER_HOME}/document-server-package

## Starting building
echo "Building..."
cd ${BUILDER_HOME}/build_tools/tools/linux
python3 ./automate.py server --branch=tags/${PRODUCT_VERSION}.${BUILD_NUMBER}



