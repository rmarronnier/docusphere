import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  
  updateComparison(event) {
    // Validate that version1 and version2 are different
    const form = event.target.closest('form')
    const version1 = form.querySelector('select[name="version1"]').value
    const version2 = form.querySelector('select[name="version2"]').value
    
    if (version1 === version2) {
      this.showError("Veuillez sélectionner deux versions différentes")
      return
    }
    
    // Check that version1 is older than version2
    const version1Index = this.getVersionIndex(version1)
    const version2Index = this.getVersionIndex(version2)
    
    if (version1Index < version2Index) {
      this.showError("La version antérieure doit être plus ancienne que la version récente")
      return
    }
    
    this.clearError()
  }

  submit(event) {
    event.preventDefault()
    const form = event.target
    
    // Perform validation
    const version1 = form.querySelector('select[name="version1"]').value
    const version2 = form.querySelector('select[name="version2"]').value
    
    if (version1 === version2) {
      this.showError("Veuillez sélectionner deux versions différentes")
      return
    }
    
    // Submit form with Turbo
    form.requestSubmit()
  }

  getVersionIndex(versionId) {
    const select = document.querySelector('select[name="version1"]')
    const options = Array.from(select.options)
    return options.findIndex(option => option.value === versionId)
  }

  showError(message) {
    // Remove existing error
    this.clearError()
    
    // Create error element
    const error = document.createElement('div')
    error.className = 'mt-2 text-sm text-red-600'
    error.textContent = message
    error.dataset.versionSelectorTarget = 'error'
    
    // Insert after form
    const form = this.element.querySelector('form')
    form.parentNode.insertBefore(error, form.nextSibling)
  }

  clearError() {
    const error = this.element.querySelector('[data-version-selector-target="error"]')
    if (error) {
      error.remove()
    }
  }
}