#!/bin/bash

# Check if a domain name is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

DOMAIN=$1

# Initialize variables to store results
SPF_RECORD=""
DMARC_RECORD=""
MX_RECORDS=""
DKIM_RECORDS=""
DKIM_FOUND=false

# Function to check TXT records
check_txt_record() {
  local record_type=$1
  local record_name=$2
  local result

  result=$(dig +short $record_name TXT)

  if [ -z "$result" ]; then
    echo "$record_type record for $record_name: Not found" >&2
  else
    echo "$record_type record for $record_name: Found"
    echo "$result"
  fi
}

# Function to check MX records
check_mx_record() {
  local record_name=$1
  local result

  result=$(dig +short $record_name MX)

  if [ -z "$result" ]; then
    echo "MX records for $record_name: Not found" >&2
  else
    echo "MX records for $record_name: Found"
  fi

  echo "$result"
}

echo "Checking DNS records for domain: $DOMAIN"
echo

# Check SPF record
SPF_RECORD=$(check_txt_record "SPF" "$DOMAIN")

# Check DMARC record
DMARC_RECORD=$(check_txt_record "DMARC" "_dmarc.$DOMAIN")

# Check MX records
MX_RECORDS=$(check_mx_record "$DOMAIN")

# Check DKIM records (common selector names: default, mail, etc.)
for selector in default mail; do
  DKIM_RECORD=$(check_txt_record "DKIM" "$selector._domainkey.$DOMAIN")
  if [ -n "$DKIM_RECORD" ]; then
    DKIM_FOUND=true
    DKIM_RECORDS+="$selector._domainkey.$DOMAIN: DKIM record found\n$DKIM_RECORD\n"
  else
    DKIM_RECORDS+="$selector._domainkey.$DOMAIN: DKIM record not found\n"
  fi
done

# Summarize findings
echo
echo "==========================================="
echo "Summary of DNS records for domain: $DOMAIN"
echo "==========================================="

# SPF Record
echo
echo "-------------------------------------------"
echo "SPF Record"
echo "-------------------------------------------"
if [ -z "$SPF_RECORD" ]; then
  echo "SPF record: Missing"
else
  echo "SPF record: Found"
  echo "$SPF_RECORD"
fi

# DMARC Record
echo
echo "-------------------------------------------"
echo "DMARC Record"
echo "-------------------------------------------"
if [ -z "$DMARC_RECORD" ]; then
  echo "DMARC record: Missing"
else
  echo "DMARC record: Found"
  echo "$DMARC_RECORD"
fi

# MX Records
echo
echo "-------------------------------------------"
echo "MX Records"
echo "-------------------------------------------"
if [ -z "$MX_RECORDS" ]; then
  echo "MX records: Missing"
else
  echo "MX records: Found"
  echo "$MX_RECORDS"
fi

# DKIM Records
echo
echo "-------------------------------------------"
echo "DKIM Records"
echo "-------------------------------------------"
if ! $DKIM_FOUND; then
  echo "DKIM records: Missing"
else
  echo "DKIM records: Found"
  echo -e "$DKIM_RECORDS"
fi

echo "-------------------------------------------"
echo "DNS record check completed for domain: $DOMAIN"
echo "==========================================="
