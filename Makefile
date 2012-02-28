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

.PHONY: FORCE
all:			bash			\
			iterm			\
			emacs			\
			homebrew		\

# bash		-- set up bash, etc.
.PHONY: bash
bash:			.git-completion.bash

.git-completion.bash:
	curl -o $@ https://raw.github.com/git/git/master/contrib/completion/git-completion.bash

# iterm		-- make sure its installed, and configured
.PHONY: iterm
iterm:			Library//Preferences/com.googlecode.iterm2.plist \

Library//Preferences/com.googlecode.iterm2.plist:\
			FORCE
	@if [ ! -r $@ ]; then			\
	    echo "*** Install iTerm2!"; false;	\
	fi
	@if ! plutil -convert xml1 -o - $@ | grep -q "<key>0xd-0x60000</key>"; then \
	    echo "*** Configure iTerm2 Profiles/Keys <shift-control-return> to Send Hex: 0x03 0x18 0x08"; \
	fi

# homebrew	-- build various applications
.PHONY: homebrew
homebrew:		/usr/local/bin/brew

/usr/local/bin/brew:	FORCE
	if [ ! -r $@a ]; then			\
	    echo 'Installing homebrew...";	\
	    /usr/bin/ruby -e "$(curl -fsSL https://raw.github.com/gist/323731)"; \
	fi

# emacs 24.0	-- editor and any necessary components
.PHONY: emacs emacs-24
emacs:			.emacs.d		\
			emacs-24		\
			src/emacs-prelude	\
			aspell			\
			FORCE

emacs-24:		/usr/local/bin/emacs	\
			FORCE
	@if ! which emacs | grep -q /usr/local/bin/emacs; then \
		echo "Add /usr/local/bin to beginning of PATH; adjust /etc/paths, or .bash_profile"; \
	fi
	@if ! emacs --version | grep -q "GNU Emacs 24"; then \
		echo "Version 24 of emacs needed; found: $(shell emacs --version | head -1 )"; \
	fi

/usr/local/bin/emacs:	bazaar
	brew install emacs --HEAD

.emacs.d:
	git clone git://github.com/pjkundert/emacs-prelude.git $@


# org-mode 7.8.03
#     Builds only if we don't see the compiled .elc files

.PHONY: org-mode
org-mode:		src/org-mode/lisp/org-install.elc

src/org-mode:
	git clone git://orgmode.org/org-mode.git $@
	cd $@; git checkout release_7.8.03
src/org-mode/lisp/org-install.elc:		\
			src/org-mode
	cd $^; make

# Misc. utilities
.PHONY: bazaar
bazaar:			/usr/local/bin/bzr
aspell:			/usr/local/bin/aspell

/usr/local/bin/bzr:
	brew install bazaar

/usr/local/bin/aspell:
	brew install aspell --lang=en
