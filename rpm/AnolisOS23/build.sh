#!/bin/bash

# Exit on any error
set -e

# Function to print status messages
print_status() {
    echo "==== $1 ===="
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tag-name)
            TAG_NAME="$2"
            shift 2
            ;;
        --github-ref)
            GITHUB_REF="$2"
            shift 2
            ;;
        --github-repository)
            GITHUB_REPOSITORY="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$TAG_NAME" || -z "$GITHUB_REF" || -z "$GITHUB_REPOSITORY" ]]; then
    echo "Error: Missing required parameters"
    echo "Usage: $0 --tag-name <tag> --github-ref <ref> --github-repository <repo>"
    exit 1
fi

# Install required tools
print_status "Installing required tools"
dnf install -y anolis-epao-release gzip tar wget git

# Install RPM build tools
print_status "Installing RPM build tools"
dnf install -y rpm-build rpmdevtools

# Install dependency RPMs (Source5)
print_status "Installing dependency RPMs"
# Check if rpms.tar.gz is available in the current directory
if [ -f "rpms.tar.gz" ]; then
    # Extract RPMs to a temporary directory
    mkdir -p /tmp/rpms
    tar -xzf rpms.tar.gz -C /tmp/rpms
    # Install RPMs from the extracted directory
    if ls /tmp/rpms/rpms/*.rpm 1> /dev/null 2>&1; then
        dnf install -y /tmp/rpms/rpms/*.rpm
        print_status "Dependency RPMs installed successfully"
    else
        print_status "No RPM files found in the tarball, skipping installation"
    fi
    # Clean up
    rm -rf /tmp/rpms
else
    print_status "No rpms.tar.gz found, skipping installation"
fi

# Install additional BuildRequires dependencies
print_status "Installing additional BuildRequires dependencies"
dnf install -y anolis-epao-release cargo clang perl protobuf-devel git libtdx-attest-devel libgudev-devel openssl-devel tpm2-tss tpm2-tss-devel libsgx-dcap-quote-verify-devel libsgx-dcap-quote-verify libsgx-headers ca-certificates gcc golang perl-FindBin

# Prepare build artifacts
print_status "Preparing build artifacts"

# Set up RPM build environment
rpmdev-setuptree

# Move downloaded artifacts to SOURCES directory
# This assumes artifacts are already in the current directory
mv *.tar.gz ~/rpmbuild/SOURCES/ 2>/dev/null || true

# Prepare RPM build environment
print_status "Setting up RPM build environment"

# (Skip) Download the source tarball from the release
# wget -O ~/rpmbuild/SOURCES/trustee-${TAG_NAME#v}.tar.gz https://github.com/${GITHUB_REPOSITORY}/archive/refs/tags/${TAG_NAME}.tar.gz

# Extract config.toml from the tarball for the RPM build process
# The spec file expects a plain config.toml file, not a tarball
tar -xzf ~/rpmbuild/SOURCES/config.toml.tar.gz -C ~/rpmbuild/SOURCES/
print_status "Extracted config.toml from tarball for RPM build"

# Build RPM packages
print_status "Building RPM packages"
# Copy spec file to build directory
# This assumes we're running from the project root
cp rpm/AnolisOS23/trustee.spec ~/rpmbuild/SPECS/

# Build RPM packages using only the artifacts we downloaded
rpmbuild -ba ~/rpmbuild/SPECS/trustee.spec

print_status "RPM build completed successfully"
