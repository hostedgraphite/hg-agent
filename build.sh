#!/bin/bash
# Builds the agent. To be run inside the `hostedgraphite/hg-agent-build` docker image.

if [[ -z "$1" ]]; then
    echo "Usage: build.sh <version>"
    exit 1
fi

VERSION=$1

cp -r /root/ssh_copy /root/.ssh
chown -R root /root/.ssh

# Use the container's user for this
sed -i 's/ubuntu/root/' /root/.ssh/config
sed -i 's/\/home//' /root/.ssh/config

cd /hg-agent
virtualenv /hg-agent.venv
source /hg-agent.venv/bin/activate
pip install pyinstaller==3.1.1    \
            setproctitle==1.1.10  \
            supervisor==3.3.1     \
            diamond==4.0.451      \
            psutil==5.1.3         \
            multitail2==1.4.1     \
            pymongo==3.5.1       \
            'git+ssh://git@github.com/hostedgraphite/hg-agent-periodic.git@a496c507689b634acf3efdd6076e61698504f511#egg=hg_agent_periodic'\
            'git+ssh://git@github.com/hostedgraphite/hg-agent-forwarder.git@6d3939e42a8d2df80c737136da803c33bb61ae0d#egg=hg_agent_forwarder'
# Workaround a PyInstaller issue with namespaced packages, cf. goo.gl/CnuoMo
touch /hg-agent.venv/lib/python2.7/site-packages/supervisor/__init__.py

pyinstaller -y data/hg-agent.spec

# Symlinks to the various binaries inside `hg-agent`
BINARIES="diamond periodic config diamond-config supervisorctl supervisord forwarder receiver"
rm -Rf dist/bin
mkdir -p dist/bin
for b in ${BINARIES} ; do
    ln -s /opt/hg-agent/package/binary dist/bin/$b
done

# Packaging scripts
for s in postinst prerm ; do
    cp scripts/$s dist/bin
done

# Copies of the diamond collectors selected for distribution
COLLECTORS="cpu diskspace diskusage files loadavg memory network sockstat vmstat mongodb"
rm -Rf dist/collectors
mkdir -p dist/collectors
for c in ${COLLECTORS} ; do
    cp -R ${VIRTUAL_ENV}/share/diamond/collectors/$c dist/collectors
done

# Copies of custom collectors
COLLECTORS="self"
for c in ${COLLECTORS} ; do
    cp -R collectors/$c dist/collectors
done

# Version data
echo ${VERSION} > dist/version
