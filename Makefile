#
# Makefile	-- GNU 'make' for validating and building home setup
#

#
# Obtaining Individual Files from github.com:
#
#    Github redirects URLs of the form:
#
#        https://github.com/<user>/<repo>/raw/<branch>/<filename>
# to:
#        https://raw.github.com/<user>/<repo>/<branch>/<filename>
#

# Sometimes, /bin/sh is /bin/ash or something that doesn't understand:
# 
#     if [[ ... ]]; then
SHELL			= /bin/bash


.PHONY: FORCE all
all:			test				\
			personal			\
			git				\
			bash				\
			iterm				\
			emacs				\
			python				\
			python-modules			\
			tex


SYSTEM			= $(shell uname -s)
ifeq ($(SYSTEM),Linux)
    # Linux.  Use apt-get to install (assume Debian or Ubuntu...)
    homebrew		= /usr/bin/apt-get
    emacs		= /usr/local/bin/emacs
    bazaar		= /usr/bin/bzr
    mercurial		= /usr/bin/hg
    subversion		= /usr/bin/svn
    aspell		= /usr/bin/aspell
    gnutls		= /usr/bin/gnutls-serv
    autoconf		= /usr/bin/autoconf
    automake		= /usr/bin/automake
    libtool		= /usr/bin/libtool

    osname		= linux
    osarch		= i686

$(bazaar):
	sudo apt-get -u install bzr

$(mercurial):
	sudo apt-get -u install mercurial

$(subversion):
	sudo apt-get -u install subversion

$(aspell):
	sudo apt-get -u install aspell

$(gnutls):
	sudo apt-get -u install gnutls-bin

$(autoconf):
	sudo apt-get -u install autoconf

$(automake):
	sudo apt-get -u install automake

$(libtool):
	sudo apt-get -u install libtool
# Mostly from http://chrisperkins.blogspot.ca/2011/07/building-emacs-24.html
src/emacs:		$(bazaar)			\
			$(aspell)			\
			$(gnutls) 			\
			FORCE
	@if [ ! -d $@ ]; then				\
	    git clone git://git.savannah.gnu.org/emacs.git $@;\
	fi

$(emacs):		src/emacs
	sudo apt-get -u install libncurses5-dev libxpm-dev libjpeg-dev libgif-dev libtiff4-dev libpng12-dev
	cd $<; if [ ! -r configure ]; then ./autogen.sh; fi
	cd $<; if [ ! -r Makefile ]; then ./configure --prefix=/usr/local --without-makeinfo --with-x-toolkit=no; fi
	cd $<; make bootstrap && make && make install

.PHONY: sqlite3

/usr/bin/sqlite3:
	sudo apt-get -u install sqlite3

/usr/lib/libsqlite3.a:
	sudo apt-get -u install sqlite3 libsqlite3-dev

sqlite3:		/usr/bin/sqlite3 /usr/lib/libsqlite3.a
else
  ifeq ($(SYSTEM),Darwin)
    homebrew		= /usr/local/bin/brew
    emacs		= /usr/local/bin/emacs
    bazaar		= /usr/local/bin/bzr
    mercurial		= /usr/local/bin/hg
    subversion		= /usr/local/bin/svn
    aspell		= /usr/local/bin/aspell
    gnutls		= /usr/local/bin/gnutls-serv
    autoconf		= /usr/local/bin/autoconf
    automake		= /usr/local/bin/automake
    libtool		= /usr/local/bin/glibtool

    osname		= macosx-10.7
    osarch		= intel

$(bazaar):		$(homebrew)
	brew install bazaar || brew update bazaar || brew list bazaar && touch -c $@

$(mercurial):		$(homebrew)
	brew install mercurial || brew update mercurial || brew list mercurial && touch -c $@

$(subversion):		$(homebrew)
	brew install subversion || brew update subversion || brew list subversion && touch -c $@

$(aspell):		$(homebrew)
	brew install aspell --lang=en || brew update aspell || brew list aspell && touch -c $@

