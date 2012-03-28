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

homebrew		= /usr/local/bin/brew
emacs			= /usr/local/bin/emacs
bazaar			= /usr/local/bin/bzr
mercurial		= /usr/local/bin/hg
aspell			= /usr/local/bin/aspell
gnutls			= /usr/local/bin/gnutls-serv

pyvers			= $(shell python --version 2>&1 | sed -ne '/Python/ s/.*\([0-9]\.[0-9]\)\..*/\1/p' )

gitpyvers		= 0.3.1
gitpypath		= /usr/local/lib/python$(pyvers)/site-packages/GitPython-$(gitpyvers)-py$(pyvers).egg

ittyvers		= 0.8.1
ittypath		= /usr/local/lib/python$(pyvers)/site-packages/itty-$(ittyvers)-py$(pyvers).egg-info

webpyvers		= 0.37
webpypath		= /usr/local/lib/python$(pyvers)/site-packages/web.py-$(webpyvers)-py$(pyvers).egg-info

wsgilogvers		= 0.3
wsgilogurl		= https://bitbucket.org/lcrees/wsgilog
wsgilogpath		= /usr/local/lib/python$(pyvers)/site-packages/wsgilog-$(wsgilogvers)-py$(pyvers).egg

nosevers		= 1.1.3.dev
nosepath		= /usr/local/lib/python$(pyvers)/site-packages/nose-$(nosevers)-py$(pyvers).egg
noseurl			= git://github.com/nose-devs/nose.git

mockvers		= 0.5.0
mockfile		= mock-$(mockvers).zip
mockurl			= http://mock.googlecode.com/files/$(mockfile)
mockpath		= /usr/local/lib/python$(pyvers)/site-packages/mock-$(mockvers)-py$(pyvers).egg

splunksdkvers		= 0.9.0
splunksdkpath		= /usr/local/lib/python$(pyvers)/site-packages/splunk-$(splunksdkvers)-py$(pyvers).egg
splunksdkurl		= https://github.com/splunk/splunk-sdk-python.git

#
# Target to allow the printing of 'make' variables, eg:
#
#     make print-CXXFLAGS
#
print-%:
	@echo $* = $($*)
	@echo $*\'s origin is $(origin $*)


.PHONY: FORCE all personal
all:			personal			\
			git				\
			bash				\
			iterm				\
			emacs				\
			$(homebrew)			\
			python				\
			python-modules

# personal	-- Collect and store personal information in Makefile.personal
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
#     Tests for existence and offer to install if necessary.  Always
# ensure that targets are marked as up-to-date by using, in case brew
# is ever re-installed, by including '... && touch <target>':
#
#     /usr/local/bin/<target>:	$(homebrew)
#         brew install <target> && touch $@

/usr/local/bin/brew:
	@if read -p "Install homebrew? (y/n)" R		\
		&& [[ "$${R##[Yy]*}" == "" ]]; then	\
	    /usr/bin/ruby -e "$$(curl -fsSL https://raw.github.com/gist/323731)"; \
	else						\
	    echo "Please install homebrew."; false;	\
	fi

$(bazaar):		$(homebrew)
	brew install bazaar && touch $@

$(mercurial):		$(homebrew)
	brew install mercurial && touch $@

$(aspell):		$(homebrew)
	brew install aspell --lang=en && touch $@

$(gnutls):		$(homebrew)
	brew install gnutls && touch $@

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

$(emacs):		$(bazaar)			\
			$(aspell)			\
			$(gnutls)			\
			$(homebrew)
	brew install emacs --HEAD --use-git-head && touch $@

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
# into /usr/local/python#.#/site-packages/.

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
			splunk

# GitPython	-- Python git API module "git"
.PHONY: git-python
src/git-python:		FORCE
	@if [ ! -d $@ ]; then				\
	    git clone git://github.com/pjkundert/GitPython.git $@; \
	fi
#	cd $@; git checkout master; git pull origin master
	cd $@; git checkout 0.3;    git pull origin 0.3
	git submodule update --init --recursive

$(gitpypath):		src/git-python			\
			FORCE
	mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $^; python setup.py install --prefix=/usr/local

git-python:		python nose mock $(gitpypath)

# itty		-- Python webserver module "itty"
src/itty:		FORCE
	@if [ ! -d $@ ]; then				\
	    git clone git://github.com/pjkundert/itty.git $@; \
	fi
	cd $@; git pull origin master

$(ittypath):		src/itty
	mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $^; python setup.py install --prefix=/usr/local

itty:			python $(ittypath)

# web.py	-- Pytnon webserver module "web"
.PHONY: webpy
src/webpy:		FORCE
	@if [ ! -d $@ ]; then				\
	    git clone git://github.com/pjkundert/webpy.git $@; \
	fi
	cd $@; git pull origin master

$(webpypath):		src/webpy
	mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $^; python setup.py install --prefix=/usr/local

webpy:			python $(webpypath)

# wsgilog	-- Needed for logging in web.py webservers

.PHONY: wsgilog

src/wsgilog:		$(mercurial) FORCE
	@if [ ! -d $@ ]; then				\
	    hg clone $(wsgilogurl) $@;			\
	fi
	cd $@; hg pull -u

$(wsgilogpath):		src/wsgilog
	mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $^/wsgilog; python setup.py install --prefix=/usr/local

wsgilog:		python $(wsgilogpath)

# nose		-- Python unittest helper nosetests (like py.test)
.PHONY: nose
src/nose:		FORCE
	@if [ ! -d $@ ]; then				\
	    git clone $(noseurl) $@;			\
	fi
	cd $@; git pull origin master

$(nosepath):		src/nose
	mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $^; python setup.py install --prefix=/usr/local

nose:			python $(nosepath)

# mock		-- Python testing utility
.PHONY: mock
src/$(mockfile):
	curl -o $@ $(mockurl)

src/mock-$(mockvers):	src/$(mockfile)
	cd $(dir $@) && unzip -o $(mockfile)

$(mockpath):		src/mock-$(mockvers)
	mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@):$(PYTHONPATH)}; cd $^; python setup.py install --prefix=/usr/local

mock:			python $(mockpath)

# splunkpy	-- Python Splunk API
.PHONY: splunk
src/splunk-sdk-python:	FORCE
	@if [ ! -d $@ ]; then				\
	    git clone $(splunksdkurl) $@;		\
	fi
	cd $@; git pull origin master

$(splunksdkpath):	src/splunk-sdk-python
	mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $^; python setup.py install --prefix=/usr/local

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
			$(splunksdkpath)		\
			.splunkrc
