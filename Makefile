# Fixed assignments.
# ..............................................................
# Shell type.
SHELL:=/bin/bash
# OLD_SHELL := $(SHELL)
# SHELL = $(if $@$^,$(warning [Making: $@] [Dep: $^] [Changed: $?]),)$(OLD_SHELL)

# Base directories.
SRCROOT:=md
INTROOT:=int
DSTROOT:=pdf

# base files.
DEFAULT_YAML:=$(realpath default.yaml)
CROSSREF_YAML:=$(realpath crossref.yaml)
TEMPLATE_TEX:=$(realpath templates/pandoc-latex-template/eisvogel.tex)

# All files dependend files
COMMON_BASE:=$(realpath Makefile) $(DEFAULT_YAML) $(CROSSREF_YAML) \
	$(TEMPLATE_TEX)

# Pandoc options.
# ..............................................................
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

# Book directory suffix
BS:=md

# pandoc command
PANDOC_CMD=(cd $(dir $<) && pandoc $(PANDOCOPT) $(notdir $<) -o $(abspath $(@)))
# PANDOC_CMD=(cd $(dir $<) && cp $(notdir $<) $(abspath $(@)))

# output suffix
OUTSUFFIXS:=pdf
# OUTSUFFIXS:=pdf tex

# Silent
V?=@

# default rule
default: all

#################################################################
# Automatic calculation below here
#################################################################

# Book DIRS to create one PDF.
BMD_S_DIRS:=$(shell find $(SRCROOT) -name '.?*' \
	-prune -o -type d -name "*.$(BS)" ! -path "*.$(BS)/*" -print)
# Book MD intermediate files.
BMD_I_FILES:=$(foreach dir,$(BMD_S_DIRS),$(dir:$(SRCROOT)%=$(INTROOT)%/book.md))
# Book pdf files.
BOUT_D_FILES:=$(foreach \
	suf,$(OUTSUFFIXS),$(BMD_S_DIRS:$(SRCROOT)%.$(BS)=$(DSTROOT)%.$(suf)))

# Single md files dir.
SMD_S_DIRS:=$(shell find $(SRCROOT) \( -name '.?*' -o -name "*.$(BS)" \) \
	-prune -o -type d -print)
# Single md files.
SMD_S_FILES:=$(shell find $(SMD_S_DIRS) -maxdepth 1 -type f -name '*.md')
# Single pdf files.
SOUT_D_FILES:=$(foreach \
	suf,$(OUTSUFFIXS),$(SMD_S_FILES:$(SRCROOT)%.md=$(DSTROOT)%.$(suf)))

# All source files.
SRC_FILES:=$(SMD_S_FILES)
SRC_DIRS:=$(shell find $(SRCROOT) -name '.?*' -prune -o -type d -print)

#################################################################
# Macro
#################################################################
# BMD_S_DIRS => BMD_I_FILES => BMD_D_FILES
# $1 = A book directory name with $(BS) suffix
define book_gen_rule
# Copy assets files to intermediate. (for estensible)
# Rule for $(SRCROOT)/**/%.$(BS)/**/% => $(INTROOT)/**/%.$(BS)/**/%
INT_DIR_$(1):=$(1:$(SRCROOT)/%=$(INTROOT)/%)
$$(INT_DIR_$(1))/%:$(1)/% $(COMMON_BASE)
	@echo "@@@@   SUBSGEN [$$@] <= [$$<]"
	@$$(V)mkdir -p $$(dir $$@)
	@$$(V)cp $$< $$@
# Concatnate md files to intermediate.
# Rule for $(SRCROOT)/**/%.$(BS)/*.md => $(INTROOT)/**/%.$(BS)/book.md
SRC_MDS_$(1):=$(shell find $(1) -maxdepth 1 -type f -name "*.md")
INT_MD_$(1):=$$(INT_DIR_$(1))/book.md
$$(INT_MD_$(1)):$$(SRC_MDS_$(1)) $(COMMON_BASE)
	@echo "@@@@   IMDGEN [$$@] <= [$$(SRC_MDS_$(1))]"
	$$(V)mkdir -p $$(dir $$@)
	$$(V)if [[ -n "$$(SRC_MDS_$(1))" ]]; then\
		cat $$(SRC_MDS_$(1)) > $$@;\
	else\
		touch $$@;\
	fi
