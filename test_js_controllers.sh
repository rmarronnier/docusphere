#!/bin/bash

# Script pour tester tous les contrôleurs JavaScript un par un

echo "🧪 Test des contrôleurs JavaScript"
echo "=================================="

# Liste des fichiers de test
tests=(
    "activity_timeline_controller_spec.js"
    "alert_controller_spec.js"
    "bulk_actions_controller_spec.js"
    "chart_controller_spec.js"
    "dashboard_controller_spec.js"
    "dashboard_sortable_controller_spec.js"
    "data_grid_controller_spec.js"
    "document_grid_controller_spec.js"
    "document_preview_controller_spec.js"
    "document_sidebar_controller_spec.js"
    "document_upload_controller_spec.js"
    "document_viewer_controller_spec.js"
    "dropdown_controller_spec.js"
    "ged_controller_spec.js"
    "image_viewer_controller_spec.js"
    "image_zoom_controller_spec.js"
    "immo_promo_navbar_controller_spec.js"
    "lazy_load_controller_spec.js"
    "mobile_menu_controller_spec.js"
    "notification_bell_controller_spec.js"
    "notification_controller_spec.js"
    "pdf_viewer_controller_spec.js"
    "preferences_controller_spec.js"
    "ripple_controller_spec.js"
    "search_autocomplete_controller_spec.js"
    "widget_loader_controller_spec.js"
    "widget_resize_controller_spec.js"
    "actions_panel_controller_spec.js"
)

passed=0
failed=0
declare -a failed_tests

for test in "${tests[@]}"; do
    echo ""
    echo "📁 Testing: $test"
    echo "----------------------------------------"
    
    # Lancer le test avec timeout et capture des erreurs
    if timeout 60 docker-compose run --rm web bun test "spec/javascript/controllers/$test" --silent 2>&1 | grep -q "0 pass\|fail\|error"; then
        echo "❌ FAILED: $test"
        failed_tests+=("$test")
        ((failed++))
    else
        echo "✅ PASSED: $test"
        ((passed++))
    fi
done

echo ""
echo "📊 RÉSUMÉ"
echo "============"
echo "✅ Passés: $passed"
echo "❌ Échoués: $failed"
echo "📊 Total: $((passed + failed))"

if [ ${#failed_tests[@]} -gt 0 ]; then
    echo ""
    echo "❌ Tests échoués:"
    for test in "${failed_tests[@]}"; do
        echo "  - $test"
    done
fi