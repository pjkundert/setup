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
bazaar			= /usr/local/bin/bzr
aspell			= /usr/local/bin/aspell


.PHONY: FORCE all
all:			bash				\
			iterm				\
			emacs				\
			$(homebrew)			\

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
	@if [ ! -r $@ ]; then				\
	    echo "*** Install iTerm2!"; false;		\
	fi
	@if ! plutil -convert xml1 -o - $@	\
		| sed -ne '/<key>0xd-0x20000/,/<\/dict>/{p;}' \
		| grep -q "<string>\[SR</string>"; then \
	    echo "*** Configure iTerm2 Profiles/Keys <shift-return> to Send Escape Code \[SR"; \
	fi
	@if ! plutil -convert xml1 -o - $@	\
		| sed -ne '/<key>0xd-0x40000/,/<\/dict>/{p;}' \
		| grep -q "<string>\[CR</string>"; then \
	    echo "*** Configure iTerm2 Profiles/Keys <control-return> to Send Escape Code \[CR"; \
	fi
	@if ! plutil -convert xml1 -o - $@	\
		| sed -ne '/<key>0xd-0x60000/,/<\/dict>/{p;}' \
		| grep -q "<string>\[CSR</string>"; then \
	    echo "*** Configure iTerm2 Profiles/Keys <control-shift-return> to Send Escape Code \[CSR"; \
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

/usr/local/bin/bzr:	$(homebrew)
	brew install bazaar && touch $@

/usr/local/bin/aspell:	$(homebrew)
	brew install aspell --lang=en && touch $@

# emacs 24.0	-- editor and any necessary components
#
#     Check out pjkundert/emacs-prelude, branch 'hardcons', and
# always execute the personal/Makefile.

.PHONY: emacs emacs-24
emacs:			.emacs.d/personal		\
			emacs-24			\
			src/emacs-prelude		\
			$(aspell)			\
			FORCE

emacs-24:		/usr/local/bin/emacs		\
			FORCE
	@if ! which emacs | grep -q /usr/local/bin/emacs; then \
		echo "Add /usr/local/bin to beginning of PATH; adjust /etc/paths, or .bash_profile"; \
	fi
	@if ! emacs --version | grep -q "GNU Emacs 24"; then \
		echo "Version 24 of emacs needed; found: $(shell emacs --version | head -1 )"; \
	fi

/usr/local/bin/emacs:	$(bazaar)			\
			$(homebrew)
	brew install emacs --HEAD && touch $@

.emacs.d:
	git clone git://github.com/pjkundert/emacs-prelude.git $@
	cd $@; git checkout hardcons

.emacs.d/personal:	.emacs.d
	cd $@; make
