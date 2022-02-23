NAME=hg-agent
VERSION=2.0
ARCH=amd64

docker:
	docker build -t hostedgraphite/hg-agent-build-os7-py3 .
	@echo "You can upload the image with:"
	@echo "docker push hostedgraphite/hg-agent-build"
	@echo "(and the right credentials!)"

build:
	docker run -v $(HOME)/.ssh:/root/ssh_copy -v $(PWD):/hg-agent hostedgraphite/hg-agent-build-os7-py3 bash /hg-agent/build.sh $(VERSION)

buildtest:
	docker run -it -v $(HOME)/.ssh:/root/ssh_copy -v $(PWD):/hg-agent hostedgraphite/hg-agent-build-os7-py3 bash

buildlocal:
	docker run -v $(SSH_AUTH_SOCK):/ssh-agent --env SSH_AUTH_SOCK=/ssh-agent -v $(HOME)/.ssh:/root/ssh_copy -v $(PWD):/hg-agent hostedgraphite/hg-agent-build-os7-py3 bash /hg-agent/build.sh $(VERSION)

package:
	make deb
	make rpm

deb:
	make build-deb INIT=upstart   # Ubuntu 14.04
	make build-deb INIT=systemd   # Ubuntu > 16.04, Debian >= Jessie

build-deb:
	mkdir -p out/deb/$(INIT)/
	fpm -s dir -t deb -n $(NAME) -v $(VERSION) \
		-p out/deb/$(INIT)/$(NAME)_$(VERSION)_$(ARCH).deb \
 		--deb-priority optional --category admin \
 		--force \
 		--deb-compression bzip2 \
 		--after-install scripts/postinst.deb \
 		--before-remove scripts/prerm.deb \
 		--url https://www.hostedgraphite.com/ \
 		--description "Hosted Graphite agent" \
 		-m "Hosted Graphite agent <agent@hostedgraphite.com>" \
 		--license "MIT" \
 		--vendor "hostedgraphite.com" \
 		-a $(ARCH) \
 		dist/package=/opt/hg-agent \
 		dist/bin=/opt/hg-agent \
	    dist/collectors=/opt/hg-agent \
		dist/version=/opt/hg-agent \
	    etc/=/etc/opt/hg-agent \
 		$(INIT)/root/=/

rpm:
	make build-rpm INIT=systemd  # RHEL family >7

build-rpm:
	mkdir -p out/rpm/$(INIT)/
	fpm -s dir -t rpm -n $(NAME) -v $(VERSION) \
		-p out/rpm/$(INIT)/$(NAME)-$(VERSION).$(ARCH).rpm \
		--category admin \
 		--force \
 		--rpm-compression bzip2 \
 		--rpm-os linux \
 		--after-install scripts/postinst.rpm \
 		--before-remove scripts/prerm.rpm \
 		--url https://www.hostedgraphite.com/ \
 		--description "Hosted Graphite agent" \
 		-m "Hosted Graphite agent <agent@hostedgraphite.com>" \
 		--license "MIT" \
 		--vendor "hostedgraphite.com" \
 		-a $(ARCH) \
 		dist/package=/opt/hg-agent \
 		dist/bin=/opt/hg-agent \
	    dist/collectors=/opt/hg-agent \
		dist/version=/opt/hg-agent \
	    etc/=/etc/opt/hg-agent \
 		$(INIT)/root/=/

shell_lint:
	docker run -v $(PWD):/hg-agent koalaman/shellcheck /hg-agent/package_test

package_test:
	make -C targets/centos7
	make -C targets/centos8
	make -C targets/debian-jessie
	make -C targets/debian-stretch
	# Not available on Vagrant
	#make -C targets/debian-buster
	make -C targets/debian-bullseye
	make -C targets/ubuntu-14.04
	make -C targets/ubuntu-16.04
	make -C targets/ubuntu-18.04
	# Not available on Vagrant
	#make -C targets/ubuntu-18.10
	#make -C targets/ubuntu-19.04
	#make -C targets/ubuntu-19.10
	make -C targets/ubuntu-20.04

deb-upload:
	package_cloud push hostedgraphite/$(NAME)/$(DISTRO) /tmp/artifacts/out/deb/$(INIT)/$(NAME)_$(VERSION)_$(ARCH).deb

rpm-upload:
	package_cloud push hostedgraphite/$(NAME)/$(DISTRO) /tmp/artifacts/out/rpm/$(INIT)/$(NAME)-$(VERSION).$(ARCH).rpm

package-upload:
	make deb-upload DISTRO=debian/jessie   INIT=systemd
	make deb-upload DISTRO=debian/stretch  INIT=systemd
	make deb-upload DISTRO=debian/buster   INIT=systemd
	make deb-upload DISTRO=debian/bullseye INIT=systemd
	make deb-upload DISTRO=ubuntu/trusty   INIT=upstart
	make deb-upload DISTRO=ubuntu/xenial   INIT=systemd
	make deb-upload DISTRO=ubuntu/bionic   INIT=systemd
	make deb-upload DISTRO=ubuntu/cosmic   INIT=systemd
	make deb-upload DISTRO=ubuntu/disco    INIT=systemd
	make deb-upload DISTRO=ubuntu/eoan     INIT=systemd
	make deb-upload DISTRO=ubuntu/focal    INIT=systemd
	make rpm-upload DISTRO=el/7 INIT=systemd
	make rpm-upload DISTRO=el/8 INIT=systemd

.PHONY: docker build package deb build-deb rpm build-rpm shell_lint package_test deb-upload rpm-upload package-upload
