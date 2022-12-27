.PHONY:	default install
default: install-all
install: install-all

SSHHOST	= localhost
KEYCOMMENT = $$USER@console

TOOLDIR	= $$HOME/www-tools
TTYDSSH	= $(TOOLDIR)/etc/ttyd/ssh
HTMLDIR	= $$HOME/www/tty/ttyd/ssh

MAKEFLAGS += --no-print-directory

.PHONY:	install-all uninstall-all
install-all: install-bin install-misc
uninstall-all: uninstall-bin uninstall-misc

.PHONY:	install-bin uninstall-bin
install-bin: install-beatwatch install-ttyd
uninstall-bin: uninstall-beatwatch uninstall-ttyd

.PHONY:	install-misc uninstall-misc
install-misc: install-html install-ssh-config
uninstall-misc: uninstall-html uninstall-ssh-config

.PHONY:	install-beatwatch uninstall-beatwatch
install-beatwatch: ../../obj/beatwatch
	install -t $(TOOLDIR)/bin -m 0755 $<

../../obj/beatwatch:
	$(MAKE) -C ../.. build

uninstall-beatwatch:
	rm -f $(TOOLDIR)/bin/beatwatch
	rmdir -v -p $(TOOLDIR)/bin

.PHONY:	install-ttyd uninstall-ttyd
install-ttyd: ttyd-mod-build+install-script.sh
	/bin/sh ttyd-mod-build+install-script.sh $(TOOLDIR)

uninstall-ttyd:
	rm -f $(TOOLDIR)/bin/ttyd
	rmdir -v -p $(TOOLDIR)/bin

.PHONY:	install-html uninstall-html
install-html: index.cgi console.cgi console.shfunc
	mkdir -p $(HTMLDIR)
	install -t $(HTMLDIR) -m 0755 index.cgi
	install -t $(HTMLDIR) -m 0755 console.cgi
	install -t $(HTMLDIR) -m 0644 console.shfunc
	install -m 0644 htaccess $(HTMLDIR)/.htaccess

uninstall-html:
	rm -f $(HTMLDIR)/index.cgi
	rm -f $(HTMLDIR)/console.cgi
	rm -f $(HTMLDIR)/console.disable*
	rm -f $(HTMLDIR)/console.shfunc
	rm -f $(HTMLDIR)/.htaccess
	rmdir -v -p $(HTMLDIR)

.PHONY:	install-ssh-config uninstall-ssh-config
install-ssh-config: ssh-config
	mkdir -p $(TTYDSSH)
	chmod 0700 $(TTYDSSH)
	umask 0077 && cat ssh-config > $(TTYDSSH)/config
	/bin/sh ssh-known-hosts.sh $(TTYDSSH) $(SSHHOST)
	/bin/sh ssh-keygen.sh $(TTYDSSH) $(KEYCOMMENT)
	/bin/sh ssh-authorized-keys.sh $(TTYDSSH) $(SSHHOST)
	find $(TTYDSSH) -exec chmod go-rwxst {} \;

uninstall-ssh-config:
	rm -rf $(TTYDSSH)
	rmdir -v -p $$(dirname $(TTYDSSH))

# vim: noet sw=8 sts=8
