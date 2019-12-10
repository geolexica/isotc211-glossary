SHELL := /bin/bash
TERMBASE_VERSION := $(shell yq r metadata.yaml version)
TERMBASE_XLSX_PATH := $(shell yq r metadata.yaml filename)

all: tc211-termbase.yaml tc211-termbase.meta.yaml tc211-termbase.xlsx concepts

clean:
	rm -rf concepts tc211-termbase.yaml tc211-termbase.xlsx tc211-termbase.meta.yaml

tc211-termbase.xlsx:
	cp '${TERMBASE_XLSX_PATH}' tc211-termbase.xlsx

tc211-termbase.yaml tc211-termbase.meta.yaml concepts: tc211-termbase.xlsx
	bundle exec tc211-termbase-xlsx2yaml $<;

update-init:
	git submodule update --init

update-modules:
	git submodule foreach git pull origin master

.PHONY: all clean update-init update-modules
