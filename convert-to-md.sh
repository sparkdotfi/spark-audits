#!/bin/bash
set -euo pipefail

# ---------- Tool checks ----------
command -v ocrmypdf  >/dev/null 2>&1 || { echo >&2 "ocrmypdf not installed";  exit 1; }
command -v pdftotext >/dev/null 2>&1 || { echo >&2 "pdftotext not installed (brew install poppler)"; exit 1; }

# ---------- Args ----------
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <repo-dir-1> [<repo-dir-2> ...]"
    echo "Example: $0 spark-vaults-v2 spark-gov-relay"
    exit 1
fi

# Directory of this script (spark-audits root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PARENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"   # where the repos live (../)

# pdf/ and md/ live INSIDE spark-audits
PDF_ROOT="$SCRIPT_DIR/pdf"
MD_ROOT="$SCRIPT_DIR/md"

mkdir -p "$PDF_ROOT" "$MD_ROOT"

# ---------- Per-repo processing ----------
for repo in "$@"; do
    # Repo is assumed to live one level up, e.g. ../spark-vaults-v2
    REPO_DIR="$REPO_PARENT_DIR/$repo"
    AUDIT_DIR="$REPO_DIR/audits"

    if [ ! -d "$REPO_DIR" ]; then
        echo "Skipping '$repo': repo dir '$REPO_DIR' does not exist."
        continue
    fi
    if [ ! -d "$AUDIT_DIR" ]; then
        echo "Skipping '$repo': audits dir '$AUDIT_DIR' does not exist."
        continue
    fi

    # Subdir name inside pdf/ and md/; using repo name by default
    SLUG="$repo"

    DEST_PDF_DIR="$PDF_ROOT/$SLUG"
    DEST_MD_DIR="$MD_ROOT/$SLUG"

    mkdir -p "$DEST_PDF_DIR" "$DEST_MD_DIR"

    echo "=== Repo: $repo"
    echo "    Audits: $AUDIT_DIR"
    echo "    PDFs  → $DEST_PDF_DIR"
    echo "    MD    → $DEST_MD_DIR"

    shopt -s nullglob
    found_any=false

    for pdf in "$AUDIT_DIR"/*.pdf; do
        found_any=true

        filename="$(basename "$pdf")"
        dest_pdf="$DEST_PDF_DIR/$filename"
        dest_md="$DEST_MD_DIR/${filename%.pdf}.md"

        echo "Processing: $pdf"
        echo "  → PDF copy: $dest_pdf"
        echo "  → MD out  : $dest_md"

        # Copy PDF into pdf/<slug>/
        cp "$pdf" "$dest_pdf"

        # OCR source: work on the copied PDF
        tmp="$(mktemp /tmp/ocrpdf.XXXXXX).pdf"
        src=""

        if ocrmypdf --skip-text "$dest_pdf" "$tmp"; then
            src="$tmp"
        else
            echo "  ocrmypdf failed on $dest_pdf, falling back to direct text extraction"
            rm -f "$tmp"
            src="$dest_pdf"
        fi

        # Extract text into markdown file (plain text is valid markdown)
        pdftotext -layout "$src" - | sed 's/\r$//' > "$dest_md"
        rm -f "$tmp" || true

        # Post-process the .md: wrap function blocks in ```solidity fences
        python3 - "$dest_md" << 'PY'
import sys
import re
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8", errors="ignore").splitlines()

out_lines = []
in_func = False
brace_depth = 0
buf = []

def flush_buf():
    if not buf:
        return
    out_lines.append("```solidity")
    out_lines.extend(buf)
    out_lines.append("```")
    buf.clear()

for line in text:
    if not in_func:
        # Detect the start of a function:
        #   optional leading spaces + 'function' + ... + '{' somewhere on the line
        if re.match(r"\s*function\b", line) and "{" in line:
            in_func = True
            buf.append(line)
            brace_delta = line.count("{") - line.count("}")
            brace_depth = brace_delta
            if brace_depth <= 0:
                # Single-line function or already balanced
                flush_buf()
                in_func = False
        else:
            out_lines.append(line)
    else:
        buf.append(line)
        brace_delta = line.count("{") - line.count("}")
        brace_depth += brace_delta
        if brace_depth <= 0:
            # Matching closing brace reached
            flush_buf()
            in_func = False

# If file ends while still in a function, flush what we have
if in_func and buf:
    flush_buf()

path.write_text("\n".join(out_lines) + "\n", encoding="utf-8")
PY

        echo "  Created: $dest_md"
        echo "-----------------------------"
    done

    if [ "$found_any" = false ]; then
        echo "  No PDFs found in $AUDIT_DIR"
    fi
done
