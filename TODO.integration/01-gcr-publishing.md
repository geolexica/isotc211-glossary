# 01 — Versioned GCR Publishing via glossarist Ruby Gem

## Goal

This repository publishes versioned GCR packages as GitHub Release assets. The glossarist gem handles the v2 → canonical conversion and packaging.

## Repository Info

| Field | Value |
|-------|-------|
| **Dataset ID / shortname** | `isotc211` |
| **Owner** | ISO/TC 211 |
| **Format** | v2 (`geolexica-v2/*.yaml` — UUID multi-document YAML) |
| **Concepts** | ~1,507 |
| **Languages** | 14 (eng, ara, zho, fin, fra, deu, kor, rus, spa, ...) |
| **GCR filename** | `isotc211-{version}.gcr` |

## Key Challenge: v2 Format

Concepts live in `geolexica-v2/` as multi-document YAML with UUID filenames. The `concepts/` directory does NOT exist in git HEAD (removed in commit `5ed9b0058`). The glossarist Ruby gem's `ConceptManager` can load these via `load_from_files` — the `package` command needs to use it.

Example file (`geolexica-v2/00061441-c9f2-5dd8-b28b-20dd94ad5ebf.yaml`):
```yaml
---
data:
  identifier: '699'
  localized_concepts:
    eng: f97c8700-4637-5d81-875d-4db604cf319b
    ara: 48aee9d4-b7ce-5aac-b00f-d4170673471b
id: 00061441-c9f2-5dd8-b28b-20dd94ad5ebf
---
data:
  definition:
  - content: application schema written in UML...
  terms:
  - type: expression
    designation: UML application schema
  language_code: eng
id: f97c8700-4637-5d81-875d-4db604cf319b
```

## Release Convention

| Trigger | Tag | Asset |
|---------|-----|-------|
| Push to `main` | `gcr-latest` (rolling) | `isotc211.gcr` |
| Tag `gcr-v2.3.0` | `gcr-v2.3.0` (pinned) | `isotc211-2.3.0.gcr` |

## Tasks

### 1. Replace publish-gcr.yml with glossarist gem

```yaml
name: publish-gcr

on:
  push:
    branches: [main]
    tags: ['gcr-v*']
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

      - run: gem install glossarist

      - name: Determine version
        id: version
        run: |
          if [[ "${GITHUB_REF}" == refs/tags/gcr-v* ]]; then
            VERSION="${GITHUB_REF_NAME#gcr-v}"
            echo "version=${VERSION}" >> "$GITHUB_OUTPUT"
            echo "tag=gcr-v${VERSION}" >> "$GITHUB_OUTPUT"
            echo "filename=isotc211-${VERSION}.gcr" >> "$GITHUB_OUTPUT"
          else
            DATEVER=$(date +%Y.%m.%d)
            echo "version=${DATEVER}" >> "$GITHUB_OUTPUT"
            echo "tag=gcr-latest" >> "$GITHUB_OUTPUT"
            echo "filename=isotc211.gcr" >> "$GITHUB_OUTPUT"
          fi

      - name: Build GCR package
        run: |
          glossarist package . -o "${{ steps.version.outputs.filename }}" \
            --shortname isotc211 \
            --version "${{ steps.version.outputs.version }}" \
            --title "ISO/TC 211 Multi-Lingual Glossary" \
            --owner "ISO/TC 211"

      - name: Publish release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ steps.version.outputs.tag }}
          name: "GCR Package ${{ steps.version.outputs.version }}"
          files: ${{ steps.version.outputs.filename }}
```

### 2. Verify glossarist gem handles v2

```bash
gem install glossarist

# Test load
ruby -e '
  c = Glossarist::ManagedConceptCollection.new
  m = Glossarist::ConceptManager.new(path: "geolexica-v2")
  m.load_from_files(collection: c)
  puts "Loaded #{c.count} concepts"
'

# Test package
glossarist package . -o isotc211-test.gcr \
  --shortname isotc211 --version 0.0.1 \
  --title "ISO/TC 211" --owner "ISO/TC 211"
glossarist validate isotc211-test.gcr
```

If `glossarist package` doesn't auto-detect `geolexica-v2/`, the gem needs v2 support added first (see `glossarist-ruby/TODO.integration/01-gcr-package-cli.md`).

### 3. Remove vocabulary-browser dependency

Delete the current workflow that checks out vocabulary-browser.

## Acceptance Criteria

- [ ] `publish-gcr.yml` uses `gem install glossarist` only
- [ ] `glossarist package` handles `geolexica-v2/` format
- [ ] GCR contains ~1,507 concepts, 14 languages
- [ ] `metadata.yaml` has `shortname: isotc211` and `version`
- [ ] Push to main → `gcr-latest` release updated
- [ ] Tag push → pinned version release created
