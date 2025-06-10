#!/usr/bin/env python3

import os
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Configuration
LOOKBOOK_BASE_URL = "http://localhost:3000"
SCREENSHOT_DIR = "tmp/screenshots/lookbook_manual"

# Créer le répertoire si nécessaire
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

# URLs à capturer
urls = [
    ("/rails/lookbook", "00_lookbook_home"),
    ("/rails/lookbook/preview/ui/data_grid_component_preview/default", "01_data_grid_default"),
    ("/rails/lookbook/preview/ui/data_grid_component_preview/with_inline_actions", "02_data_grid_inline_actions"),
    ("/rails/lookbook/preview/ui/data_grid_component_preview/with_dropdown_actions", "03_data_grid_dropdown_actions"),
    ("/rails/lookbook/preview/ui/data_grid_component_preview/with_formatting", "04_data_grid_formatting"),
    ("/rails/lookbook/preview/ui/data_grid_component_preview/empty_default", "05_data_grid_empty"),
    ("/rails/lookbook/preview/ui/button_component_preview/variants", "06_button_variants"),
    ("/rails/lookbook/preview/ui/button_component_preview/sizes", "07_button_sizes"),
    ("/rails/lookbook/preview/ui/card_component_preview/default", "08_card_default"),
    ("/rails/lookbook/preview/ui/alert_component_preview/types", "09_alert_types"),
    ("/rails/lookbook/preview/ui/modal_component_preview/default", "10_modal_default"),
    ("/rails/lookbook/preview/ui/empty_state_component_preview/icon_variations", "11_empty_states")
]

# Configuration Chrome
chrome_options = Options()
chrome_options.add_argument("--window-size=1400,1024")
chrome_options.add_argument("--force-device-scale-factor=2")  # Pour des screenshots haute résolution

# Connexion au Selenium distant
print("🚀 Connexion à Selenium...")
driver = webdriver.Remote(
    command_executor='http://localhost:4444/wd/hub',
    options=chrome_options
)

try:
    print("📸 Capture des screenshots Lookbook...\n")
    
    for path, name in urls:
        url = LOOKBOOK_BASE_URL + path
        screenshot_path = os.path.join(SCREENSHOT_DIR, f"{name}.png")
        
        try:
            print(f"  Capturing {name}...")
            driver.get(url)
            
            # Attendre que la page soit chargée
            time.sleep(3)
            
            # Pour les previews, attendre l'iframe si présent
            if "/preview/" in path:
                try:
                    # Attendre l'iframe et basculer dedans
                    iframe = WebDriverWait(driver, 5).until(
                        EC.presence_of_element_located((By.TAG_NAME, "iframe"))
                    )
                    driver.switch_to.frame(iframe)
                    time.sleep(1)
                except:
                    pass  # Pas d'iframe, on continue
            
            # Capturer le screenshot
            driver.save_screenshot(screenshot_path)
            print(f"  ✅ Saved: {name}.png")
            
            # Revenir au contexte principal si on était dans un iframe
            driver.switch_to.default_content()
            
        except Exception as e:
            print(f"  ❌ Error capturing {name}: {str(e)}")
    
    print(f"\n✨ Screenshots saved to: {os.path.abspath(SCREENSHOT_DIR)}")
    print(f"Run 'open {SCREENSHOT_DIR}' to view them")
    
finally:
    driver.quit()
    print("\n✅ Done!")