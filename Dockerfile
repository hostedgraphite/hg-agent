# A build environment for the Hosted Graphite agent.
# Because we use PyInstaller, we need to build against the oldest glibc we
# intend to support: that's 2.12, available in CentOS 6.
FROM centos:6
MAINTAINER docker@hostedgraphite.com

ADD data /data/

# Fix for yum
RUN \cp -r hg-agent/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo

RUN yum -y update && \
    yum groupinstall -y development && \
    yum install -y gcc gcc-c++ zlib-dev openssl-devel sqlite-devel bzip2-devel libffi-devel zlib zlib-devel libssl-dev wget

# Build & install a modern Python
RUN cd /opt && wget https://www.python.org/ftp/python/3.8.8/Python-3.8.8.tgz && \
    tar xzf Python-3.8.8.tgz && \
    cd Python-3.8.8 && \
    ./configure --enable-optimizations && \
    make altinstall && rm Python-3.8.8.tgz

RUN ln -sfn /usr/local/bin/python3.8 /usr/bin/python3.8

# Add /usr/local/lib to ld.so's path.
RUN cp /data/usrlocal.conf /etc/ld.so.conf.d && \
    ldconfig -v

# Get pip & virtualenv up and running.
RUN wget https://bootstrap.pypa.io/ez_setup.py -O - | /usr/local/bin/python3 && \
    wget https://bootstrap.pypa.io/get-pip.py -O - | /usr/local/bin/python3 && \
    /usr/local/bin/pip install virtualenv

# Install the UPX executable packer.
RUN wget https://github.com/upx/upx/releases/download/v3.91/upx-3.91-amd64_linux.tar.bz2 && \
    tar -xjf upx-3.91-amd64_linux.tar.bz2 && \
    cp upx-3.91-amd64_linux/upx /usr/local/bin
