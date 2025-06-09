import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    selected: Array,
    viewMode: String 
  }
  
  connect() {
    this.selectedValue = this.selectedValue || []
    this.viewModeValue = this.viewModeValue || 'grid'
  }

  toggleSelection(event) {
    const checkbox = event.target
    const documentId = checkbox.value
    
    if (checkbox.checked) {
      this.selectedValue = [...this.selectedValue, documentId]
    } else {
      this.selectedValue = this.selectedValue.filter(id => id !== documentId)
    }
    
    this.updateSelectionUI()
    this.dispatch("selection-changed", { 
      detail: { selected: this.selectedValue } 
    })
  }

  selectAll() {
    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]')
    this.selectedValue = Array.from(checkboxes).map(cb => {
      cb.checked = true
      return cb.value
    })
    
    this.updateSelectionUI()
    this.dispatch("selection-changed", { 
      detail: { selected: this.selectedValue } 
    })
  }

  deselectAll() {
    const checkboxes = this.element.querySelectorAll('input[type="checkbox"]')
    checkboxes.forEach(cb => cb.checked = false)
    this.selectedValue = []
    
    this.updateSelectionUI()
    this.dispatch("selection-changed", { 
      detail: { selected: this.selectedValue } 
    })
  }

  updateSelectionUI() {
    // Update any UI elements that show selection count
    const countElement = document.querySelector('[data-selection-count]')
    if (countElement) {
      countElement.textContent = this.selectedValue.length
    }
    
    // Show/hide bulk action buttons
    const bulkActions = document.querySelector('[data-bulk-actions]')
    if (bulkActions) {
      if (this.selectedValue.length > 0) {
        bulkActions.classList.remove('hidden')
      } else {
        bulkActions.classList.add('hidden')
      }
    }
  }

  changeViewMode(event) {
    const mode = event.currentTarget.dataset.viewMode
    this.viewModeValue = mode
    
    // Update active state on buttons
    document.querySelectorAll('[data-view-mode]').forEach(btn => {
      btn.classList.remove('bg-gray-100', 'text-gray-900')
      btn.classList.add('text-gray-500')
    })
    event.currentTarget.classList.remove('text-gray-500')
    event.currentTarget.classList.add('bg-gray-100', 'text-gray-900')
    
    this.dispatch("view-mode-changed", { 
      detail: { viewMode: mode } 
    })
  }

  // Drag and drop support
  dragStart(event) {
    const documentId = event.currentTarget.dataset.documentId
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('documentId', documentId)
    event.currentTarget.classList.add('opacity-50')
  }

  dragEnd(event) {
    event.currentTarget.classList.remove('opacity-50')
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }

  drop(event) {
    event.preventDefault()
    const documentId = event.dataTransfer.getData('documentId')
    const targetId = event.currentTarget.dataset.folderId
    
    this.dispatch("document-dropped", { 
      detail: { documentId, targetId } 
    })
  }

  // Quick preview
  quickPreview(event) {
    event.preventDefault()
    const documentId = event.currentTarget.dataset.documentId
    
    this.dispatch("quick-preview", { 
      detail: { documentId } 
    })
  }

  // Batch operations
  batchDownload() {
    if (this.selectedValue.length === 0) return
    
    this.dispatch("batch-download", { 
      detail: { documentIds: this.selectedValue } 
    })
  }

  batchDelete() {
    if (this.selectedValue.length === 0) return
    
    if (confirm(`Are you sure you want to delete ${this.selectedValue.length} documents?`)) {
      this.dispatch("batch-delete", { 
        detail: { documentIds: this.selectedValue } 
      })
    }
  }

  batchMove() {
    if (this.selectedValue.length === 0) return
    
    this.dispatch("batch-move", { 
      detail: { documentIds: this.selectedValue } 
    })
  }
}