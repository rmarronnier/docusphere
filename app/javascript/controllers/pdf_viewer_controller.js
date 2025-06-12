import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["frame", "pageInput", "totalPages", "zoomSelect"]
  
  connect() {
    this.currentPage = 1
    this.totalPages = 1
    this.currentZoom = 'auto'
    
    // Wait for PDF to load
    if (this.hasFrameTarget) {
      this.frameTarget.addEventListener('load', () => {
        this.initializePdfViewer()
      })
    }
  }

  initializePdfViewer() {
    // This is a basic implementation
    // For full PDF.js integration, we would load the PDF.js library
    // and have more control over the PDF rendering
    console.log('PDF viewer initialized')
  }

  previousPage() {
    if (this.currentPage > 1) {
      this.currentPage--
      this.goToPage()
    }
  }

  nextPage() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++
      this.goToPage()
    }
  }

  goToPage() {
    const page = parseInt(this.pageInputTarget.value)
    if (page >= 1 && page <= this.totalPages) {
      this.currentPage = page
      // Update PDF viewer to show the requested page
      // With PDF.js integration, we would render the specific page
      this.updatePageDisplay()
    }
  }

  updatePageDisplay() {
    this.pageInputTarget.value = this.currentPage
    // Update navigation button states
    const prevButton = this.element.querySelector('[data-action*="previousPage"]')
    const nextButton = this.element.querySelector('[data-action*="nextPage"]')
    
    if (prevButton) {
      prevButton.disabled = this.currentPage <= 1
      prevButton.classList.toggle('opacity-50', this.currentPage <= 1)
    }
    
    if (nextButton) {
      nextButton.disabled = this.currentPage >= this.totalPages
      nextButton.classList.toggle('opacity-50', this.currentPage >= this.totalPages)
    }
  }

  zoomIn() {
    const currentZoom = this.getCurrentZoomLevel()
    const newZoom = Math.min(currentZoom * 1.25, 5) // Max 500%
    this.setZoomLevel(newZoom)
  }

  zoomOut() {
    const currentZoom = this.getCurrentZoomLevel()
    const newZoom = Math.max(currentZoom * 0.8, 0.25) // Min 25%
    this.setZoomLevel(newZoom)
  }

  setZoom(event) {
    const zoomValue = event.target.value
    this.currentZoom = zoomValue
    
    if (zoomValue === 'auto' || zoomValue === 'fit-width' || zoomValue === 'fit-page') {
      this.applySpecialZoom(zoomValue)
    } else {
      this.setZoomLevel(parseFloat(zoomValue))
    }
  }

  getCurrentZoomLevel() {
    if (this.currentZoom === 'auto' || isNaN(parseFloat(this.currentZoom))) {
      return 1
    }
    return parseFloat(this.currentZoom)
  }

  setZoomLevel(level) {
    this.currentZoom = level.toString()
    
    // Update zoom select if the level matches a preset
    const presetOption = Array.from(this.zoomSelectTarget.options).find(
      option => parseFloat(option.value) === level
    )
    
    if (presetOption) {
      this.zoomSelectTarget.value = presetOption.value
    } else {
      // Update to custom zoom level
      this.zoomSelectTarget.value = 'custom'
    }
    
    // Apply zoom to PDF frame
    this.applyZoom(level)
  }

  applyZoom(level) {
    if (this.hasFrameTarget) {
      this.frameTarget.style.transform = `scale(${level})`
      this.frameTarget.style.transformOrigin = 'top left'
      
      // Adjust container size to accommodate zoomed content
      const container = this.frameTarget.parentElement
      if (container) {
        container.style.width = `${100 * level}%`
        container.style.height = `${100 * level}%`
      }
    }
  }

  applySpecialZoom(type) {
    // These would be implemented with proper PDF.js integration
    switch(type) {
      case 'fit-width':
        console.log('Fitting to width')
        break
      case 'fit-page':
        console.log('Fitting to page')
        break
      case 'auto':
      default:
        console.log('Auto zoom')
        this.applyZoom(1)
        break
    }
  }

  fullscreen() {
    const viewer = this.element.closest('.document-viewer-component')
    if (viewer) {
      if (viewer.requestFullscreen) {
        viewer.requestFullscreen()
      } else if (viewer.webkitRequestFullscreen) {
        viewer.webkitRequestFullscreen()
      }
    }
  }

  print() {
    if (this.hasFrameTarget) {
      // Print the PDF content
      this.frameTarget.contentWindow.print()
    }
  }
}