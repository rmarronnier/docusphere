#!/bin/bash

# Script to create placeholder file icons
# These can be replaced with proper icons later

# Function to create icon with text
create_icon() {
    local filename=$1
    local text=$2
    local color=$3
    
    # Create a 100x100 PNG with text
    convert -size 100x100 xc:white \
            -fill "$color" \
            -draw "rectangle 10,10 90,90" \
            -fill white \
            -font Arial -pointsize 20 \
            -gravity center \
            -annotate +0+0 "$text" \
            "$filename"
}

# Create icons for different file types
create_icon "pdf-icon.png" "PDF" "#DC2626"
create_icon "word-icon.png" "DOC" "#2563EB"
create_icon "excel-icon.png" "XLS" "#059669"
create_icon "ppt-icon.png" "PPT" "#DC2626"
create_icon "zip-icon.png" "ZIP" "#7C3AED"
create_icon "txt-icon.png" "TXT" "#6B7280"
create_icon "generic-icon.png" "FILE" "#9CA3AF"

echo "Icons created successfully!"