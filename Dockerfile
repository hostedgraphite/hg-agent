# A build environment for the Hosted Graphite agent.
# Because we use PyInstaller, we need to build against the oldest glibc we
# intend to support: that's 2.17, available in CentOS 7.
FROM centos:7
MAINTAINER docker@hostedgraphite.com

ADD data /data/

# Enable epel-release for yum
RUN yum --enablerepo=extras install epel-release -y

# Install required packages including packages for Python3 installation
RUN yum -y update && \
    yum groupinstall -y development && \
    yum -y install openssl-devel bzip2-devel libffi-devel xz-devel wget

# Build & install a modern Python
RUN wget https://www.python.org/ftp/python/3.8.8/Python-3.8.8.tgz && \
    tar xzf Python-3.8.8.tgz && \
    cd Python-3.8.8 && \
    ./configure --enable-optimizations --enable-shared && \
    make altinstall

# Add link for python3
RUN ln -sfn /usr/local/bin/python3.8 /usr/bin/python3

# Add /usr/local/lib to ld.so's path.
RUN cp /data/usrlocal.conf /etc/ld.so.conf.d && ldconfig -v

# Get pip and virtualenv up and running.
RUN ln -s /usr/local/bin/pip3.8 /usr/bin/pip
RUN /usr/bin/pip install virtualenv

# Install the UPX executable packer.
RUN wget https://github.com/upx/upx/releases/download/v3.91/upx-3.91-amd64_linux.tar.bz2 && \
    tar -xjf upx-3.91-amd64_linux.tar.bz2 && \
    cp upx-3.91-amd64_linux/upx /usr/local/bin
