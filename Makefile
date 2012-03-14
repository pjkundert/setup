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
aspell			= /usr/local/bin/aspell
gnutls			= /usr/local/bin/gnutls-serv
pyvers			= $(shell python --version 2>&1 | sed -ne '/Python/ s/.*\([0-9]\.[0-9]\)\..*/\1/p' )
gitpyvers		= 0.3.1
gitpypath		= /usr/local/lib/python$(pyvers)/site-packages/GitPython-$(gitpyvers)-py$(pyvers).egg
ittyvers		= 0.8.1
ittypath		= /usr/local/lib/python$(pyvers)/site-packages/itty-$(ittyvers)-py$(pyvers).egg-info
webpyvers		= 0.37
webpypath		= /usr/local/lib/python$(pyvers)/site-packages/web.py-$(webpyvers)-py$(pyvers).egg-info

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

$(aspell):		$(homebrew)
	brew install aspell --lang=en && touch $@

$(gnutls):		$(homebrew)
	brew install aspell --lang=en && touch $@

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

.PHONY: python git-python itty webpy

python:
	@if ! python --version 2>&1 | grep -q "2.[67]"; then \
	    echo "Need Python 2.[67]; found: $(shell python --version 2>&1 )"; \
	fi

python-modules:		git-python			\
			itty				\
			webpy

# GitPython	-- Python git API module "git"
src/git-python:		FORCE
	git clone git://github.com/pjkundert/GitPython.git $@ || true
	cd $@; git pull origin master

$(gitpypath):		src/git-python
	mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $^; python setup.py install --prefix=/usr/local

git-python:		python $(gitpypath)

# itty		-- Python webserver module "itty"
src/itty:		FORCE
	git clone git://github.com/pjkundert/itty.git $@ || true
	cd $@; git pull origin master

$(ittypath):		src/itty
	mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $^; python setup.py install --prefix=/usr/local

itty:			python $(ittypath)

# web.py	-- Pytnon webserver module "web"
src/webpy:		FORCE
	git clone git://github.com/pjkundert/webpy.git $@ || true
	cd $@; git pull origin master

$(webpypath):		src/webpy
	mkdir -p $(dir $@)
	export PYTHONPATH=$(dir $@); cd $^; python setup.py install --prefix=/usr/local

webpy:			python $(webpypath)