$(gnutls):		$(homebrew)
	brew install gnutls || brew update gnutls || brew list gnutls && touch -c $@

$(autoconf):		$(homebrew)
	brew install autoconf || brew update autoconf || brew list autoconf && touch -c $@

$(automake):		$(homebrew)
	brew install automake || brew update automake || brew list automake && touch -c $@

$(libtool):		$(homebrew)
	brew install libtool || brew update libtool || brew list libtool && touch -c $@

$(emacs):		$(bazaar)			\
			$(aspell)			\
			$(gnutls)			\
			$(homebrew)
	brew install emacs --HEAD --use-git-head || brew update emacs || brew list emacs && touch $@

.PHONY: sqlite3
# Sqlite3 is already install on OS-X
sqlite3:

  else
    $(error Unknown SYSTEM: $(SYSTEM))
  endif
endif

pyvers			= $(shell python --version 2>&1 | sed -ne '/Python/ s/.*\([0-9]\.[0-9]\)\..*/\1/p' )
ifeq ($(pyvers),2.7)
    pypkgs		= site-packages
else
    pypkgs		= dist-packages
endif

#
# Target to allow the printing of 'make' variables, eg:
#
#     make print-CXXFLAGS
#
print-%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)


# test		-- validate certain assumpsion
test:			/usr/local

# Confirm that /usr/local has 'admin' group write permissions
/usr/local:		FORCE
	@if [[ "$(shell ls -ld /usr/local 			\
	         | python -c 'print raw_input().split()[3]')"	\
	      != "admin" ]]; then				\
	    echo -n "/usr/local should group admin; found: ";	\
	    ls -ld /usr/local;					\
	    if read -p "Fix /usr/local permissions? (y/n)" R	\
	      && [[ "$${R##[Yy]*}" == "" ]]; then		\
	        echo "Fixing /usr/local";			\
		sudo find /usr/local -not -group 'admin' -a	\
		    -exec chgrp admin {} \; -a			\
		    -exec chmod g+w {} \; -print;		\
	    fi							\
	fi


# personal	-- Collect and store personal information in Makefile.personal
.PHONY: personal	
personal:		Makefile.personal		\
			.authinfo			\
			.bash_personal			\

Makefile.personal:	FORCE
	@if [ ! -f $@ ]; then touch $@; fi
	@if ! grep -q "^fullname=" $@; then		\
	    echo "This is your Git and Emacs Gnus email full name."; \
	    read -p "Enter full name: " REPLY; echo "fullname=$$REPLY" >> $@; \
	fi
	@if ! grep -q "^emailaddr=" $@; then		\
	    echo "This is your Git email, and your default Gnus From: address."; \
	    read -p "Enter email address: " REPLY; echo "emailaddr=$$REPLY" >> $@; \
	fi
	@if ! grep -q "^username=" $@; then		\
	    echo "This is your Org clock user ID.  Short, lower-case"; \
	    read -p "Enter username: " REPLY; echo "username=$$REPLY" >> $@; \
	fi
	@if ! grep -q "^gmailaddr=" $@; then		\
	    read -p "Enter gmail address: " REPLY; echo "gmailaddr=$$REPLY" >> $@; \
	fi
	@if ! grep -q "^gmailpass=" $@; then		\
	    echo "Only do this, if you have enabled Gmail 2-step verificationn, and have"; \
	    echo "created an application-specific password!!  Otherwise, hit return..."; \
	    read -p "Enter gmail password: " REPLY; echo "gmailpass=$$REPLY" >> $@; \
	fi
	@if ! grep -q "^splunkhost=" $@; then		\
	    read -p "Enter splunk hostname: " REPLY; echo "splunkhost=$$REPLY" >> $@; \
	fi
	@if ! grep -q "^splunkuser=" $@; then		\
	    read -p "Enter splunk username: " REPLY; echo "splunkuser=$$REPLY" >> $@; \
	fi
	@if ! grep -q "^splunkpass=" $@; then		\
	    read -p "Enter splunk password: " REPLY; echo "splunkpass=$$REPLY" >> $@; \
	fi

