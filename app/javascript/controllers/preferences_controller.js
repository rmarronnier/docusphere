import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="preferences"
export default class extends Controller {
  static targets = ["modal", "previewContent"]

  connect() {
    console.log("Preferences controller connected")
    this.updateCategoryToggles()
  }

  // Enable all notifications
  enableAll(event) {
    event.preventDefault()
    this.setAllPreferences(true, 'both', 'immediate')
    this.showToast('Toutes les notifications ont été activées', 'success')
  }

  // Enable only essential/urgent notifications
  essentialOnly(event) {
    event.preventDefault()
    this.setUrgentPreferences(true, 'both', 'immediate')
    this.setNonUrgentPreferences(false, 'disabled', 'disabled_frequency')
    this.showToast('Seules les notifications essentielles sont activées', 'info')
  }

  // Disable all notifications
  disableAll(event) {
    event.preventDefault()
    this.setAllPreferences(false, 'disabled', 'disabled_frequency')
    this.showToast('Toutes les notifications ont été désactivées', 'warning')
  }

  // Toggle entire category
  toggleCategory(event) {
    const button = event.currentTarget
    const category = button.dataset.category
    const isEnabled = button.classList.contains('category-enabled')
    
    // Toggle the category
    this.setCategoryPreferences(category, !isEnabled, !isEnabled ? 'in_app' : 'disabled')
    
    // Update toggle appearance
    this.updateCategoryToggle(button, !isEnabled)
    
    const action = !isEnabled ? 'activées' : 'désactivées'
    this.showToast(`Notifications ${category.humanize} ${action}`, 'info')
  }

  // Update individual preference
  updatePreference(event) {
    const element = event.currentTarget
    const category = element.dataset.category
    
    // Update category toggle state
    this.updateCategoryToggleForCategory(category)
    
    // Auto-save (optional)
    if (this.shouldAutoSave()) {
      this.autoSave()
    }
  }

  // Show notification preview
  async showPreview(event) {
    event.preventDefault()
    const notificationType = event.currentTarget.dataset.notificationType
    
    try {
      const response = await fetch(`/notification_preferences/preview?notification_type=${notificationType}`, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.showPreviewModal(html)
      } else {
        throw new Error('Failed to load preview')
      }
    } catch (error) {
      console.error('Error loading preview:', error)
      this.showToast('Erreur lors du chargement de l\'aperçu', 'error')
    }
  }

  // Close preview modal
  closePreview(event) {
    event.preventDefault()
    this.hidePreviewModal()
  }

  // Set all preferences
  setAllPreferences(enabled, deliveryMethod, frequency) {
    const enabledCheckboxes = this.element.querySelectorAll('.preference-enabled')
    const deliverySelects = this.element.querySelectorAll('select[name*="[delivery_method]"]')
    const frequencySelects = this.element.querySelectorAll('select[name*="[frequency]"]')
    
    enabledCheckboxes.forEach(checkbox => {
      checkbox.checked = enabled
    })
    
    deliverySelects.forEach(select => {
      select.value = deliveryMethod
    })
    
    frequencySelects.forEach(select => {
      select.value = frequency
    })
    
    this.updateCategoryToggles()
  }

  // Set urgent preferences only
  setUrgentPreferences(enabled, deliveryMethod, frequency) {
    const urgentElements = this.element.querySelectorAll('[data-notification-type]')
    
    urgentElements.forEach(element => {
      const urgentBadge = element.querySelector('.bg-red-100')
      if (urgentBadge) {
        const checkbox = element.querySelector('.preference-enabled')
        const deliverySelect = element.querySelector('select[name*="[delivery_method]"]')
        const frequencySelect = element.querySelector('select[name*="[frequency]"]')
        
        if (checkbox) checkbox.checked = enabled
        if (deliverySelect) deliverySelect.value = deliveryMethod
        if (frequencySelect) frequencySelect.value = frequency
      }
    })
    
    this.updateCategoryToggles()
  }

  // Set non-urgent preferences
  setNonUrgentPreferences(enabled, deliveryMethod, frequency) {
    const allElements = this.element.querySelectorAll('[data-notification-type]')
    
    allElements.forEach(element => {
      const urgentBadge = element.querySelector('.bg-red-100')
      if (!urgentBadge) {
        const checkbox = element.querySelector('.preference-enabled')
        const deliverySelect = element.querySelector('select[name*="[delivery_method]"]')
        const frequencySelect = element.querySelector('select[name*="[frequency]"]')
        
        if (checkbox) checkbox.checked = enabled
        if (deliverySelect) deliverySelect.value = deliveryMethod
        if (frequencySelect) frequencySelect.value = frequency
      }
    })
    
    this.updateCategoryToggles()
  }

