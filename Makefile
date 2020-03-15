SHELL=/bin/bash

PDFROOT:=pdf
INTROOT:=int
SRCROOT:=md

PANDOCOPT+=-d default.yaml
# pandoc additiona options
# '-M codeBlockCaptions' and '-M listings' cannot be added
# from default.yaml
PANDOCOPT+=-M codeBlockCaptions -M listings
# Generate pdf command
PANDOC_MD2PDF=pandoc $(PANDOCOPT) $< -o $@

# For debug.
# PANDOC_MD2PDF=cp $< $@
V:=@

# All dirs in srcroot.
# ..............................................................
SRCDIRS:=$(shell find $(SRCROOT) -name '.?*' -prune -o -type d)

# The dir containing file with this suffix build a pdf by concatenating the all
# md files instead of build one pdf on one md file.
# ..............................................................
CATSUFFIX:=meta
# Dirs to build single pdf.
CSUFFILES:=$(strip $(foreach dir,$(SRCDIRS),$(firstword $(wildcard $(dir)/*.$(CATSUFFIX)))))
CMDDIRS:=$(shell dirname $(CSUFFILES))
# src files
CMDSRCFILES:=$(foreach dir,$(CMDDIRS),$(wildcard $(dir)/*.md))
# Int files
CMDFILES:=$(CSUFFILES:$(SRCROOT)%.$(CATSUFFIX)=$(INTROOT)%.mdc)
# target files
CPDFFILES:=$(CMDFILES:$(INTROOT)%.mdc=$(PDFROOT)%.pdf)

# Dirs to build one pdf on one md files.
# ..............................................................
# dir list
SMDDIRS:=$(filter-out $(CMDDIRS),$(SRCDIRS))
# src files
SMDFILES:=$(foreach dir,$(SMDDIRS),$(wildcard $(dir)/*.md))
# target files
SPDFFILES:=$(SMDFILES:$(SRCROOT)%.md=$(PDFROOT)%.pdf)

################################################################
MDC?=/dev/null

.PHONY: all clean cleanall
.SECONDARY: $(CMDFILES)

all: $(SPDFFILES) $(CPDFFILES)

$(PDFROOT)/%.pdf:$(INTROOT)/%.mdc
	$(V)mkdir -p $(dir $@)
	@echo "@@@@ $< => $@"
	$(V)$(PANDOC_MD2PDF)

$(PDFROOT)/%.pdf:$(SRCROOT)/%.md
	$(V)mkdir -p $(dir $@)
	@echo "@@@@ $< => $@"
	$(V)$(PANDOC_MD2PDF)

$(INTROOT)/%.mdc: $(CMDSRCFILES)
	$(V)$(MAKE) -s $(shell dirname $@) MDC=$@

$(INTROOT)/%: $(SRCROOT)/%/*.md
	$(V)mkdir -p $@
	@echo "@@@@ $(sort $^) => $(MDC)"
	cat $(sort $^) > $(MDC)

cleanall: clean
	rm -rf $(PDFROOT)

clean:
	rm -rf $(INTROOT)

hash:
	@cat $(CMDSRCFILES) $(SMDFILES) | md5sum

debug:
	@echo "==== single markdowns"
	@echo SMDDIRS..:$(SMDDIRS)
	@echo SMDFILES.:$(SMDFILES)
	@echo SPDFFILES:$(SPDFFILES)
	@echo "==== concat markdowns"
	@echo "CSUFFILES:$(CSUFFILES)"
	@echo "CMDSRCFILES:$(CMDSRCFILES)"
	@echo "CMDDIRS..:$(CMDDIRS)"
	@echo "CMDFILES.:$(CMDFILES)"