# If we've modified Makefile.personal GNU make will re-exec the make...
include Makefile.personal

.bash_personal:		Makefile.personal		\
			FORCE
	@if ! grep -q "^export EMAIL=$(emailaddr)" < $@; then \
	    echo "Updating $@ for EMAIL environment variable..."; \
	    echo "export EMAIL=$(emailaddr)" >> $@;	\
	fi

.authinfo:		Makefile.personal		\
			FORCE
	@if ! grep -q "$(gmailaddr) password $(gmailpass)" $@; then \
	    echo "Updating $@ for gnutls Gmail account access..."; \
	    echo "machine imap.gmail.com login $(gmailaddr) password $(gmailpass) port 993" > $@; \
	    echo "machine smtp.gmail.com login $(gmailaddr) password $(gmailpass) port 587" >> $@; \
	fi
	@chmod 0600 $@


# git		-- check git setup
.PHONY: git
git:			Makefile.personal		\
			FORCE
	@if [[ "$(shell git config --get user.name)" != "$(fullname)" ]]; then \
	    echo "Your Git user.name was: $(shell git config --get user.name); updating to $(fullname)"; \
	    git config --global user.name "$(fullname)"; \
	fi
	@if [[ "$(shell git config --get user.email)" != "$(emailaddr)" ]]; then \
	    echo "Your Git user.email was: $(shell git config --get user.email); updating to $(emailaddr)"; \
	    git config --global user.email "$(emailaddr)"; \
	fi
	@if [[ "$(shell git config --get core.editor)" != "emacs" ]]; then \
	    echo "Your Git core.editor was: $(shell git config --get core.editor); updating to emacs"; \
	    git config --global core.editor "emacs"; \
	fi

# bash		-- set up bash, etc.
#
#     Checks for and installs git prompt support.
.PHONY: bash
bash:			.git-completion.bash

.git-completion.bash:
	curl -o $@ https://raw.github.com/git/git/master/contrib/completion/git-completion.bash

# iterm		-- make sure its installed, and configured
#
#     For emacs to support org-mode in the iTerm terminal, we need to
# be able to support C-return, S-return and C-S-return; the Mac
# Terminal and iTerm doesn't send these.  Send alternative escape
# sequences; check that iTerm is properly configured.
#
.PHONY: iterm
iterm:			Library/Preferences/com.googlecode.iterm2.plist

Library/Preferences/com.googlecode.iterm2.plist:\
			FORCE
	@if ! plutil -convert xml1 -o - $@	\
		| sed -ne '/<key>0xd-0x20000/,/<\/dict>/{p;}' \
		| grep -q "<string>\[SR</string>"; then \
	    echo "*** Configure iTerm2 Profiles/Keys <shift-return> to Send Escape Code [SR"; \
	fi
	@if ! plutil -convert xml1 -o - $@	\
		| sed -ne '/<key>0xd-0x40000/,/<\/dict>/{p;}' \
		| grep -q "<string>\[CR</string>"; then \
	    echo "*** Configure iTerm2 Profiles/Keys <control-return> to Send Escape Code [CR"; \
	fi
	@if ! plutil -convert xml1 -o - $@	\
		| sed -ne '/<key>0xd-0x60000/,/<\/dict>/{p;}' \
		| grep -q "<string>\[CSR</string>"; then \
	    echo "*** Configure iTerm2 Profiles/Keys <control-shift-return> to Send Escape Code [CSR"; \
	fi

# homebrew	-- required to build various applications
#
#     Tests for existence and installs if necessary.  Always ensures that
# targets are marked as up-to-date by using, in case homebrew is ever
# re-installed, by including '... && touch -c <target>':
#
#     /usr/local/bin/<target>:	$(homebrew)
#         brew install <target> || brew list <target> && touch -c $@
# 
# This pattern will succeed in touching the target up-to-date iff and only iff
# *either* the target is successfully isntalled, *or* if it is already
# installed.  This complexity is necessary because brew install <target> will
# report failure if already installed.
/usr/local/bin/brew:
	@if read -p "Install homebrew? (y/n)" R		\
		&& [[ "$${R##[Yy]*}" == "" ]]; then	\
	    /usr/bin/ruby -e "$$(curl -fsSL https://raw.github.com/gist/323731)"; \
	else						\
	    echo "Please install homebrew."; false;	\
	fi

