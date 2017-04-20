NAME=hg-agent
VERSION=1.0
ARCH=amd64

docker:
	docker build -t hostedgraphite/hg-agent-build .
	@echo "You can upload the image with:"
	@echo "docker push hostedgraphite/hg-agent-build"
	@echo "(and the right credentials!)"

build:
	docker run -v $(HOME)/.ssh:/root/ssh_copy -v $(PWD):/hg-agent hostedgraphite/hg-agent-build bash /hg-agent/build.sh $(VERSION)

buildlocal:
	docker run -v $(SSH_AUTH_SOCK):/ssh-agent --env SSH_AUTH_SOCK=/ssh-agent -v $(HOME)/.ssh:/root/ssh_copy -v $(PWD):/hg-agent hostedgraphite/hg-agent-build bash /hg-agent/build.sh $(VERSION)

package:
	make deb
	make rpm

deb:
	make build-deb INIT=sysvinit  # Debian < Jessie
	make build-deb INIT=upstart   # Ubuntu 1{2,4}.04
	make build-deb INIT=systemd   # Ubuntu 16.04, Debian Jessie

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
	make build-rpm INIT=sysvinit # RHEL family 6
	make build-rpm INIT=systemd  # RHEL family 7

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
	make -C targets/centos6
	make -C targets/centos7
	make -C targets/debian-wheezy
	make -C targets/debian-jessie
	make -C targets/ubuntu-12.04
	make -C targets/ubuntu-14.04
	make -C targets/ubuntu-16.04

deb-upload:
	package_cloud push metricfire/$(NAME)/$(DISTRO) out/deb/$(INIT)/$(NAME)_$(VERSION)_$(ARCH).deb

rpm-upload:
	package_cloud push metricfire/$(NAME)/$(DISTRO) out/rpm/$(INIT)/$(NAME)-$(VERSION).$(ARCH).rpm

package-upload:
	make deb-upload DISTRO=debian/wheezy  INIT=sysvinit
	make deb-upload DISTRO=debian/jessie  INIT=systemd
	make deb-upload DISTRO=ubuntu/precise INIT=upstart
	make deb-upload DISTRO=ubuntu/trusty  INIT=upstart
	make deb-upload DISTRO=ubuntu/xenial  INIT=systemd
	make rpm-upload DISTRO=el/6 INIT=sysvinit
	make rpm-upload DISTRO=el/7 INIT=systemd

.PHONY: docker build package deb build-deb rpm build-rpm shell_lint package_test deb-upload rpm-upload package-upload
