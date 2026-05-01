# 01 — Versioned GCR Publishing via glossarist Ruby Gem

## Goal

This repository publishes versioned GCR packages as GitHub Releases, triggered by version tags. The glossarist gem handles the v2 → canonical conversion and packaging.

## Repository Info

| Field | Value |
|-------|-------|
| **Dataset ID / shortname** | `isotc211` |
| **Owner** | ISO/TC 211 |
| **Format** | v2 (`geolexica-v2/*.yaml` — UUID multi-document YAML) |
| **Concepts** | ~1,507 |
| **Languages** | 14 (eng, ara, zho, fin, fra, deu, kor, rus, spa, ...) |
| **GCR filename** | `isotc211-{version}.gcr` |

## Release Convention

| Trigger | Tag | Assets |
|---------|-----|--------|
| Push tag `v2.3.0` | `v2.3.0` | `isotc211-2.3.0.gcr` + `isotc211.gcr` |
| workflow_dispatch | `v{version}` | `isotc211-{version}.gcr` + `isotc211.gcr` |

### Download URLs
```
https://github.com/geolexica/isotc211-glossary/releases/latest/download/isotc211.gcr
https://github.com/geolexica/isotc211-glossary/releases/download/v2.3.0/isotc211-2.3.0.gcr
```

## How to publish

```bash
git tag v2.3.0
git push origin v2.3.0
```

## Key: v2 Format Handling

Concepts live in `geolexica-v2/` as multi-document YAML with UUID filenames. The `glossarist package` command auto-detects this and converts via `ConceptManager`.

## Acceptance Criteria

- [ ] `publish-gcr.yml` triggers on `v*` tag push only
- [ ] `glossarist package` handles `geolexica-v2/` format
- [ ] Release has both versioned and unversioned GCR assets
- [ ] `metadata.yaml` has `shortname: isotc211` and `version`
- [ ] No checkout of vocabulary-browser