# emacs 24.0	-- editor and any necessary components
#
#     Clone and/or pull pjkundert/emacs-prelude, branch 'hardcons', and
# always execute the personal/Makefile; ensure we've updated the
# 'personal' target, here, since Makefile.personal is used by
# .emacs.d/personal/Makefile, to generate various personalized
# variables.


.PHONY: emacs emacs-24
emacs:			.emacs.d/personal		\
			emacs-24			\
			FORCE

emacs-24:		$(emacs)			\
			FORCE
	@if ! which emacs | grep -q /usr/local/bin/emacs; then \
	    echo "Add /usr/local/bin to beginning of PATH; adjust /etc/paths, or .bash_profile"; \
	fi
	@if ! emacs --version | grep -q "GNU Emacs 24"; then \
	    echo "Version 24 of emacs needed; found: $(shell emacs --version | head -1 )"; \
	fi

.emacs:			FORCE
	@if [ -f $@ ]; then				\
	    echo "*** $@ exists; move aside.";		\
	    false;					\
	fi

.emacs.d:		FORCE
	@if [ ! -d $@ ]; then				\
	    git clone git://github.com/pjkundert/emacs-prelude.git $@; \
	else						\
	    if [ ! -d $@/.git ]				\
		    || ! grep -q "emacs-prelude.git" $@/.git/config; then \
		echo "*** $@ exists, but is not emacs-prelude!  Move aside."; \
		false;					\
	    fi						\
	fi
	cd $@; git checkout hardcons
	cd $@; git pull origin hardcons

.emacs.d/personal:	.emacs				\
			.emacs.d			\
			personal
	cd $@; make


# python
#
#     Various required python extension.  Source in ~/src/..., install
# into /usr/local/python#.#/$(pypkgs)/.

.PHONY: python

python:
	@if ! python --version 2>&1 | grep -q "2.[67]"; then \
	    echo "Need Python 2.[67]; found: $(shell python --version 2>&1 )"; \
	fi

python-modules:		git-python			\
			itty				\
			webpy				\
			wsgilog				\
			nose				\
			websockets			\
			splunk

# GitPython	-- Python git API module "git"
#GitPython-0.3.2.RC1-py2.7.egg
gitpyvers		= 0.3.2.RC1
#gitpyurl		= git://github.com/gitpython-developers/GitPython.git
gitpyurl		= git://github.com/pjkundert/GitPython.git
gitpybranch		= 0.3
gitpypath		= /usr/local/lib/python$(pyvers)/$(pypkgs)/GitPython-$(gitpyvers)-py$(pyvers).egg
.PHONY: git-python
src/git-python:		FORCE
	@if [ ! -d $@ ]; then				\
	    git clone $(gitpyurl) $@;			\
	fi
	cd $@; git checkout $(gitpybranch); git pull origin $(gitpybranch)
	git submodule update --init --recursive

$(gitpypath):		src/git-python
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

git-python:		python nose mock $(gitpypath)

# itty	-- Python webserver module "itty"; Not reliable...
# itty-0.8.1-py2.7.egg-info
ittyvers		= 0.8.1
ittypath		= /usr/local/lib/python$(pyvers)/$(pypkgs)/itty-$(ittyvers)-py$(pyvers).egg-info
src/itty:		FORCE
	@if [ ! -d $@ ]; then				\
	    git clone git://github.com/pjkundert/itty.git $@; \
	fi
	cd $@; git pull origin master

$(ittypath):		src/itty
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

itty:			python $(ittypath)

