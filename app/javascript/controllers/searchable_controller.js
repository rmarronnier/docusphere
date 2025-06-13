import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="searchable"
export default class extends Controller {
  static targets = ["input", "dropdown", "option", "select"]

  connect() {
    this.selectedValues = new Set()
    this.isMultiple = this.selectTarget.multiple
    this.initializeSelection()
  }

  initializeSelection() {
    // Set initial values from the hidden select
    const selectedOptions = Array.from(this.selectTarget.selectedOptions)
    selectedOptions.forEach(option => {
      this.selectedValues.add(option.value)
    })
    this.updateInputDisplay()
  }

  filter(event) {
    const searchTerm = event.target.value.toLowerCase()
    
    this.optionTargets.forEach(option => {
      const text = option.dataset.text || option.textContent.toLowerCase()
      if (text.includes(searchTerm)) {
        option.classList.remove('hidden')
      } else {
        option.classList.add('hidden')
      }
    })
  }

  open() {
    this.dropdownTarget.classList.remove('hidden')
    this.updateOptionStates()
  }

  close() {
    // Delay closing to allow option selection
    setTimeout(() => {
      this.dropdownTarget.classList.add('hidden')
    }, 200)
  }

  select(event) {
    const option = event.currentTarget
    const value = option.dataset.value
    const text = option.textContent.trim()

    if (this.isMultiple) {
      this.toggleMultipleSelection(value, text)
    } else {
      this.setSingleSelection(value, text)
      this.close()
    }

    this.updateHiddenSelect()
    this.updateInputDisplay()
    this.updateOptionStates()
  }

  toggleMultipleSelection(value, text) {
    if (this.selectedValues.has(value)) {
      this.selectedValues.delete(value)
    } else {
      this.selectedValues.add(value)
    }
  }

  setSingleSelection(value, text) {
    this.selectedValues.clear()
    this.selectedValues.add(value)
  }

  updateHiddenSelect() {
    // Clear all selections
    Array.from(this.selectTarget.options).forEach(option => {
      option.selected = false
    })

    // Set new selections
    this.selectedValues.forEach(value => {
      const option = this.selectTarget.querySelector(`option[value="${value}"]`)
      if (option) {
        option.selected = true
      }
    })

    // Trigger change event
    this.selectTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }

  updateInputDisplay() {
    const selectedTexts = []
    
    this.selectedValues.forEach(value => {
      const option = this.optionTargets.find(opt => opt.dataset.value === value)
      if (option) {
        selectedTexts.push(option.textContent.trim())
      }
    })

    if (selectedTexts.length > 0) {
      if (this.isMultiple) {
        this.inputTarget.value = `${selectedTexts.length} option(s) selected`
      } else {
        this.inputTarget.value = selectedTexts[0]
      }
    } else {
      this.inputTarget.value = ''
    }
  }

  updateOptionStates() {
    this.optionTargets.forEach(option => {
      const value = option.dataset.value
      const isSelected = this.selectedValues.has(value)
      
      if (isSelected) {
        option.classList.add('bg-indigo-600', 'text-white')
        option.classList.remove('hover:bg-indigo-600', 'hover:text-white')
      } else {
        option.classList.remove('bg-indigo-600', 'text-white')
        option.classList.add('hover:bg-indigo-600', 'hover:text-white')
      }
    })
  }
}