# On OSX the PATH variable isn't exported unless "SHELL" is also set, see: http://stackoverflow.com/a/25506676
SHELL = /bin/bash
NODE_BINDIR = ./node_modules/.bin
export PATH := $(NODE_BINDIR):$(PATH)

# Where to write the files generated by this makefile.
OUTPUT_DIR = dev

# Available locales for the app.
LOCALES = en_GB fr_FR it_IT

# Name of the generated .po files for each available locale.
LOCALE_FILES ?= $(patsubst %,$(OUTPUT_DIR)/locale/%/LC_MESSAGES/app.po,$(LOCALES))

GETTEXT_HTML_SOURCES = $(shell find $(OUTPUT_DIR) -name '*.vue' -o -name '*.html' 2> /dev/null)
GETTEXT_JS_SOURCES = $(shell find $(OUTPUT_DIR) -name '*.vue' -o -name '*.js')

# Makefile Targets
.PHONY: clean makemessages translations

clean:
	rm -f /tmp/template.pot $(OUTPUT_DIR)/translations.json

makemessages: /tmp/template.pot

translations: ./$(OUTPUT_DIR)/translations.json

# Create a main .pot template, then generate .po files for each available language.
# Thanx to Systematic: https://github.com/Polyconseil/systematic/blob/866d5a/mk/main.mk#L167-L183
/tmp/template.pot: $(GETTEXT_HTML_SOURCES)
# `dir` is a Makefile built-in expansion function which extracts the directory-part of `$@`.
# `$@` is a Makefile automatic variable: the file name of the target of the rule.
# => `mkdir -p /tmp/`
	mkdir -p $(dir $@)
	which gettext-extract
# Extract gettext strings from templates files and create a POT dictionary template.
	gettext-extract --quiet --output $@ $(GETTEXT_HTML_SOURCES)
# Extract gettext strings from JavaScript files.
	xgettext --language=JavaScript --keyword=npgettext:1c,2,3 \
		--from-code=utf-8 --join-existing --no-wrap \
		--package-name=$(shell node -e "console.log(require('./package.json').name);") \
		--package-version=$(shell node -e "console.log(require('./package.json').version);") \
		--output $@ $(GETTEXT_JS_SOURCES)
# Generate .po files for each available language.
	@for lang in $(LOCALES); do \
		export PO_FILE=$(OUTPUT_DIR)/locale/$$lang/LC_MESSAGES/app.po; \
		echo "msgmerge --update $$PO_FILE $@"; \
		mkdir -p $$(dirname $$PO_FILE); \
		[ -f $$PO_FILE ] && msgmerge --lang=$$lang --update $$PO_FILE $@ || msginit --no-translator --locale=$$lang --input=$@ --output-file=$$PO_FILE; \
		msgattrib --no-wrap --no-obsolete -o $$PO_FILE $$PO_FILE; \
	done;

$(OUTPUT_DIR)/translations.json: clean /tmp/template.pot
	mkdir -p $(OUTPUT_DIR)
	gettext-compile --output $@ $(LOCALE_FILES)