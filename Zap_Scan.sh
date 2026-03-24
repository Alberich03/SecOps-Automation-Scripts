#!/bin/bash

# ======================================================
# OWASP ZAP Automated Full Scan Script (Local)
# Author: AubreyN SOC
# ======================================================
# 
# --- Ensure ZAP Is Running ---
# zaproxy -daemon -port 8090 -config api.key=YOUR_API_KEY &
#

set -e

INPUT_FILE="$1"
OUTPUT_DIR="$2"

# --- CONFIGURATION ---
ZAP_API_KEY="ho1pejb4aj4moqrv2v4es6c86p"
ZAP_PROXY_HOST="127.0.0.1"
ZAP_PROXY_PORT="8090"
ZAP_PROXY="http://$ZAP_PROXY_HOST:$ZAP_PROXY_PORT"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Usage: $0 <targets.txt> <output_directory>"
  exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "[!] Targets file not found: $INPUT_FILE"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# -------- Pre-Scan Checks --------

# 1. Check if ZAP is actually running
echo "[~] Checking if ZAP is active on $ZAP_PROXY..."
if ! nc -z "$ZAP_PROXY_HOST" "$ZAP_PROXY_PORT"; then
  echo "[!] Error: ZAP is not running on port $ZAP_PROXY_PORT."
  echo "    Please start ZAP GUI or run: zaproxy -daemon -port $ZAP_PROXY_PORT -config api.key=$ZAP_API_KEY &"
  exit 1
fi
echo "[✓] ZAP is online and responding."

# 2. Check for wkhtmltopdf (required for PDF conversion)
command -v wkhtmltopdf >/dev/null 2>&1 || {
  echo "[!] wkhtmltopdf not found. Install with: sudo apt install wkhtmltopdf";
  exit 1;
}

# -------- Main loop --------
while IFS= read -r TARGET_URL || [ -n "$TARGET_URL" ]; do

  # Skip empty lines and comments
  [[ -z "$TARGET_URL" || "$TARGET_URL" =~ ^# ]] && continue

  # File naming logic (Day-Month-Year)
  SAFE_NAME=$(echo "$TARGET_URL" | sed 's|https\?://||; s|/|_|g')
  CURRENT_DATE=$(date +"%d-%m-%Y")
  HTML_REPORT="$OUTPUT_DIR/${CURRENT_DATE}_ZAP_${SAFE_NAME}.html"
  PDF_REPORT="$OUTPUT_DIR/${CURRENT_DATE}_ZAP_${SAFE_NAME}.pdf"

  echo "---------------------------------------------"
  echo "[+] Starting ZAP scan on: $TARGET_URL"

  # Using Python to interface with the ZAP API
  python3 - <<EOF
import time
import sys
from zapv2 import ZAPv2

# Initialize ZAP API Client
zap = ZAPv2(proxies={'http': '$ZAP_PROXY', 'https': '$ZAP_PROXY'}, apikey='$ZAP_API_KEY')

# Step 1: Spidering
print(f'  [~] Spidering target...')
scanid = zap.spider.scan('$TARGET_URL')
while int(zap.spider.status(scanid)) < 100:
    print(f'      Spider progress: {zap.spider.status(scanid)}%', end='\r')
    time.sleep(2)
print('\n  [✓] Spider complete.')

# Step 2: Active Scan
print(f'  [~] Active Scanning...')
ascanid = zap.ascan.scan('$TARGET_URL')
while int(zap.ascan.status(ascanid)) < 100:
    print(f'      Scan progress: {zap.ascan.status(ascanid)}%', end='\r')
    time.sleep(5)
print('\n  [✓] Active scan complete.')

# Step 3: Save HTML Report
print(f'  [~] Generating HTML report...')
with open('$HTML_REPORT', 'w') as f:
    f.write(zap.core.htmlreport())
EOF

  # Step 4: Convert HTML to PDF
  echo "[+] Converting report to PDF..."
  wkhtmltopdf --quiet "$HTML_REPORT" "$PDF_REPORT"

  echo "[✓] Scan Finished for: $TARGET_URL"
  echo "    Final Report: $PDF_REPORT"

done < "$INPUT_FILE"

echo "---------------------------------------------"
echo "[✓] All targets processed successfully."
