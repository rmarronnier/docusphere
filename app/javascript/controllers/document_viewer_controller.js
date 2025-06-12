import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    id: Number
  }

  connect() {
    this.setupKeyboardShortcuts()
    this.trackView()
  }

  disconnect() {
    this.removeKeyboardShortcuts()
  }

  setupKeyboardShortcuts() {
    this.keyboardHandler = (event) => {
      // Esc to close fullscreen
      if (event.key === 'Escape' && this.isFullscreen()) {
        this.exitFullscreen()
      }
      
      // Ctrl/Cmd + S to save/download
      if ((event.ctrlKey || event.metaKey) && event.key === 's') {
        event.preventDefault()
        this.download()
      }
      
      // Ctrl/Cmd + P to print
      if ((event.ctrlKey || event.metaKey) && event.key === 'p') {
        event.preventDefault()
        this.print()
      }
    }
    
    document.addEventListener('keydown', this.keyboardHandler)
  }

  removeKeyboardShortcuts() {
    if (this.keyboardHandler) {
      document.removeEventListener('keydown', this.keyboardHandler)
    }
  }

  trackView() {
    // Track document view for analytics
    if (this.idValue) {
      fetch(`/ged/documents/${this.idValue}/track_view`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content,
          'Content-Type': 'application/json'
        }
      })
    }
  }

  download() {
    const downloadButton = this.element.querySelector('[data-action*="download"]')
    if (downloadButton) {
      downloadButton.click()
    }
  }

  print() {
    window.print()
  }

  enterFullscreen() {
    if (this.element.requestFullscreen) {
      this.element.requestFullscreen()
    } else if (this.element.webkitRequestFullscreen) {
      this.element.webkitRequestFullscreen()
    } else if (this.element.msRequestFullscreen) {
      this.element.msRequestFullscreen()
    }
  }

  exitFullscreen() {
    if (document.exitFullscreen) {
      document.exitFullscreen()
    } else if (document.webkitExitFullscreen) {
      document.webkitExitFullscreen()
    } else if (document.msExitFullscreen) {
      document.msExitFullscreen()
    }
  }

  isFullscreen() {
    return !!(document.fullscreenElement || 
              document.webkitFullscreenElement || 
              document.msFullscreenElement)
  }

  toggleFullscreen() {
    if (this.isFullscreen()) {
      this.exitFullscreen()
    } else {
      this.enterFullscreen()
    }
  }
}