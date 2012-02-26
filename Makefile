#
# Makefile	-- GNU 'make' for validating and building home setup
#
.PHONY: FORCE
all:			emacs			\
			homebrew


# homebrew	-- build various applications
.PHONY: homebrew
homebrew:		FORCE

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
