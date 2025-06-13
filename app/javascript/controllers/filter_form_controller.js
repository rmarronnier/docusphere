import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="filter-form"
export default class extends Controller {
  static values = { 
    autoSubmit: Boolean,
    debounceDelay: { type: Number, default: 300 }
  }
  
  static targets = ["form", "loading"]

  connect() {
    this.debounceTimeout = null
    this.setupFormInputs()
  }

  disconnect() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }
  }

  setupFormInputs() {
    if (!this.autoSubmitValue) return

    const inputs = this.element.querySelectorAll('select, input[type="text"], input[type="search"], input[type="date"]')
    
    inputs.forEach(input => {
      if (input.type === 'text' || input.type === 'search') {
        // Debounce text inputs
        input.addEventListener('input', this.handleTextInput.bind(this))
      } else {
        // Immediate submit for selects and date inputs
        input.addEventListener('change', this.handleSelectChange.bind(this))
      }
    })
  }

  handleTextInput(event) {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout)
    }

    this.debounceTimeout = setTimeout(() => {
      this.submitForm(event)
    }, this.debounceDelayValue)
  }

  handleSelectChange(event) {
    this.submitForm(event)
  }

  submitForm(event) {
    if (!this.autoSubmitValue) return

    // Show loading state if target exists
    if (this.hasLoadingTarget) {
      this.showLoading()
    }

    // Add loading class to the form
    this.element.classList.add('loading')
    
    // Submit the form
    const form = this.element.querySelector('form')
    if (form) {
      form.submit()
    }
  }

  showLoading() {
    this.loadingTarget.classList.remove('hidden')
    this.loadingTarget.innerHTML = `
      <div class="flex items-center text-sm text-gray-500">
        <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-gray-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        Filtrage en cours...
      </div>
    `
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
    this.element.classList.remove('loading')
  }

  // Action to manually reset the form
  reset() {
    const form = this.element.querySelector('form')
    if (form) {
      // Clear all form inputs
      const inputs = form.querySelectorAll('select, input[type="text"], input[type="search"], input[type="date"]')
      inputs.forEach(input => {
        if (input.type === 'text' || input.type === 'search' || input.type === 'date') {
          input.value = ''
        } else if (input.tagName.toLowerCase() === 'select') {
          input.selectedIndex = 0
        }
      })
      
      // Submit the cleared form
      this.submitForm()
    }
  }
}