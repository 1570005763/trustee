#!/bin/bash
# build-in-docker.sh

# Exit on any error
set -euxo pipefail

# Function to print status messages
print_status() {
    echo "==== $1 ===="
}

# Parse command line arguments
TARBALL="$1"
if [[ -z "$TARBALL" ]]; then
  echo "Usage: $0 <rpmbuild-tarball.tar.gz>"
  exit 1
fi

# Set up RPM build environment
print_status "Setting up RPM build environment"
rpmdev-setuptree

# Prepare build artifacts
print_status "Preparing build artifacts"

tar -xzf "/input/$TARBALL" -C /tmp/
BUILD_DIR="/tmp/${TARBALL%.tar.gz}"

# copy SOURCES and SPECS
cp -r "$BUILD_DIR"/SOURCES/* ~/rpmbuild/SOURCES/
cp -r "$BUILD_DIR"/SPECS/*   ~/rpmbuild/SPECS/

# Build RPM packages
print_status "Building RPM packages"

# Install dependency RPMs (Source5)
dnf install -y ~/rpmbuild/SOURCES/rpms/*.rpm

# Install  BuildRequires dependencies
dnf builddep your-package.spec

# Build RPM packages using only the artifacts we downloaded
rpmbuild -ba ~/rpmbuild/SPECS/trustee.spec

print_status "RPM build completed successfully"
