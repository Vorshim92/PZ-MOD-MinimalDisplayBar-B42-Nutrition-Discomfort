#!/usr/bin/env python3
"""
Convert PZ translation files from Lua-table .txt to flat .json format (42.15).

Walks Contents/mods/*/42.15/media/lua/shared/Translate/*/*.txt and converts
each translation file to JSON, stripping the Lua table wrapper and language
suffix from the filename.

Skips: !TranslationNotes_*, language.txt, credits.txt
"""

import chardet
import json
import os
import re
import glob

ROOT = os.path.dirname(os.path.abspath(__file__))
PATTERN = os.path.join(ROOT, "Contents", "mods", "*", "42.15", "media", "lua", "shared", "Translate", "*", "*.txt")

SKIP_FILENAMES = {"language.txt", "credits.txt"}

# Regex to match key = "value" lines (keys can contain dots, underscores, alphanumeric)
KV_RE = re.compile(r'^\s*([\w.]+)\s*=\s*"((?:[^"\\]|\\.)*)"\s*,?\s*$')


def read_file(filepath):
    """Read file with auto-detected encoding via chardet, UTF-8 tried first."""
    raw = open(filepath, "rb").read()
    # Try UTF-8 first (most common and most reliable)
    try:
        return raw.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        pass
    try:
        return raw.decode("utf-8-sig"), "utf-8-sig"
    except UnicodeDecodeError:
        pass
    # Auto-detect encoding
    detected = chardet.detect(raw)
    enc = detected.get("encoding", "latin-1") or "latin-1"
    return raw.decode(enc), enc


def parse_txt(filepath):
    """Parse a PZ Lua-table translation .txt file into a dict."""
    content, enc = read_file(filepath)
    entries = {}
    for line in content.splitlines():
            line = line.rstrip("\n\r")
            # Skip header (e.g. "ContextMenu_EN = {" or "Moodles_EN {")
            stripped = line.strip()
            if stripped == "" or stripped == "}" or stripped.endswith("= {") or stripped.endswith("{"):
                if re.match(r'^\s*\w+\s*=?\s*\{\s*$', stripped):
                    continue
                if stripped in ("", "}"):
                    continue
            m = KV_RE.match(line)
            if m:
                entries[m.group(1)] = m.group(2)
    return entries


def compute_json_filename(txt_filename, lang_folder):
    """Strip language suffix from filename and change extension to .json.

    Examples:
        ContextMenu_EN.txt, EN -> ContextMenu.json
        Sandbox_SafehousePP_IT.txt, IT -> Sandbox_SafehousePP.json
        IG_UI_EN.txt, EN -> IG_UI.json
    """
    name = os.path.splitext(txt_filename)[0]  # e.g. "ContextMenu_EN"
    suffix = f"_{lang_folder}"
    if name.endswith(suffix):
        name = name[: -len(suffix)]
    return name + ".json"


def main():
    txt_files = sorted(glob.glob(PATTERN))
    converted = 0
    skipped = 0
    errors = []

    for filepath in txt_files:
        filename = os.path.basename(filepath)

        # Skip non-translation files
        if filename in SKIP_FILENAMES or filename.startswith("!"):
            print(f"  SKIP: {filepath}")
            skipped += 1
            continue

        # Determine language folder
        lang_folder = os.path.basename(os.path.dirname(filepath))

        try:
            entries = parse_txt(filepath)
            if not entries:
                print(f"  WARN: No entries found in {filepath}")
                errors.append((filepath, "no entries"))
                continue

            json_filename = compute_json_filename(filename, lang_folder)
            json_filepath = os.path.join(os.path.dirname(filepath), json_filename)

            with open(json_filepath, "w", encoding="utf-8") as f:
                json.dump(entries, f, indent=4, ensure_ascii=False)
                f.write("\n")

            os.remove(filepath)
            converted += 1
            print(f"  OK: {filepath} -> {json_filename}")

        except Exception as e:
            print(f"  ERROR: {filepath}: {e}")
            errors.append((filepath, str(e)))

    print(f"\nDone: {converted} converted, {skipped} skipped, {len(errors)} errors")
    if errors:
        print("Errors:")
        for path, err in errors:
            print(f"  {path}: {err}")


if __name__ == "__main__":
    main()
