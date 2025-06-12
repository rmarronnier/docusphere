import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handleKeyPress = this.handleKeyPress.bind(this)
    this.setupKeyboardListeners()
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeyPress)
  }

  setupKeyboardListeners() {
    // Global keyboard listener for shortcuts
    document.addEventListener('keydown', this.handleKeyPress)
  }

  handleKeyPress(event) {
    // Don't capture keys when user is typing in input/textarea
    if (event.target.matches('input, textarea, select')) {
      return
    }

    // Handle shortcuts based on key
    switch(event.key.toLowerCase()) {
      case '?':
        if (event.shiftKey) {
          event.preventDefault()
          this.showHelp()
        }
        break
      case 'd':
        if (!event.metaKey && !event.ctrlKey) {
          event.preventDefault()
          this.download()
        }
        break
      case 'p':
        if (!event.metaKey && !event.ctrlKey) {
          event.preventDefault()
          this.print()
        }
        break
      case 's':
        if (!event.metaKey && !event.ctrlKey) {
          event.preventDefault()
          this.share()
        }
        break
      case 'e':
        if (!event.metaKey && !event.ctrlKey) {
          event.preventDefault()
          this.edit()
        }
        break
      case 'f':
        if (!event.metaKey && !event.ctrlKey) {
          event.preventDefault()
          this.fullscreen()
        }
        break
      case '+':
      case '=':
        event.preventDefault()
        this.zoomIn()
        break
      case '-':
        event.preventDefault()
        this.zoomOut()
        break
      case '0':
        event.preventDefault()
        this.resetZoom()
        break
      case 'arrowleft':
        if (!event.metaKey && !event.ctrlKey) {
          event.preventDefault()
          this.previousDocument()
        }
        break
      case 'arrowright':
        if (!event.metaKey && !event.ctrlKey) {
          event.preventDefault()
          this.nextDocument()
        }
        break
      case 'arrowup':
        if (!event.metaKey && !event.ctrlKey) {
          event.preventDefault()
          this.previousPage()
        }
        break
      case 'arrowdown':
        if (!event.metaKey && !event.ctrlKey) {
          event.preventDefault()
          this.nextPage()
        }
        break
      case 'escape':
        event.preventDefault()
        this.escape()
        break
    }
  }

  showHelp() {
    const modal = document.getElementById('keyboard-shortcuts-modal')
    if (modal) {
      modal.classList.remove('hidden')
      modal.dispatchEvent(new Event('modal:open'))
    }
  }

  download() {
    const downloadButton = document.querySelector('[data-action*="download"]')
    if (downloadButton) {
      downloadButton.click()
    }
  }

  print() {
    const printButton = document.querySelector('[data-action*="print"]')
    if (printButton) {
      printButton.click()
    } else {
      window.print()
    }
  }

  share() {
    const shareButton = document.querySelector('[data-action*="share"]')
    if (shareButton) {
      shareButton.click()
    }
  }

  edit() {
    const editButton = document.querySelector('[data-action*="edit-metadata"]')
    if (editButton) {
      editButton.click()
    }
  }

  fullscreen() {
    const viewerElement = document.querySelector('[data-document-viewer-target="viewer"]')
    if (viewerElement) {
      if (!document.fullscreenElement) {
        viewerElement.requestFullscreen()
      } else {
        document.exitFullscreen()
      }
    }
  }

  zoomIn() {
    this.dispatch('zoom-in')
  }

  zoomOut() {
    this.dispatch('zoom-out')
  }

  resetZoom() {
    this.dispatch('reset-zoom')
  }

  previousDocument() {
    this.dispatch('navigate-previous')
  }

  nextDocument() {
    this.dispatch('navigate-next')
  }

  previousPage() {
    this.dispatch('page-up')
  }

  nextPage() {
    this.dispatch('page-down')
  }

  escape() {
    // Close any open modal
    const openModal = document.querySelector('.modal:not(.hidden), [data-controller*="modal"]:not(.hidden)')
    if (openModal) {
      openModal.classList.add('hidden')
      openModal.dispatchEvent(new Event('modal:close'))
    }
    
    // Exit fullscreen if active
    if (document.fullscreenElement) {
      document.exitFullscreen()
    }
  }

  dispatch(eventName, detail = {}) {
    this.element.dispatchEvent(new CustomEvent(eventName, { 
      detail,
      bubbles: true 
    }))
  }
}