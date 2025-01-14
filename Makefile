# Minimal makefile for Sphinx documentation
#
# You can set these variables from the command line.
LOCALE          ?= fr
PUBHOST         ?= club1.fr
PUBDIR          ?= /var/www/docs

ifneq "$(LOCALE)" "fr"
override NOTFR   = 1
else
override NOTFR   =
endif

SPHINXLANG       = -D language=$(LOCALE)
SPHINXOPTS      += -a
SPHINXBUILD     ?= sphinx-build
SPHINXBUILDERS   = html dirhtml singlehtml epub latex text man texinfo
SPHINXCMDS       = pickle json htmlhelp changes xml pseudoxml linkcheck doctest coverage
SOURCEDIR        = .
BUILDDIR         = _build
MDFILES          = index.md $(shell find . -type f -name '*.md')
LOCALES          = en
LOCALEFILES      = $(LOCALES:%=locales/%/LC_MESSAGES/package.po)

# Put it first so that "make" without argument is like "make help".
help:
	$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $O

.PHONY: help clean update-po gettext latexpdf info publish $(SPHINXBUILDERS) $(SPHINXCMDS)

update-po: $(LOCALEFILES)

gettext: locales/package.pot

$(LOCALEFILES): locales/%/LC_MESSAGES/package.po: locales/package.pot
	sphinx-intl update -p $(<D) -l $*
	@touch $@

locales/package.pot: $(MDFILES)
	$(SPHINXBUILD) -b gettext "$(SOURCEDIR)" locales $(SPHINXOPTS) $O
	@touch $@

latexpdf: latex
	$(MAKE) -C $(BUILDDIR)/latex/$(LOCALE)

info: texinfo
	$(MAKE) -C $(BUILDDIR)/texinfo/$(LOCALE)

publish:
	rsync -av --del --exclude='.*' _build/html/ $(USER)@$(PUBHOST):$(PUBDIR)

# Shinx commands that need locales (builders).
$(SPHINXBUILDERS): $(if $(NOTFR),locales/$(LOCALE)/LC_MESSAGES/package.po)
	$(SPHINXBUILD) -b $@ "$(SOURCEDIR)" "$(BUILDDIR)/$@/$(LOCALE)" $(SPHINXLANG) $(SPHINXOPTS) $O

# Other Sphinx commands for autocompletion
$(SPHINXCMDS):
	$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $O

clean:
	rm -f locales/*/LC_MESSAGES/package.mo
	rm -rf locales/.doctrees
	rm -rf $(BUILDDIR)/*
