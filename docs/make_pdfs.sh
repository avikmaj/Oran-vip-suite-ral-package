#!/usr/bin/env bash
# ======================================================================
#  File   : docs/make_pdfs.sh
#  Author : AVIK MAJUMDAR
#  Project: AVIK VIP FACTORY - O-RAN VIP Suite
#  Desc   : Render Markdown docs -> A4 PDF (pandoc standalone HTML + CSS,
#           then wkhtmltopdf full-width, no smart-shrink). Full-page layout.
# ======================================================================
set -e
cd "$(dirname "$0")"
mkdir -p pdf
CSS=$(mktemp --suffix=.css)
cat > "$CSS" <<'EOF'
@page { margin: 14mm 12mm; }
body { font-family: "DejaVu Sans", Arial, sans-serif; font-size: 10.5pt;
       line-height: 1.34; color: #1a2733; max-width: 100%; margin: 0; }
h1 { font-size: 19pt; color: #12324b; border-bottom: 2px solid #12324b; padding-bottom: 3px; }
h2 { font-size: 14pt; color: #12324b; border-left: 4px solid #12324b; padding-left: 7px; margin-top: 16px; }
h3 { font-size: 12pt; color: #234; margin-top: 12px; }
table { border-collapse: collapse; width: 100%; margin: 8px 0; font-size: 9pt; }
th, td { border: 1px solid #b7c2cc; padding: 3px 6px; text-align: left; vertical-align: top; }
th { background: #12324b; color: #fff; }
tr:nth-child(even) td { background: #f2f5f7; }
code { background: #eef1f4; padding: 1px 3px; border-radius: 3px; font-size: 8.8pt; }
pre { background: #0f1b26; color: #dfe7ee; padding: 8px 10px; border-radius: 5px;
      font-size: 8.4pt; overflow-x: auto; white-space: pre-wrap; }
pre code { background: transparent; color: inherit; }
EOF

docs=(VERIFICATION_REFERENCE FUNCTIONAL_DESIGN INTEGRATION_GUIDE
      CROSS_SIMULATOR_AND_UVM_README FULL_REGRESSION_REPORT FULL_COVERAGE_REPORT
      VCS_PORTABILITY_NOTES ORAN_VIP_ARCHITECTURE ORAN_VIP_SUITE_GUIDE)
for d in "${docs[@]}"; do
  [ -f "$d.md" ] || continue
  H=$(mktemp --suffix=.html)
  pandoc "$d.md" -f markdown-yaml_metadata_block -t html5 -s \
    --metadata title="$d" -H "$CSS" -o "$H"
  wkhtmltopdf --quiet --disable-smart-shrinking --page-size A4 \
    --margin-top 12 --margin-bottom 12 --margin-left 10 --margin-right 10 \
    "$H" "pdf/$d.pdf"
  rm -f "$H"
  echo "  pdf/$d.pdf"
done
# README lives one level up
if [ -f ../README.md ]; then
  H=$(mktemp --suffix=.html)
  pandoc ../README.md -f markdown-yaml_metadata_block -t html5 -s \
    --metadata title="README" -H "$CSS" -o "$H"
  wkhtmltopdf --quiet --disable-smart-shrinking --page-size A4 \
    --margin-top 12 --margin-bottom 12 --margin-left 10 --margin-right 10 \
    "$H" "pdf/README.pdf"
  rm -f "$H"; echo "  pdf/README.pdf"
fi
rm -f "$CSS"
echo "PDF_DONE"
