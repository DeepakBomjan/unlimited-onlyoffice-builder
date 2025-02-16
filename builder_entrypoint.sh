#!/bin/bash

export PRODUCT_VERSION="$1"
export BUILD_NUMBER="$2"
BUILDER_HOME=/root

## Prepare build environment
export TZ=Etc/UTC
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

echo "Updating system and installing dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    make \
    sudo \
    build-essential \
    apt-utils \
    fakeroot \
    devscripts \
    equivs



# Ensure python symlink exists
ln -sf /usr/bin/python3 /usr/bin/python

echo "Building docserver..."

# Clone required repositories
if [ ! -d "${BUILDER_HOME}/document-server-package" ]; then
    git clone https://github.com/ONLYOFFICE/document-server-package.git ${BUILDER_HOME}/document-server-package
else
    echo "document-server-package already exists, skipping clone."
fi

if [ ! -d "${BUILDER_HOME}/build_tools" ]; then
    git clone https://github.com/ONLYOFFICE/build_tools.git ${BUILDER_HOME}/build_tools
else
    echo "build_tools already exists, skipping clone."
fi

# Modify Makefile
cd ${BUILDER_HOME}/document-server-package/
cat << EOF >> Makefile

deb_dependencies: \$(DEB_DEPS)

EOF

# Install Debian dependencies
echo "Installing Debian dependencies..."
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

# Remove old Node.js versions
echo "Removing old Node.js versions..."
apt-get remove -y nodejs libnode72 || true
apt-get autoremove -y
rm -rf /var/cache/apt/archives/nodejs_*.deb

## Start building
echo "Building..."
cd ${BUILDER_HOME}/build_tools/tools/linux
python3 ./automate.py server --branch=tags/${PRODUCT_VERSION}.${BUILD_NUMBER}
