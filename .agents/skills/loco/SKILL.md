---
name: loco
description: Manage localization keys in Localise.biz and download the latest .xcstrings catalog. Use when updating localized strings or refreshing translation files.
compatibility: Requires curl and internet access to localise.biz.
---

# Loco Localizations

## When to use this skill

Use this skill when you need to:

- add a new localization key to Localise.biz
- set translations for supported languages (listed in `languages.conf`)
- pull the latest translated `.xcstrings` catalog into the project

## Prerequisites

1. Work from the repository root.
2. Ensure `curl` is available (ships with macOS).
3. Ensure `LOCO_API_KEY` and `LOCO_EXPORT_KEY` are set (via `.env` or environment).

## Add a new localization key

Run:

```bash
.agents/skills/loco/scripts/add-localization-key "section.key_name" --ru "Текст" --en "Text" --ar "نص" --tr "Metin"
```

The source language flag (first language in `languages.conf`) is required. Other languages are optional.

Behavior:

- creates the asset if it does not exist
- skips creation if the key already exists
- writes provided translations per locale
- exits with non-zero status if any API call fails

## Add a plural localization key

When a key needs singular ("one") and plural ("other") forms, use the `--plural` flag along with `--{locale}-other` arguments:

```bash
.agents/skills/loco/scripts/add-localization-key "section.item_count" --plural \
  --ru "%d элемент" --ru-other "%d элементов" \
  --en "%d item" --en-other "%d items"
```

Behavior:

- creates the base asset for the "one" form (same as a simple key)
- creates a linked plural asset `{key}_other` via Loco's plural API
- sets translations on both the "one" and "other" assets
- source language `--*-other` flag is required when `--plural` is set; other locales are optional
- exits with non-zero status if any API call fails

## Download latest localization files

Run:

```bash
.agents/skills/loco/scripts/download-localizations --resources-dir "path/to/Resources"
```

Behavior:

- downloads Localise.biz `.xcstrings` catalog (single JSON file with all locales, including plurals)
- auto-detects and converts plural keys that don't reference a number to substitutions format (avoids Xcode warnings)
- saves `Localizable.xcstrings` in the specified resources directory
- exits with non-zero status on network/API failures

## Delete a localization key

Run:

```bash
.agents/skills/loco/scripts/delete-localization-key "section.obsolete_key"
```

Behavior:

- permanently deletes the asset and all locale translations from Localise.biz
- exits non-zero on API/network failures

## Typical workflow

1. Add/update key translations with `scripts/add-localization-key`.
2. Pull updated `.xcstrings` catalog with `scripts/download-localizations`.
3. Review changes with `git status` and `git diff` before committing.

## Files in this skill

- `languages.conf` — supported languages (source language first)
- `scripts/add-localization-key`
- `scripts/download-localizations`
- `scripts/postprocess-xcstrings`
- `scripts/delete-localization-key`
