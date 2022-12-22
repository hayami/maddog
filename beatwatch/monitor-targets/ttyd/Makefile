TOOLDIR	= $$HOME/www-tools
TTYDSSH	= $(TOOLDIR)/etc/ttyd/ssh
HTMLDIR	= $$HOME/www/tty/ttyd/ssh

install-ttyd: ttyd-mod-build+install-script.sh
	/bin/sh ttyd-mod-build+install-script.sh

install-ssh-config: ssh-config
	mkdir -p $(TTYDSSH)
	chmod 0700 $(TTYDSSH)
	cat ssh-config | (umask 077 && cd $(TTYDSSH) && cat > config)
	cd $(TTYDSSH) && ssh -4 localhost -o UserKnownHostsFile=known_hosts true
	cd $(TTYDSSH) && ssh-keygen -b 4096 -f identity -C "$$USER@console"
	find $(TTYDSSH) -exec chmod go-rwx {} \;

install-html: index.cgi console.cgi console.shfunc
	mkdir -p $(HTMLDIR)
	install -t $(HTMLDIR) -m 0755 index.cgi
	install -t $(HTMLDIR) -m 0755 console.cgi
	install -t $(HTMLDIR) -m 0644 console.shfunc
	install -m 0644 htaccess $(HTMLDIR)/.htaccess