  // Set preferences for a specific category
  setCategoryPreferences(category, enabled, deliveryMethod) {
    const categoryElements = this.element.querySelectorAll(`[data-category="${category}"]`)
    
    categoryElements.forEach(element => {
      const checkbox = element.querySelector('.preference-enabled')
      const deliverySelect = element.querySelector('select[name*="[delivery_method]"]')
      
      if (checkbox) checkbox.checked = enabled
      if (deliverySelect) deliverySelect.value = deliveryMethod
    })
  }

  // Update all category toggles
  updateCategoryToggles() {
    const categories = [...new Set(Array.from(this.element.querySelectorAll('[data-category]')).map(el => el.dataset.category))]
    
    categories.forEach(category => {
      const toggle = this.element.querySelector(`.category-toggle[data-category="${category}"]`)
      if (toggle) {
        const isEnabled = this.isCategoryEnabled(category)
        this.updateCategoryToggle(toggle, isEnabled)
      }
    })
  }

  // Update category toggle for specific category
  updateCategoryToggleForCategory(category) {
    const toggle = this.element.querySelector(`.category-toggle[data-category="${category}"]`)
    if (toggle) {
      const isEnabled = this.isCategoryEnabled(category)
      this.updateCategoryToggle(toggle, isEnabled)
    }
  }

  // Check if category is enabled
  isCategoryEnabled(category) {
    const categoryElements = this.element.querySelectorAll(`[data-category="${category}"] .preference-enabled`)
    const enabledCount = Array.from(categoryElements).filter(checkbox => checkbox.checked).length
    return enabledCount > 0
  }

  // Update toggle appearance
  updateCategoryToggle(toggle, enabled) {
    const thumb = toggle.querySelector('.toggle-thumb')
    
    if (enabled) {
      toggle.classList.add('category-enabled', 'bg-blue-600')
      toggle.classList.remove('bg-gray-200')
      thumb.classList.add('translate-x-5')
      thumb.classList.remove('translate-x-0')
    } else {
      toggle.classList.remove('category-enabled', 'bg-blue-600')
      toggle.classList.add('bg-gray-200')
      thumb.classList.remove('translate-x-5')
      thumb.classList.add('translate-x-0')
    }
  }

  // Show preview modal
  showPreviewModal(content) {
    const modal = document.getElementById('preview-modal')
    const previewContent = document.getElementById('preview-content')
    
    if (modal && previewContent) {
      previewContent.innerHTML = content
      modal.classList.remove('hidden')
      document.body.classList.add('overflow-hidden')
    }
  }

  // Hide preview modal
  hidePreviewModal() {
    const modal = document.getElementById('preview-modal')
    
    if (modal) {
      modal.classList.add('hidden')
      document.body.classList.remove('overflow-hidden')
    }
  }

  // Check if should auto-save
  shouldAutoSave() {
    // Return false for now - implement based on requirements
    return false
  }

  // Auto-save preferences
  async autoSave() {
    try {
      const formData = new FormData(this.element.querySelector('form'))
      
      const response = await fetch('/notification_preferences/bulk_update', {
        method: 'PATCH',
        body: formData,
        headers: {
          'X-CSRF-Token': this.getCsrfToken(),
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (response.ok) {
        this.showToast('Préférences sauvegardées automatiquement', 'success')
      }
    } catch (error) {
      console.error('Auto-save failed:', error)
    }
  }

  // Get CSRF token
  getCsrfToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  // Show toast notification
  showToast(message, type = 'info') {
    const toast = document.createElement('div')
    toast.className = `preferences-toast preferences-toast--${type}`
    toast.textContent = message
    
    Object.assign(toast.style, {
      position: 'fixed',
      top: '20px',
      right: '20px',
      padding: '12px 20px',
      borderRadius: '6px',
      color: 'white',
      fontWeight: '500',
      zIndex: '1000',
      transform: 'translateX(100%)',
      transition: 'transform 0.3s ease-in-out'
    })
    
    const colors = {
      success: '#10B981',
      error: '#EF4444',
      warning: '#F59E0B',
      info: '#3B82F6'
    }
    toast.style.backgroundColor = colors[type] || colors.info
    
    document.body.appendChild(toast)
    
    setTimeout(() => {
      toast.style.transform = 'translateX(0)'
    }, 10)
    
    setTimeout(() => {
      toast.style.transform = 'translateX(100%)'
      setTimeout(() => {
        if (toast.parentNode) {
          toast.parentNode.removeChild(toast)
        }
      }, 300)
    }, 3000)
  }
}