import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "selectAll"]
  static values = { 
    selected: Array,
    sortKey: String,
    sortDirection: String 
  }

  connect() {
    this.selectedValue = this.selectedValue || []
  }

  toggleAll(event) {
    const checked = event.target.checked
    const checkboxes = this.element.querySelectorAll('tbody input[type="checkbox"]')
    
    checkboxes.forEach(checkbox => {
      checkbox.checked = checked
      const id = checkbox.value
      
      if (checked && !this.selectedValue.includes(id)) {
        this.selectedValue = [...this.selectedValue, id]
      } else if (!checked) {
        this.selectedValue = this.selectedValue.filter(selectedId => selectedId !== id)
      }
    })
    
    this.dispatch("selection-changed", { 
      detail: { selected: this.selectedValue } 
    })
  }

  toggleRow(event) {
    const checkbox = event.target
    const id = checkbox.value
    
    if (checkbox.checked) {
      this.selectedValue = [...this.selectedValue, id]
    } else {
      this.selectedValue = this.selectedValue.filter(selectedId => selectedId !== id)
    }
    
    this.updateSelectAll()
    this.dispatch("selection-changed", { 
      detail: { selected: this.selectedValue } 
    })
  }

  updateSelectAll() {
    const selectAllCheckbox = this.element.querySelector('thead input[type="checkbox"]')
    if (!selectAllCheckbox) return
    
    const checkboxes = this.element.querySelectorAll('tbody input[type="checkbox"]')
    const allChecked = Array.from(checkboxes).every(cb => cb.checked)
    const someChecked = Array.from(checkboxes).some(cb => cb.checked)
    
    selectAllCheckbox.checked = allChecked
    selectAllCheckbox.indeterminate = someChecked && !allChecked
  }

  sort(event) {
    const header = event.currentTarget
    const key = header.dataset.sortKey
    
    if (!key) return
    
    // Toggle sort direction
    if (this.sortKeyValue === key) {
      this.sortDirectionValue = this.sortDirectionValue === 'asc' ? 'desc' : 'asc'
    } else {
      this.sortKeyValue = key
      this.sortDirectionValue = 'asc'
    }
    
    // Update visual indicators
    this.updateSortIndicators(header)
    
    // Dispatch sort event
    this.dispatch("sort", { 
      detail: { 
        key: this.sortKeyValue, 
        direction: this.sortDirectionValue 
      } 
    })
  }

  updateSortIndicators(activeHeader) {
    // Remove all sort indicators
    this.element.querySelectorAll('th[data-sortable]').forEach(header => {
      const icon = header.querySelector('svg')
      if (icon) {
        icon.classList.remove('text-gray-900', 'transform', 'rotate-180')
        icon.classList.add('text-gray-400')
      }
    })
    
    // Add active sort indicator
    const icon = activeHeader.querySelector('svg')
    if (icon) {
      icon.classList.remove('text-gray-400')
      icon.classList.add('text-gray-900')
      
      if (this.sortDirectionValue === 'desc') {
        icon.classList.add('transform', 'rotate-180')
      }
    }
  }

  rowClick(event) {
    // Ignore clicks on interactive elements
    if (event.target.matches('input, button, a, [role="button"]')) return
    
    const row = event.currentTarget
    const id = row.dataset.rowId
    
    this.dispatch("row-click", { detail: { id, row } })
  }

  // Export selected data
  exportSelected() {
    this.dispatch("export", { 
      detail: { selected: this.selectedValue } 
    })
  }

  // Clear selection
  clearSelection() {
    this.selectedValue = []
    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]')
    checkboxes.forEach(checkbox => checkbox.checked = false)
    
    this.dispatch("selection-changed", { 
      detail: { selected: this.selectedValue } 
    })
  }
}