# web.py	-- Pytnon webserver module "web"
# web.py-0.37-py2.7.egg-info
webpyvers		= 0.37
#webpyurl		= git://github.com/webpy/webpy.git
webpyurl		= git://github.com/pjkundert/webpy.git
webpypath		= /usr/local/lib/python$(pyvers)/$(pypkgs)/web.py-$(webpyvers)-py$(pyvers).egg-info
.PHONY: webpy
src/webpy:		FORCE
	@if [ ! -d $@ ]; then				\
	    git clone $(webpyurl) $@;			\
	fi
	cd $@; git pull origin master

$(webpypath):		src/webpy
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

webpy:			python $(webpypath)

# wsgilog	-- Needed for logging in web.py webservers
# wsgilog-0.3-py2.7.egg
wsgilogvers		= 0.3
wsgilogurl		= https://bitbucket.org/lcrees/wsgilog
wsgilogpath		= /usr/local/lib/python$(pyvers)/$(pypkgs)/wsgilog-$(wsgilogvers)-py$(pyvers).egg
.PHONY: wsgilog

src/wsgilog:		$(mercurial) FORCE
	@if [ ! -d $@ ]; then				\
	    hg clone $(wsgilogurl) $@;			\
	fi
#	cd $@; hg pull -u

$(wsgilogpath):		src/wsgilog
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $</wsgilog; python setup.py install --prefix=/usr/local

wsgilog:		python $(wsgilogpath)

# nose		-- Python unittest helper nosetests (like py.test)
# nose-1.1.3.dev-py2.7.egg
nosevers		= 1.1.3.dev
nosepath		= /usr/local/lib/python$(pyvers)/$(pypkgs)/nose-$(nosevers)-py$(pyvers).egg
noseurl			= git://github.com/nose-devs/nose.git
.PHONY: nose
src/nose:		FORCE
	@if [ ! -d $@ ]; then				\
	    git clone $(noseurl) $@;			\
	fi
	cd $@; git pull origin master

$(nosepath):		src/nose
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

nose:			python $(nosepath)

# mock		-- Python testing utility
# mock-0.5.0-py2.7.egg
mockvers		= 0.5.0
mockfile		= mock-$(mockvers).zip
mockurl			= http://mock.googlecode.com/files/$(mockfile)
mockpath		= /usr/local/lib/python$(pyvers)/$(pypkgs)/mock-$(mockvers)-py$(pyvers).egg
.PHONY: mock
src/$(mockfile):
	curl -o $@ $(mockurl)

src/mock-$(mockvers):	src/$(mockfile)
	cd $(dir $@) && unzip -o $(mockfile)

$(mockpath):		src/mock-$(mockvers)
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@):$(PYTHONPATH)}; cd $<; python setup.py install --prefix=/usr/local

mock:			python $(mockpath)

# splunk	-- Python Splunk API
# splunk_sdk-0.8.0-py2.7.egg-info
splunkurl		= https://github.com/splunk/splunk-sdk-python.git
splunkvers		= 0.8.0
splunkbranch		= master
splunkpath		= /usr/local/lib/python$(pyvers)/$(pypkgs)/splunk_sdk-$(splunkvers)-py$(pyvers).egg-info
.PHONY: splunk
src/splunk-sdk-python:	FORCE
	@if [ ! -d $@ ]; then				\
	    git clone $(splunkurl) $@;			\
	fi
	cd $@; git pull origin master

$(splunkpath):		src/splunk-sdk-python
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

.splunkrc:		Makefile.personal		\
			FORCE
	@if ! grep -q "^host=$(splunkhost)" < $@; then	\
	    echo "Updating $@ for Splunk host...";	\
	    echo "host=$(splunkhost)" >> $@;		\
	fi
	@if ! grep -q "^username=$(splunkuser)" < $@; then\
	    echo "Updating $@ for Splunk user...";	\
	    echo "username=$(splunkuser)" >> $@;	\
	fi
	@if ! grep -q "^password=$(splunkpass)" < $@; then\
	    echo "Updating $@ for Splunk password...";	\
	    echo "password=$(splunkpass)" >> $@;	\
	fi

