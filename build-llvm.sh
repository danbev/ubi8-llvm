#!/bin/bash

set -ex

INSTALL_PKGS="nss_wrapper python2"
yum install --disableplugin=subscription-manager -y --setopt=tsflags=nodocs ${INSTALL_PKGS}
export PYTHON=`which python2`

### Install clang
pushd /opt/llvm-project
mkdir build && cd build
cmake -G "Unix Makefiles" -DLLVM_ENABLE_PROJECTS="clang;libcxx;libcxxabi" ../llvm
make -j8 
make dist-zip
popd
