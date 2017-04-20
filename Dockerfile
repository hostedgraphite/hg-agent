# A build environment for the Hosted Graphite agent.
# Because we use PyInstaller, we need to build against the oldest glibc we
# intend to support: that's 2.12, available in CentOS 6.
FROM centos:6
MAINTAINER docker@hostedgraphite.com

ADD data /data/

RUN yum -y update && \
    yum groupinstall -y development && \
    yum install -y zlib-dev openssl-devel sqlite-devel bzip2-devel wget

# Build & install a modern Python
RUN wget http://www.python.org/ftp/python/2.7.12/Python-2.7.12.tar.xz && \
    tar -xJf Python-2.7.12.tar.xz && \
    cd Python-2.7.12 && \
    ./configure --prefix=/usr/local --enable-shared && \
    make && \
    make altinstall

# Add /usr/local/lib to ld.so's path.
RUN cp /data/usrlocal.conf /etc/ld.so.conf.d && \
    ldconfig -v

# Get pip & virtualenv up and running.
RUN wget https://bootstrap.pypa.io/ez_setup.py -O - | /usr/local/bin/python2.7 && \
    wget https://bootstrap.pypa.io/get-pip.py -O - | /usr/local/bin/python2.7 && \
    /usr/local/bin/pip install virtualenv

# Install the UPX executable packer.
RUN wget https://github.com/upx/upx/releases/download/v3.91/upx-3.91-amd64_linux.tar.bz2 && \
    tar -xjf upx-3.91-amd64_linux.tar.bz2 && \
    cp upx-3.91-amd64_linux/upx /usr/local/bin
