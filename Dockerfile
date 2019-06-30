FROM registry.access.redhat.com/ubi8/s2i-base
COPY ./llvm-project /opt/llvm-project/
COPY ./build-llvm.sh /opt/app-root
RUN /opt/app-root/build-llvm.sh
