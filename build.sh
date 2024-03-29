#!/bin/bash
# Builds the agent. To be run inside the `hostedgraphite/hg-agent-build` docker image.

if [[ -z "$1" ]]; then
    echo "Usage: build.sh <version>"
    exit 1
fi

VERSION=$1

mkdir /root/.ssh
\cp -r /root/ssh_copy/* /root/.ssh

cd /hg-agent
virtualenv --python=/usr/bin/python3 /hg-agent.venv
source /hg-agent.venv/bin/activate
pip install pyinstaller==4.8    \
            setproctitle==1.1.10  \
            supervisor==4.2.4     \
            psutil==5.9.0         \
            pymongo==3.12.3       \
            'git+ssh://git@github.com/metricfire/python-multitail2.git@master#egg=multitail2'\
            'git+ssh://git@github.com/hostedgraphite/hg-agent-periodic.git@master#egg=hg_agent_periodic'\
            'git+ssh://git@github.com/hostedgraphite/Diamond.git@master#egg=diamond'\
            'git+ssh://git@github.com/hostedgraphite/hg-agent-forwarder.git@master#egg=hg_agent_forwarder'
# Workaround a PyInstaller issue with namespaced packages, cf. goo.gl/CnuoMo
touch /hg-agent.venv/lib/python3.8/site-packages/supervisor/__init__.py

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
