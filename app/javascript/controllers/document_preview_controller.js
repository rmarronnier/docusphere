import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop", "content", "viewer", "loading", "error"]
  static values = { id: Number }
  
  connect() {
    // Bind escape key to close modal
    this.handleEscape = this.handleEscape.bind(this)
    this.handleClickOutside = this.handleClickOutside.bind(this)
  }
  
  disconnect() {
    this.close()
  }
  
  open(event) {
    event.preventDefault()
    
    const documentId = event.currentTarget.dataset.documentId || this.idValue
    const previewUrl = event.currentTarget.dataset.previewUrl
    
    if (documentId) {
      this.idValue = documentId
    }
    
    // Show modal
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    
    // Add event listeners
    document.addEventListener("keydown", this.handleEscape)
    
    // Load preview content if URL provided
    if (previewUrl && this.hasViewerTarget) {
      this.loadPreview(previewUrl)
    }
    
    // Animate in
    requestAnimationFrame(() => {
      this.backdropTarget.classList.add("opacity-100")
      this.contentTarget.classList.add("opacity-100", "scale-100")
    })
  }
  
  close(event) {
    if (event) {
      event.preventDefault()
    }
    
    // Animate out
    this.backdropTarget.classList.remove("opacity-100")
    this.contentTarget.classList.remove("opacity-100", "scale-100")
    
    // Hide modal after animation
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
      
      // Remove event listeners
      document.removeEventListener("keydown", this.handleEscape)
      
      // Clear any loaded content
      if (this.hasViewerTarget) {
        this.viewerTarget.innerHTML = ""
      }
    }, 300)
  }
  
  closeOnBackdrop(event) {
    // Only close if clicking directly on backdrop
    if (event.target === event.currentTarget || event.target === this.backdropTarget) {
      this.close(event)
    }
  }
  
  stopPropagation(event) {
    event.stopPropagation()
  }
  
  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
  
  handleClickOutside(event) {
    if (!this.contentTarget.contains(event.target)) {
      this.close()
    }
  }
  
  async loadPreview(url) {
    // Show loading state
    this.showLoading()
    
    try {
      const response = await fetch(url, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      
      const html = await response.text()
      
      // Update viewer content
      if (this.hasViewerTarget) {
        this.viewerTarget.innerHTML = html
      }
      
      // Hide loading state
      this.hideLoading()
      
      // Initialize any sub-controllers in the loaded content
      this.application.dispatch("preview:loaded", { 
        target: this.viewerTarget,
        detail: { documentId: this.idValue }
      })
      
    } catch (error) {
      console.error("Error loading preview:", error)
      this.showError()
    }
  }
  
  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden")
    }
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
  }
  
  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
  }
  
  showError() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden")
    }
    if (this.hasErrorTarget) {
      this.errorTarget.classList.remove("hidden")
    }
  }
  
  share(event) {
    event.preventDefault()
    
    // Dispatch custom event for share functionality
    this.dispatch("share", { 
      detail: { documentId: this.idValue }
    })
    
    // Could open a share modal or trigger other share functionality
    console.log("Share document:", this.idValue)
  }
  
  download(event) {
    // Let the default link behavior handle the download
    // but we can track it
    this.dispatch("download", { 
      detail: { documentId: this.idValue }
    })
  }
  
  // Navigation methods for multi-document preview
  next(event) {
    event.preventDefault()
    this.dispatch("navigate", { 
      detail: { direction: "next", currentId: this.idValue }
    })
  }
  
  previous(event) {
    event.preventDefault()
    this.dispatch("navigate", { 
      detail: { direction: "previous", currentId: this.idValue }
    })
  }
}