splunk:			python				\
			$(splunkpath)			\
			.splunkrc



# WebSockets.  Build and install mongrel2 and m2py, and 2 Python implementations
# Also, download Socket.IO, which appears to be the definitive cross-browser 
# Javascript WebSockets implementation, with fallbacks to Flash sockets and AJAX.
.PHONY: websockets
websockets:		mongrel2 m2py			\
			socketio

# WebSockets libraries no longer used.
#			autobahn
#			ws4py


# Mongrel2; 0MQ-backed HTTP/WebSockets async web server
# (builds by default for installation in /usr/local)
mongrel2url	= git://github.com/pjkundert/mongrel2
mongrel2branch	= develop
mongrel2path	= /usr/local/bin/mongrel2
.PHONY: mongrel2
src/mongrel2:		FORCE libzmq3 sqlite3
	@if [ ! -d $@ ]; then				\
	    git clone $(mongrel2url) $@;		\
	fi
	cd $@; git checkout $(mongrel2branch)

$(mongrel2path):	src/mongrel2
	cd $< && make all && make install

mongrel2:	$(mongrel2path)

# Mongrel2 Python 0MQ backend module
# m2py-1.7.5-py2.7.egg
m2pyvers	= 1.7.5
m2pypath	= /usr/local/lib/python$(pyvers)/$(pypkgs)/m2py-$(m2pyvers)-py$(pyvers).egg
.PHONY: m2py

src/mongrel2/examples/python:				\
			src/mongrel2 storm pyrepl simplejson nose pyzmq

$(m2pypath):		src/mongrel2/examples/python
	cd $< && python setup.py install --prefix=/usr/local

m2py:			$(m2pypath)

# storm	-- Python ORM module
#storm-0.19.0.99-py2.7-macosx-10.7-intel.egg
stormurl	= lp:storm
stormvers	= 0.19.0.99
stormpath	= /usr/local/lib/python$(pyvers)/$(pypkgs)/storm-$(stormvers)-py$(pyvers)-$(osname)-$(osarch).egg
.PHONY: storm
src/storm:		$(bazaar) FORCE
	@if [ ! -d $@ ]; then				\
	    bzr branch $(stormurl) $@;			\
	fi

$(stormpath):		src/storm
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

storm:			python $(stormpath)

# pyrepl -- Python REPL
# pyrepl-0.8.2-py2.7.egg
pyreplurl	= http://codespeak.net/svn/pyrepl/trunk/pyrepl
pyreplvers	= 0.8.2
pyreplpath	= /usr/local/lib/python$(pyvers)/$(pypkgs)/pyrepl-$(pyreplvers)-py$(pyvers).egg

.PHONY: pyrepl
src/pyrepl:		$(bazaar) FORCE
	@if [ ! -d $@ ]; then				\
	    svn co $(pyreplurl) $@;			\
	fi

$(pyreplpath):		src/pyrepl
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

pyrepl:			python $(pyreplpath)

# simplejson -- Python REPL
# simplejson-2.5.0-py2.7.egg-info
simplejsonurl	= git://github.com/simplejson/simplejson
simplejsonvers	= 2.5.0
simplejsonbranch= v$(simplejsonvers)
simplejsonpath	= /usr/local/lib/python$(pyvers)/$(pypkgs)/simplejson-$(simplejsonvers)-py$(pyvers).egg-info

.PHONY: simplejson
src/simplejson:		$(bazaar) FORCE
	@if [ ! -d $@ ]; then				\
	    git clone $(simplejsonurl) $@;		\
	fi
	cd $@; git checkout $(simplejsonbranch)

$(simplejsonpath):	src/simplejson
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

simplejson:		python $(simplejsonpath)


# 0MQ 3.1 API; Supplied either by ZeroMQ or Crossroads-IO
libzmq3url	= git://github.com/zeromq/libzmq
libzmq3ver	= 3.1.1
libzmq3branch	= master
libzmq3path	= /usr/local/lib/libzmq.3.dylib
.PHONY: libzmq3

