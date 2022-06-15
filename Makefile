# Minimal makefile for Sphinx documentation
# heavily customized for internationalization.
#
# You can set these variables from the command line.

LOCALES         := en
LOCALEDIR       := _locales
LOCALEFILES     := $(LOCALES:%=$(LOCALEDIR)/%/LC_MESSAGES/package.po) $(LOCALES:%=$(LOCALEDIR)/%/LC_MESSAGES/sphinx.po)
UPDATEPO        := $(filter update-po,$(MAKECMDGOALS))

DATE                := $(shell date +%F)
REVISION            := $(shell git describe --always --dirty)

export AUTHORS      := $(shell awk '{printf t $$0; t=", "}' AUTHORS)
export PACKAGE      := CLUB1
export VERSION      := main
export RELEASE      := $(DATE)-g$(REVISION)
export EMAIL        := nicolas@club1.fr

export LOCALE       := fr
export LANGUAGES    := $(LOCALE) $(LOCALES)
export LATEXMKOPTS  := -file-line-error $(if $(CI),,-quiet)

SPHINXLANG      := -D language=$(LOCALE)
SPHINXOPTS      += -a --color $(if $(CI),,-q)
SPHINXBUILD     ?= sphinx-build
SPHINXBUILDERS  := html dirhtml singlehtml epub latex text man texinfo
SPHINXLBUILDERS := $(foreach b,$(SPHINXBUILDERS),$(LANGUAGES:%=$b/%))
SPHINXCMDS      := gettext changes xml pseudoxml linkcheck
SOURCEDIR       := .
BUILDDIR        := _build
DIRS            := $(SPHINXBUILDERS:%=$(BUILDDIR)/%) $(SPHINXLBUILDERS:%=$(BUILDDIR)/%)
ALL             := $(LANGUAGES:%=all/%)

PUBHOST         ?= club1.fr
PUBDIR          ?= /var/www/docs

# Put it first so that "make" without argument is like "make help".
help:
	$(SPHINXBUILD) -M help $(SOURCEDIR) $(BUILDDIR) $(SPHINXOPTS) $O

.PHONY: help clean update-po latexpdf info publish $(ALL) $(SPHINXBUILDERS) $(SPHINXLBUILDERS) $(SPHINXCMDS)

$(DIRS):
	mkdir -p $@

update-po: $(LOCALEFILES);

%.mo: %.po
	msgfmt -o $@ $<

.SECONDEXPANSION:
$(LOCALEFILES): $(LOCALEDIR)/%.po: $(if $(UPDATEPO),$(LOCALEDIR)/$$(*F).pot)
	msgmerge -q --previous --update $@ $< --backup=none -w 79
	@touch $@

$(LOCALEDIR)/package.pot $(LOCALEDIR)/sphinx.pot: $(LOCALEDIR)/%.pot: $(BUILDDIR)/gettext/%.pot
	xgettext $< -o $@ -x $(LOCALEDIR)/exclude.po -w 79 \
	--copyright-holder='$(AUTHORS)' --package-name='$(PACKAGE)' \
	--package-version='$(VERSION)' --msgid-bugs-address='$(EMAIL)'

$(BUILDDIR)/gettext/%.pot: gettext;

latexpdf info: %: $(LANGUAGES:%=\%/%);

$(LANGUAGES:%=latexpdf/%): latexpdf/%: latex/%
	cat _templates/style.xdy >> $(BUILDDIR)/$</sphinx.xdy
	max_print_line=110 $(MAKE) -C $(BUILDDIR)/$<

$(LANGUAGES:%=info/%): info/%: texinfo/%
	$(MAKE) -C $(BUILDDIR)/$<

$(BUILDDIR)/html/index.html: _templates/index.html | $(BUILDDIR)/html
	cp $< $@

publish:
	rsync -av --del --exclude='.*' _build/html/ $(USER)@$(PUBHOST):$(PUBDIR)

# Build the full docs ready to be published for a language
all: $(ALL) $(BUILDDIR)/html/index.html;
$(ALL): export DOWNLOADS = club1-$(@F)-$(RELEASE).pdf club1-$(@F)-$(RELEASE).epub
$(ALL): all/%: html/% latexpdf/% epub/% | $(BUILDDIR)/html/%
	cp $(BUILDDIR)/latex/$*/club1.pdf $(BUILDDIR)/html/$*/club1-$*-$(RELEASE).pdf
	cp $(BUILDDIR)/epub/$*/CLUB1.epub $(BUILDDIR)/html/$*/club1-$*-$(RELEASE).epub

# Shinx builders that builds localized versions.
$(filter-out html,$(SPHINXBUILDERS)): %: $(LANGUAGES:%=\%/%);

html: $(LANGUAGES:%=html/%) $(BUILDDIR)/html/index.html

# Localized Sphinx builders
.SECONDEXPANSION:
$(SPHINXLBUILDERS): $$(if $$(filter fr,$$(@F)),,$(LOCALEDIR)/$$(@F)/LC_MESSAGES/package.mo $(LOCALEDIR)/$$(@F)/LC_MESSAGES/sphinx.mo)
	LOCALE=$(@F) $(SPHINXBUILD) -b $(@D) -d $(BUILDDIR)/doctrees/$(@F) $(SOURCEDIR) $(BUILDDIR)/$(@D)/$(@F) $(SPHINXOPTS) $O

# Other Sphinx commands for autocompletion
$(SPHINXCMDS):
	$(SPHINXBUILD) -M $@ $(SOURCEDIR) $(BUILDDIR) $(SPHINXOPTS) $O

clean:
	rm -f $(LOCALEDIR)/*/LC_MESSAGES/*.mo
	rm -f *.log
	rm -rf $(BUILDDIR)/*
	rm -rf _ext/__pycache__

.PHONY: .FORCE
.FORCE:
