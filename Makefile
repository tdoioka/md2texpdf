# Shell type.
SHELL:=/bin/bash

SRCROOT := md
INTROOT := int
DSTROOT := pdf

# base files
DEFAULT_YAML:=$(realpath default.yaml)
CROSSREF_YAML:=$(realpath crossref.yaml)
TEMPLATE_TEX:=$(realpath templates/pandoc-latex-template/eisvogel.tex)
# All files dependend files
COMMON_BASE:=$(realpath Makefile) $(DEFAULT_YAML) $(CROSSREF_YAML) \
	$(TEMPLATE_TEX)

# suffixs
SG_SUF  := md
PL_SUF  := $(SG_SUF)
PDF_SUF := pdf
TEX_SUF := tex

# verbose
V := @

default: all
################################################################
# Pandoc options.
################################################################
PANDOCOPT:=
# pandoc arguments, use with template.
PANDOCOPT+=-d $(DEFAULT_YAML)
ifdef TEMPLATE_TEX
PANDOCOPT+=--template=$(TEMPLATE_TEX)
endif

# Set pandoc-crossref options
PANDOCOPT+= \
	--filter pandoc-crossref \
	-M "crossrefYaml=$(CROSSREF_YAML)"

# Set plantuml filter option
PANDOCOPT+= --filter plantuml.py

# pandoc command
PANDOC_CMD=(cd $(dir $<) && pandoc $(PANDOCOPT) $(notdir $<) -o $(abspath $(@)))
# PANDOC_CMD=(cd $(dir $<) && cp $(notdir $<) $(abspath $(@)))

################################################################
# Logging
################################################################
LOG := log
DATE_FMT :="+%F-%T.%N\(%Z\)"
define _date
	date "$(DATE_FMT) $(1): $(2)"
endef

# Logging in task command to save.
define inflog
	@$(call _date,INF,$(if $(2),$(2),----) $(1)) | tee -a $(LOG)
endef
define dbglog
	@$(if $(DEBUG),$(call _date,DBG,$(if $(2),$(2),----) $(1)) | tee -a $(LOG))
endef

# Pre task command and post task command.
define pretask
	$(call inflog,$@$(if $^$|, <= [$^$(if $(and $^,$|), )$|]),TASK)
	$(if $?,$(call dbglog,updated [$?]))
endef
define posttask
	$(call dbglog,$@,DONE)
endef

################################################################
# single buid
################################################################
SG_SRC_FILES := $(shell find $(SRCROOT) -type f -name '*.$(SG_SUF)' | grep -ve '.*\.$(PL_SUF)/')
SGR_SRC_FILES := $(shell find $(SRCROOT) \( \
	-type d -name '*.$(PL_SUF)' -o \
	-type f -name '*.$(SG_SUF)' -o \
	-name '.*' -o -name '*~' \) -prune -o -type f -print)

# inter sg files
SG_SRC_PT     := $(SRCROOT)/%.$(SG_SUF)
SG_INT_PT     := $(INTROOT)/%.$(SG_SUF)
SG_INT_FILES  := $(SG_SRC_FILES:$(SG_SRC_PT)=$(SG_INT_PT))
SGR_SRC_PT    := $(SRCROOT)/%
SGR_INT_PT    := $(INTROOT)/%
SGR_INT_FILES := $(SGR_SRC_FILES:$(SGR_SRC_PT)=$(SGR_INT_PT))
# output sg files
SG_PDF_PT     := $(DSTROOT)/%.$(PDF_SUF)
SG_PDF_FILES  := $(SG_SRC_FILES:$(SG_SRC_PT)=$(SG_PDF_PT))
SG_TEX_PT     := $(DSTROOT)/%.$(TEX_SUF)
SG_TEX_FILES  := $(SG_SRC_FILES:$(SG_SRC_PT)=$(SG_TEX_PT))

# crude dependency estimation with grep to resouce.
define sgrc_deps
$(1)_sgrc_deps := $(shell grep -le $(notdir $(1)) $(SG_SRC_FILES))
# $(1)_sgrc_outs := $$($(1)_sgrc_deps:$$(SG_SRC_PT)=$$(SG_PDF_PT))
# $(1)_sgrc_rcs  := $(1:$(SGR_SRC_PT)=$(SGR_INT_PT))
# $$($(1)_sgrc_outs): $$($(1)_sgrc_rcs)
$$($(1)_sgrc_deps:$$(SG_SRC_PT)=$$(SG_PDF_PT)): $(1:$(SGR_SRC_PT)=$(SGR_INT_PT))
endef
$(foreach file,$(sort $(SGR_SRC_FILES)),$(eval $(call sgrc_deps,$(file))))

# intermediates.
WORD=[a-zA-Z0-9][a-zA-Z0-9]*
SPACE=[ \f\n\r\t]*
$(SG_INT_FILES): $(SG_INT_PT): $(SG_SRC_PT) $(COMMON_BASE)
	$(call pretask)
	$(V)mkdir -p $(dir $@)
	$(V)sed -e 's@^```\(`*\)\($(WORD)\)@```\1{.\2}@g' \
		-e 's@^\(```[^}]*\)[}]$(SPACE)[{]\(.*\)$$@\1 \2@g' \
		$< > $@ || rm $@
	$(call posttask)

