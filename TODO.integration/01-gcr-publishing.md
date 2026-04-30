# 01 — GCR Package Publishing via glossarist Ruby Gem

## Goal

This repository publishes a GCR package as a GitHub Release asset on every push to `main`. The vocabulary-browser downloads this GCR to build www.geolexica.org.

## Repository Info

- **Dataset ID:** `isotc211`
- **Owner:** ISO/TC 211
- **Concept format:** v2 (`geolexica-v2/*.yaml` — UUID-named multi-document YAML with concept + localized concepts per file)
- **Concept count:** ~1,507
- **Languages:** eng, ara, zho, fin, fra, deu, kor, rus, spa (14 total)
- **GCR release asset:** `isotc211.gcr`

## Current State

- `.github/workflows/publish-gcr.yml` checks out vocabulary-browser and uses its Node.js script
- Concepts are in `geolexica-v2/` directory (UUID YAML format) — NOT in `concepts/`
- The `concepts/` directory does NOT exist in git HEAD (was removed in commit `5ed9b0058`)
- A temporary Node.js converter (`package-dataset.mjs`) was used to build GCR — this must be replaced with the glossarist Ruby gem

## Key Challenge: v2 Format

The `geolexica-v2/` directory contains files like `00061441-c9f2-5dd8-b28b-20dd94ad5ebf.yaml`. Each file is a multi-document YAML:

```yaml
---
data:
  identifier: '699'
  localized_concepts:
    eng: f97c8700-4637-5d81-875d-4db604cf319b
    ara: 48aee9d4-b7ce-5aac-b00f-d4170673471b
    ...
id: 00061441-c9f2-5dd8-b28b-20dd94ad5ebf

---
data:
  definition:
  - content: application schema written in UML...
  terms:
  - type: expression
    normative_status: preferred
    designation: UML application schema
  language_code: eng
id: f97c8700-4637-5d81-875d-4db604cf319b
```

The glossarist Ruby gem's `ConceptManager` already handles this format via `load_from_files`. The `glossarist package` CLI needs to use it.

## Tasks

### 1. Verify glossarist Ruby gem handles v2 format

```bash
gem install glossarist

# Test loading v2 concepts
ruby -e '
  collection = Glossarist::ManagedConceptCollection.new
  collection.load_from_files("/path/to/isotc211-glossary/geolexica-v2")
  puts "Loaded #{collection.count} concepts"
'

# Test packaging
glossarist package /path/to/isotc211-glossary -o isotc211.gcr \
  --title "ISO/TC 211 Multi-Lingual Glossary" \
  --owner "ISO/TC 211"
```

If `glossarist package` doesn't auto-detect the v2 directory, the gem needs updating first (see `glossarist-ruby/TODO.integration/01-gcr-package-cli.md`).

### 2. Replace publish-gcr.yml

```yaml
name: publish-gcr

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  publish-gcr:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'

      - name: Install glossarist
        run: gem install glossarist

      - name: Build GCR package
        run: |
          glossarist package . -o isotc211.gcr \
            --title "ISO/TC 211 Multi-Lingual Glossary" \
            --owner "ISO/TC 211"

      - name: Update gcr-latest release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: gcr-latest
          name: "GCR Package (latest)"
          body: "Auto-generated GCR package. Updated on push to main."
          files: isotc211.gcr
```

### 3. Verify GCR content

```bash
glossarist validate isotc211.gcr
# Should show ~1,507 concepts, 14 languages
```

### 4. Verify downstream

After publishing, confirm vocabulary-browser can download and use the GCR:
```bash
# In vocabulary-browser
npm run fetch-datasets  # should download isotc211.gcr from release
npm run generate-data   # should generate 1,507 concepts
```

## GCR Download URL

```
https://github.com/geolexica/isotc211-glossary/releases/download/gcr-latest/isotc211.gcr
```

## Acceptance Criteria

- [ ] `publish-gcr.yml` uses `gem install glossarist` (no Node.js, no vocabulary-browser checkout)
- [ ] `glossarist package` handles `geolexica-v2/` format
- [ ] GCR contains ~1,507 concepts with 14 languages
- [ ] GCR uploaded to `gcr-latest` release
- [ ] vocabulary-browser fetch + generate works with the new GCR
