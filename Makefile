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
emacs:			.emacs			\
			emacs-24		\
			src/emacs-prelude	\
			src/org-mode		\
			FORCE


emacs-24:		/usr/local/bin/emacs-24.0

/usr/local/bin/emacs-24.0:	bazaar
	brew install emacs --HEAD

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
/usr/local/bin/bzr:
	brew install bazaar