#!/bin/bash

# Set domain from command-line argument
if [ -z "$1" ]; then
    echo -e "\e[31m[ERROR] Usage: ./recon_tool.sh <target.com>\e[0m"
    exit 1
fi

DOMAIN=$1
OUTPUT_DIR="$HOME/recon_tool/reports"
WORDLIST="$HOME/recon_tool/wordlists/common.txt"

# Create output directory if not exists
mkdir -p "$OUTPUT_DIR"

# 🔥 Subdomain Enumeration (using subfinder)
echo -e "\e[33m[+] Enumerating subdomains for: $DOMAIN\e[0m"
subfinder -d "$DOMAIN" | tee "$OUTPUT_DIR/${DOMAIN}_subdomains.txt"

# 🔥 Filter Live Subdomains (using httpx)
echo -e "\e[32m[+] Filtering live subdomains...\e[0m"
httpx -l "$OUTPUT_DIR/${DOMAIN}_subdomains.txt" -o "$OUTPUT_DIR/${DOMAIN}_live_subdomains.txt"

# 🔥 Directory Fuzzing (using ffuf)
echo -e "\e[35m[+] Fuzzing directories on: $DOMAIN\e[0m"
ffuf -u "https://$DOMAIN/FUZZ" -w "$WORDLIST" -mc 200 -o "$OUTPUT_DIR/${DOMAIN}_fuzz_results.txt"

# 🔥 Find Exposed Endpoints (using Wayback Machine & GAU)
echo -e "\e[34m[+] Finding exposed endpoints...\e[0m"
waybackurls "$DOMAIN" | tee "$OUTPUT_DIR/${DOMAIN}_wayback.txt"
gau "$DOMAIN" | tee "$OUTPUT_DIR/${DOMAIN}_gau.txt"

# 🔥 Suggest Exploits
echo -e "\e[33m[+] Suggesting exploits...\e[0m"
grep -E "admin|dashboard|graphql|api|key|token" "$OUTPUT_DIR/${DOMAIN}_wayback.txt" "$OUTPUT_DIR/${DOMAIN}_gau.txt" | tee "$OUTPUT_DIR/${DOMAIN}_exploits.txt"

# 🔥 Generate Markdown Report
echo -e "\e[36m[+] Generating report...\e[0m"
cat <<EOF > "$OUTPUT_DIR/${DOMAIN}_report.md"
# 🛡️ Bug Bounty Report - $DOMAIN

## 📌 Subdomains Found:
$(cat "$OUTPUT_DIR/${DOMAIN}_subdomains.txt")

## 🟢 Live Subdomains:
$(cat "$OUTPUT_DIR/${DOMAIN}_live_subdomains.txt")

## 📂 Hidden Directories:
$(cat "$OUTPUT_DIR/${DOMAIN}_fuzz_results.txt")

## 🔥 Exposed Endpoints:
$(cat "$OUTPUT_DIR/${DOMAIN}_wayback.txt")
$(cat "$OUTPUT_DIR/${DOMAIN}_gau.txt")

## ⚠️ Suggested Exploits:
$(cat "$OUTPUT_DIR/${DOMAIN}_exploits.txt")
EOF

# 🔥 Convert Markdown Report to HTML & PDF
cat "$OUTPUT_DIR/${DOMAIN}_report.md" | aha --black > "$OUTPUT_DIR/${DOMAIN}_report.html"
wkhtmltopdf "$OUTPUT_DIR/${DOMAIN}_report.html" "$OUTPUT_DIR/${DOMAIN}_report.pdf"

echo -e "\e[32m[+] Report saved as Markdown, HTML & PDF.\e[0m"
