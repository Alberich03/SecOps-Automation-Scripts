#!/bin/bash

# ==============================
# Wapiti Automated Scan Script
# Author: AubreyN SOC
# ==============================

TARGET_FILE="$1"

if [[ -z "$TARGET_FILE" || ! -f "$TARGET_FILE" ]]; then
    echo "Usage: $0 targets.txt"
    exit 1
fi

# ---- REQUIRE wkhtmltopdf ----
if ! command -v wkhtmltopdf >/dev/null 2>&1; then
    echo "[!] wkhtmltopdf not found in PATH. Please install it to generate PDF reports."
    exit 1
fi

# Main execution timestamp for the master folder
TIMESTAMP=$(date +"%d%m%Y_%H%M%S")
BASE_OUTPUT="wapiti_results_$TIMESTAMP"
LOG_DIR="$BASE_OUTPUT/logs"

mkdir -p "$BASE_OUTPUT" "$LOG_DIR"

echo "[+] Target file : $TARGET_FILE"
echo "[+] Output dir  : $BASE_OUTPUT"
echo "[+] Logs dir    : $LOG_DIR"
echo "[+] Starting Wapiti scan..."

while IFS= read -r TARGET || [[ -n "$TARGET" ]]; do
    [[ -z "$TARGET" ]] && continue

    # Clean domain name for folders/files
    DOMAIN=$(echo "$TARGET" | sed 's|https\?://||; s|/|_|g')
    OUTDIR="$BASE_OUTPUT/$DOMAIN"
    LOGFILE="$LOG_DIR/$DOMAIN.log"

    mkdir -p "$OUTDIR"

    echo "[*] Scanning $TARGET"
    echo "[*] Log file: $LOGFILE"

    # Run Wapiti
    wapiti \
        -u "$TARGET" \
        --scope url \
        --max-scan-time 30 \
        -f html \
        -o "$OUTDIR" \
        -v 2 \
        </dev/null | tee "$LOGFILE"

    # ---- HTML -> PDF CONVERSION ----
    HTML_REPORT=$(ls -t "$OUTDIR"/*.html 2>/dev/null | head -n1)
    
    # Generate Custom PDF Name: DD-MM-YYYY_Wapiti_Domain.pdf
    CURRENT_DATE=$(date +"%d-%m-%Y")
    PDF_NAME="${CURRENT_DATE}_Wapiti_${DOMAIN}.pdf"
    PDF_REPORT="$OUTDIR/$PDF_NAME"

    if [[ -f "$HTML_REPORT" ]]; then
        echo "[+] Converting HTML to PDF..."
        
        wkhtmltopdf \
            --enable-local-file-access \
            --load-error-handling ignore \
            --quiet \
            "$HTML_REPORT" \
            "$PDF_REPORT"

        if [[ -f "$PDF_REPORT" ]]; then
            echo "[+] PDF report created: $PDF_REPORT"
        else
            echo "[!] PDF conversion failed for $TARGET"
        fi
    else
        echo "[!] HTML report not found in $OUTDIR"
    fi

    echo "[+] Finished $TARGET"
    echo "--------------------------------------"

done < "$TARGET_FILE"

echo "[+] All scans completed"
echo "[+] Reports saved in $BASE_OUTPUT"
