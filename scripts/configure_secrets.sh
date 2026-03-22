#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Assuming the root directory is one level up from the script directory
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Path to Secrets.plist
INFO_PLIST="$ROOT_DIR/Azkar/Resources/Secrets.plist"

# Check if environment variables are set
if [[ -z "$AZKAR_SUPABASE_API_KEY" || -z "$AZKAR_SUPABASE_API_URL" ]]; then
  echo "Error: AZKAR_SUPABASE_API_KEY and AZKAR_SUPABASE_API_URL environment variables must be set."
  exit 1
fi

# If Secrets.plist doesn't exist, create it with the correct format
if [[ ! -f "$INFO_PLIST" ]]; then
  cat > "$INFO_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AZKAR_SUPABASE_API_KEY</key>
    <string>$AZKAR_SUPABASE_API_KEY</string>
    <key>AZKAR_SUPABASE_API_URL</key>
    <string>$AZKAR_SUPABASE_API_URL</string>
    <key>REVENUE_CAT_API_KEY</key>
    <string>$REVENUE_CAT_API_KEY</string>
    <key>MIXPANEL_TOKEN</key>
    <string>$MIXPANEL_TOKEN</string>
</dict>
</plist>
EOF
fi

echo "Secrets.plist has been updated successfully."