$(SGR_INT_FILES): $(SGR_INT_PT): $(SGR_SRC_PT)
	$(V)mkdir -p $(dir $@)
	$(V)ln -s $$(realpath -s --relative-to=$(dir $@) $<) $@

# outputs.
$(SG_PDF_FILES): $(SG_PDF_PT): $(SG_INT_PT)
	$(call pretask)
	$(V)mkdir -p $(dir $@)
	$(V)$(PANDOC_CMD)
	$(call posttask)
$(SG_TEX_FILES): $(SG_TEX_PT): $(SG_INT_PT)
	$(V)mkdir -p $(dir $@)
	$(V)$(PANDOC_CMD)

################################################################
# book buid
################################################################
PL_SRC_DIRS  := $(shell find $(SRCROOT) -type d -name '*.$(PL_SUF)')
PL_SRC_FILES :=
# inte pl files
PL_SRC_PT     := $(SRCROOT)/%.$(PL_SUF)
PL_INT_PT     := $(INTROOT)/%.$(PL_SUF)/all.$(SG_SUF)
PL_INT_FILES  := $(PL_SRC_DIRS:$(PL_SRC_PT)=$(PL_INT_PT))
PLR_SRC_PT    := $(SRCROOT)/%
PLR_INT_PT    := $(INTROOT)/%
# output pl files
PL_PDF_PT     := $(DSTROOT)/%.$(PDF_SUF)
PL_PDF_FILES  := $(PL_SRC_DIRS:$(PL_SRC_PT)=$(PL_PDF_PT))
PL_TEX_PT     := $(DSTROOT)/%.$(TEX_SUF)
PL_TEX_FILES  := $(PL_SRC_DIRS:$(PL_SRC_PT)=$(PL_TEX_PT))

define pl_src_files
# sources.
$(1)_src_deps := $(sort $(wildcard $(1)/*.$(SG_SUF)))
PL_SRC_FILES  += $$($(1)_src_deps)
$(1)_src_rs   := $(shell find $(1) \( \
	-type f -name '*.$(SG_SUF)' -o \
	-name '*~' -o -name '.*' \) -prune -o -type f -print)
# intermediates.
$(1)_int      := $(1:$(PL_SRC_PT)=$(PL_INT_PT))
$(1)_int_rs   := $$($(1)_src_rs:$(PLR_SRC_PT)=$(PLR_INT_PT))
# outputs.
$(1)_pdf      := $(1:$(PL_SRC_PT)=$(PL_PDF_PT))
$(1)_tex      := $(1:$(PL_SRC_PT)=$(PL_TEX_PT))
# intermediates.
$$($(1)_int): $$($(1)_src_deps)
	$$(call pretask)
	$$(V)mkdir -p $$(dir $$@)
	$$(V)cat $$(filter-out $$(COMMON_BASE),$$^) | \
		sed -e 's@^```\(`*\)\($$(WORD)\)@```\1{.\2}@g' \
		-e 's@^\(```[^}]*\)[}]$$(SPACE)[{]\(.*\)$$$$@\1 \2@g' \
		> $$@ || rm $$@
	$$(call posttask)
$$($(1)_int_rs): $$($(1)_src_rs)
	$$(V)mkdir -p $$(dir $$@)
	$$(V)ln -s $$$$(realpath -s --relative-to=$$(dir $$@) $$<) $$@
# outputs.
$$($(1)_pdf): $$($(1)_int) $$($(1)_int_rs)
	$$(call pretask)
	$$(V)mkdir -p $$(dir $$@)
	$$(V)$$(PANDOC_CMD)
	$$(call posttask)
$$($(1)_tex): $$($(1)_int) $$($(1)_int_rs)
	$$(V)mkdir -p $$(dir $$@)
	$$(V)$$(PANDOC_CMD)
endef
$(foreach srcdir,$(PL_SRC_DIRS),$(eval $(call pl_src_files,$(srcdir))))

################################################################
# utilities
################################################################
.PHONY: hash srclist run
hash: $(SG_SRC_FILES) $(PL_SRC_FILES) $(COMMON_BASE)
	@cat $^ | md5sum -

srclist:
	@echo $(SG_SRC_FILES) $(PL_SRC_FILES) $(COMMON_BASE)

run:
	$(V)$(MAKE) -C docker run

################################################################
# clean
################################################################
.PHONY: clean
distclean: clean
	-rm -rf $(DSTROOT)
clean:
	-rm -rf $(INTROOT)

################################################################
# all
################################################################
.PHONY: all
all: $(SG_PDF_FILES) $(PL_PDF_FILES)

################################################################
# debug
################################################################
define dbg
	$(info > INFO: $(1): $($(1)))
endef
.PHONY: debug
debug:
	$(info @@@@@@@@@@@@@@@@)
	$(call dbg,SG_PDF_FILES)
	$(call dbg,PL_PDF_FILES)
	$(call dbg,SG_SRC_FILES)
	$(call dbg,PL_SRC_FILES)
	$(info @@@@@@@@@@@@@@@@)