src/libzmq:		FORCE $(autoconf) $(automake) $(libtool)
	@if [ ! -d $@ ]; then				\
	    git clone $(libzmq3url) $@;			\
	fi
	cd $@; git checkout $(libzmq3branch)

$(libzmq3path):		src/libzmq
	@if [ ! -r $</configure ]; then			\
	    cd $<; ./autogen.sh;			\
	fi
	@if [ ! -r $</Makefile ]; then			\
	    cd $<;./configure --prefix=/usr/local;	\
	fi
	cd $< && make V=1 && make install && touch $@

libzmq3:		$(libzmq3path)


# 0MQ 2.1 API; For backwards-compatibility testing changes (eg. to mongrel2)
libzmq2url	= git://github.com/zeromq/zeromq2-x
libzmq2ver	= 2.1.11
libzmq2branch	= master
libzmq2path	= /usr/local/lib/libzmq.1.dylib
.PHONY: libzmq2

src/zeromq2-x:		FORCE $(autoconf) $(automake) $(libtool)
	@if [ ! -d $@ ]; then				\
	    git clone $(libzmq2url) $@;			\
	fi
	cd $@; git checkout $(libzmq2branch)

$(libzmq2path):		src/zeromq2-x
	@if [ ! -r $</configure ]; then			\
	    cd $<; ./autogen.sh;			\
	fi
	@if [ ! -r $</Makefile ]; then			\
	    cd $<;./configure --prefix=/usr/local;	\
	fi
	cd $< && make V=1 && make install && touch $@

libzmq2:		$(libzmq2path)


# Python 0MQ 2.1/3.1 bindings.  Requires cython to compile.
pyzmqurl	= git://github.com/zeromq/pyzmq
pyzmqvers	= 2.1.11
pyzmqbranch	= v$(pyzmqvers)
pyzmqpath	= /usr/local/lib/python$(pyvers)/$(pypkgs)/pyzmq-$(pyzmqvers)-py$(pyvers).egg-info
.PHONY: pyzmq

src/pyzmq:		FORCE cython libzmq3
	@if [ ! -d $@ ]; then				\
	    git clone $(pyzmqurl) $@;			\
	fi
	cd $@; git checkout $(pyzmqbranch)

$(pyzmqpath):		src/pyzmq
	cd $<						\
	  && python setup.py configure --zmq=/usr/local	\
	  && python setup.py build			\
	  && python setup.py install --prefix=/usr/local

pyzmq:			$(pyzmqpath)

pyzmq-test:		src/pyzmq FORCE
	cd $<						\
	  && python setup.py configure --zmq=/usr/local	\
	  && python setup.py build_ext --inplace	\
	  && python setup.py test


# AutobahnPython.  Another WebSockets foundation; evidently highly respected.
# Requires twisted, also highly respected.  See src/autobahn/examples and
# src/ws4py/examples.

.PHONY: autobahn twisted
# autobahn-0.5.0-py2.7.egg
autobahnurl	= git://github.com/tavendo/AutobahnPython.git
autobahnvers	= 0.5.0
autobahnpath	= /usr/local/lib/python$(pyvers)/$(pypkgs)/autobahn-$(autobahnvers)-py$(pyvers).egg

src/autobahn:		FORCE twisted
	@if [ ! -d $@ ]; then				\
	    git clone $(autobahnurl) $@;		\
	fi
	cd $@; git checkout v$(autobahnvers)

$(autobahnpath):	src/autobahn
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $</autobahn; python setup.py install --prefix=/usr/local

autobahn:		python $(autobahnpath)

# Twisted -- Python async I/O.
# FIX: Revision number changes on each checkin; must deduce?
# Twisted-12.0.0_r34238-py2.7-macosx-10.7-intel.egg
twistedvers	= 12.0.0
twistedrev	= r34238
twistedurl	= svn://svn.twistedmatrix.com/svn/Twisted/tags/releases/twisted-$(twistedvers)
twistedpath	= /usr/local/lib/python$(pyvers)/$(pypkgs)/Twisted-$(twistedvers)_$(twistedrev)-py$(pyvers)-$(osname)-$(osarch).egg

