target_test:
	vagrant destroy --force
	vagrant up
	vagrant ssh -c "sudo /hg-agent/package_test $(PKG) $(INIT) install"
	vagrant reload
	vagrant ssh -c "sudo /hg-agent/package_test $(PKG) $(INIT) boot"
	vagrant ssh -c "sudo /hg-agent/package_test $(PKG) $(INIT) stop"
	vagrant ssh -c "sudo /hg-agent/package_test $(PKG) $(INIT) start"
	vagrant ssh -c "sudo /hg-agent/package_test $(PKG) $(INIT) remove"
	vagrant destroy --force

.PHONY: target_test
