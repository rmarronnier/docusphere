#!/bin/bash

# Script pour capturer les screenshots Lookbook directement depuis l'hôte

echo "📸 Capturing Lookbook screenshots directly from host..."
echo ""

# Vérifier que le serveur est accessible
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200\|302"; then
    echo "❌ Error: Server not accessible at http://localhost:3000"
    echo "Please ensure Docker containers are running: docker-compose up"
    exit 1
fi

# Créer le dossier de screenshots
SCREENSHOT_DIR="tmp/screenshots/lookbook_direct"
mkdir -p "$SCREENSHOT_DIR"

echo "✅ Server is accessible"
echo ""
echo "📋 Lookbook URLs to visit manually:"
echo ""
echo "1. Home: http://localhost:3000/rails/lookbook"
echo "2. DataGrid Default: http://localhost:3000/rails/lookbook/preview/ui/data_grid_component_preview/default"
echo "3. DataGrid Actions: http://localhost:3000/rails/lookbook/preview/ui/data_grid_component_preview/with_inline_actions"
echo "4. DataGrid Formatting: http://localhost:3000/rails/lookbook/preview/ui/data_grid_component_preview/with_formatting"
echo "5. Button Variants: http://localhost:3000/rails/lookbook/preview/ui/button_component_preview/variants"
echo "6. Card Default: http://localhost:3000/rails/lookbook/preview/ui/card_component_preview/default"
echo "7. Alert Types: http://localhost:3000/rails/lookbook/preview/ui/alert_component_preview/types"
echo ""
echo "💡 To capture screenshots on macOS:"
echo "   - Full page: Cmd+Shift+5 then select 'Capture Selected Window'"
echo "   - Specific area: Cmd+Shift+4"
echo ""
echo "📁 Save screenshots to: $SCREENSHOT_DIR"
echo ""

# Ouvrir automatiquement le navigateur si possible
if command -v open &> /dev/null; then
    echo "🌐 Opening Lookbook in browser..."
    open "http://localhost:3000/rails/lookbook"
fi