# Build pdf.
# Rule for $(INTROOT)/**/%.$(BS)/book.md => $(DSTROOT)/**/%.pdf
SRC_SUBS_$(1):=$(shell find $(1) -mindepth 2 -type f)
INT_SUBS_$(1):=$$(SRC_SUBS_$(1):$(SRCROOT)/%=$(INTROOT)/%)
DST_OUT_$(1):=$(foreach \
	suf,$(OUTSUFFIXS),$(1:$(SRCROOT)/%.$(BS)=$(DSTROOT)/%.$(suf)))
$$(DST_OUT_$(1)):$$(INT_MD_$(1)) $$(INT_SUBS_$(1)) $(COMMON_BASE)
	@echo "@@@@ PDFGEN [$$@] <= [$$(INT_MD_$(1)) $$(INT_SUBS_$(1))]"
	$$(V)mkdir -p $$(dir $$@)
	$$(V)$$(PANDOC_CMD)

# Union of source files for hash calculation.
SRC_FILES+=$$(SRC_SUBS_$(1)) $$(SRC_MDS_$(1))

# for Debugging
debug_$(1):
	@echo "@@@@ debug_$(1) ::"
	@echo "@@@@ INT_DIR   : $$(INT_DIR_$(1))"
	@echo "@@@@ SRC_MDS   : $$(SRC_MDS_$(1))"
	@echo "@@@@ INT_MD    : $$(INT_MD_$(1))"
	@echo "@@@@ SRC_SUBS  : $$(SRC_SUBS_$(1))"
	@echo "@@@@ INT_SUBS  : $$(INT_SUBS_$(1))"
	@echo "@@@@ DST_OUT   : $$(DST_OUT_$(1))"
endef

define single_gen_rule
$(DSTROOT)/%.$(1):$(SRCROOT)/%.$(BS) $(COMMON_BASE)
	@echo "@@@@ PDFGEN [$$@] <= [$$<]"
	$$(V)mkdir -p $$(dir $$@)
	$$(V)$$(PANDOC_CMD)
endef
################################################################
# Rules
################################################################
.PHONY: default all debug force $(DEBUG_TARGET)

all: $(BOUT_D_FILES) $(SOUT_D_FILES)
	@echo "@@@@ FINISHED [$@] <= [$^]"

# Rule generate for
# Rule for $(SRCROOT)/**/%.$(BS)/**/% => $(INTROOT)/**/%.$(BS)/**/%
# Rule for $(SRCROOT)/**/%.$(BS)/*.md => $(INTROOT)/**/%.$(BS)/book.md
# Rule for $(INTROOT)/**/%.$(BS)/book.md => $(DSTROOT)/**/%.{$(OUTSUFFIXS)}
$(foreach dir,$(BMD_S_DIRS),$(eval $(call book_gen_rule,$(dir))))

# create single pdf
# Rule for $(SRCROOT)/**/%.md => $(DSTROOT)/**/%.{$(OUTSUFFIXS)}
$(foreach suf,$(OUTSUFFIXS),$(eval $(call single_gen_rule,$(suf))))

cleanall: clean
	rm -rf $(DSTROOT)

clean:
	rm -rf $(INTROOT)

hash: $(SRC_FILES) $(COMMON_BASE)
	@cat $^ | md5sum -

srclist:
	@echo $(SRC_DIRS) $(SRC_FILES) $(COMMON_BASE)

# Debug target
DEBUG_TARGET:=$(foreach dir,$(BMD_S_DIRS),debug_$(dir))
debug: $(DEBUG_TARGET)
	@echo "@@@@ BMD_S_DIRS    : $(BMD_S_DIRS)"
	@echo "@@@@ BMD_I_FILES   : $(BMD_I_FILES)"
	@echo "@@@@ BOUT_D_FILES  : $(BOUT_D_FILES)"
	@echo "@@@@ SMD_S_DIRS    : $(SMD_S_DIRS)"
	@echo "@@@@ SMD_S_FILES   : $(SMD_S_FILES)"
	@echo "@@@@ SOUT_D_FILES  : $(SOUT_D_FILES)"
	@echo "@@@@ SRC_FILES     : $(SRC_FILES)"
	@echo "@@@@ DEBUG_TARGET  : $(DEBUG_TARGET)"