src/twisted:		FORCE
	@if [ ! -d $@ ]; then				\
	    svn co $(twistedurl) $@;			\
	fi

$(twistedpath):		src/twisted
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

twisted:		python $(twistedpath)


# Demo of WebSockets using gevent, flot.  Installation not complete; too many
# dependencies...
.PHONY: gevent-socketio socketio paste
gevent-socketio:	src/gevent-socketio		\
			gevent				\
			socketio			\
			paste

src/gevent-socketio:	FORCE
	@if [ ! -d $@ ]; then				\
	    git clone git://git.code.sf.net/u/rick446/gevent-socketio $@; \
	fi
	cd $@; git pull origin master

paste:

.PHONY: socketio
socketiourl	= git://github.com/LearnBoost/socket.io

src/socket.io:
	@if [ ! -d $@ ]; then				\
	    git clone $(socketiourl) $@;		\
	fi
	cd $@; git pull origin master

socketio:		src/socket.io


# Gevent.  Latest tag 1.0b2; Last stable tag 0.13.1 (no good).  Depends on cython
# gevent-1.0dev-py2.7-macosx-10.7-intel.egg
geventurl	= https://bitbucket.org/denis/gevent
geventvers	= 1.0b2
geventpath	= /usr/local/lib/python$(pyvers)/$(pypkgs)/gevent-1.0dev-py$(pyvers)-$(osname)-$(osarch).egg
.PHONY: gevent
src/gevent:		FORCE cython
	@if [ ! -d $@ ]; then				\
	    hg clone -r $(geventvers) $(geventurl) $@;	\
	fi
#	cd $@; hg pull -u

$(geventpath):		src/gevent
	echo "Making: $@"
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

gevent:			python $(geventpath)


cythonurl	= git://github.com/cython/cython.git
cythonpath	= /usr/local/bin/cython
cythonvers	= 0.15.1
.PHONY: cython
src/cython:		FORCE
	@if [ ! -d $@ ]; then				\
	    git clone $(cythonurl) $@;			\
	fi
	cd $@; git checkout $(cythonvers)

$(cythonpath):		src/cython
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

cython:			$(cythonpath)

# ws4py; A WSGI WebSockets implementation.  Works with cherrypy and/or gevent
ws4pyurl	= git://github.com/Lawouach/WebSocket-for-Python.git
ws4pyvers	= 0.2.1
ws4pypath	= /usr/local/lib/python$(pyvers)/$(pypkgs)/ws4py-$(ws4pyvers)-py$(pyvers).egg
.PHONY: ws4py
src/ws4py:		FORCE cherrypy gevent
	@if [ ! -d $@ ]; then				\
	    git clone $(ws4pyurl) $@;			\
	fi
	cd $@; git checkout v$(ws4pyvers)

$(ws4pypath):		src/ws4py
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

ws4py:			python $(ws4pypath)

cherrypyurl	= https://bitbucket.org/cherrypy/cherrypy
cherrypyvers	= 3.2.2
cherrypypath	= /usr/local/lib/python$(pyvers)/$(pypkgs)/cherrypy-$(cherrypyvers)-py$(pyvers).egg
.PHONY: cherrypy
src/cherrypy:		FORCE
	@if [ ! -d $@ ]; then				\
	    hg clone -r cherrypy-$(cherrypyvers) $(cherrypyurl) $@; \
	fi
#	cd $@; hg pull -u

$(cherrypypath):	src/cherrypy
	@mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $<; python setup.py install --prefix=/usr/local

cherrypy:		python $(cherrypypath)

# Check that MacTex has been installed
.PHONY: tex
tex:	/usr/texbin/pdflatex
/usr/texbin/pdflatex:
	@echo "Require pdflatex for org-export-as-pdf; Download MacTex from http://www.tug.org/mactex/2011"
