import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "zoomedImage"]
  static values = { src: String }
  
  connect() {
    this.handleEscape = this.handleEscape.bind(this)
    this.handleWheel = this.handleWheel.bind(this)
    this.scale = 1
    this.translateX = 0
    this.translateY = 0
    this.isDragging = false
  }
  
  disconnect() {
    this.close()
  }
  
  toggle(event) {
    event.preventDefault()
    
    if (this.hasModalTarget && !this.modalTarget.classList.contains("hidden")) {
      this.close()
    } else {
      this.open(event)
    }
  }
  
  open(event) {
    const imageSrc = this.srcValue || event.currentTarget.src
    
    if (!imageSrc || !this.hasModalTarget || !this.hasZoomedImageTarget) {
      return
    }
    
    // Set image source
    this.zoomedImageTarget.src = imageSrc
    
    // Show modal
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    
    // Reset transform
    this.resetTransform()
    
    // Add event listeners
    document.addEventListener("keydown", this.handleEscape)
    this.zoomedImageTarget.addEventListener("wheel", this.handleWheel, { passive: false })
    
    // Set up drag functionality
    this.setupDrag()
    
    // Animate in
    requestAnimationFrame(() => {
      this.modalTarget.classList.add("opacity-100")
    })
  }
  
  close(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    if (!this.hasModalTarget) {
      return
    }
    
    // Animate out
    this.modalTarget.classList.remove("opacity-100")
    
    // Hide modal after animation
    setTimeout(() => {
      this.modalTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
      
      // Remove event listeners
      document.removeEventListener("keydown", this.handleEscape)
      if (this.hasZoomedImageTarget) {
        this.zoomedImageTarget.removeEventListener("wheel", this.handleWheel)
      }
      
      // Clean up drag
      this.cleanupDrag()
      
      // Reset state
      this.resetTransform()
    }, 300)
  }
  
  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
  
  handleWheel(event) {
    event.preventDefault()
    
    const delta = event.deltaY > 0 ? 0.9 : 1.1
    const newScale = Math.max(0.5, Math.min(5, this.scale * delta))
    
    if (newScale !== this.scale) {
      // Calculate zoom point relative to image
      const rect = this.zoomedImageTarget.getBoundingClientRect()
      const x = event.clientX - rect.left
      const y = event.clientY - rect.top
      
      // Adjust translation to zoom towards cursor
      const scaleChange = newScale / this.scale
      this.translateX = x - (x - this.translateX) * scaleChange
      this.translateY = y - (y - this.translateY) * scaleChange
      
      this.scale = newScale
      this.updateTransform()
    }
  }
  
  setupDrag() {
    if (!this.hasZoomedImageTarget) return
    
    this.zoomedImageTarget.style.cursor = "grab"
    
    this.handleMouseDown = this.handleMouseDown.bind(this)
    this.handleMouseMove = this.handleMouseMove.bind(this)
    this.handleMouseUp = this.handleMouseUp.bind(this)
    
    this.zoomedImageTarget.addEventListener("mousedown", this.handleMouseDown)
  }
  
  cleanupDrag() {
    if (!this.hasZoomedImageTarget) return
    
    this.zoomedImageTarget.removeEventListener("mousedown", this.handleMouseDown)
    document.removeEventListener("mousemove", this.handleMouseMove)
    document.removeEventListener("mouseup", this.handleMouseUp)
  }
  
  handleMouseDown(event) {
    if (this.scale <= 1) return
    
    event.preventDefault()
    this.isDragging = true
    this.dragStartX = event.clientX - this.translateX
    this.dragStartY = event.clientY - this.translateY
    
    this.zoomedImageTarget.style.cursor = "grabbing"
    
    document.addEventListener("mousemove", this.handleMouseMove)
    document.addEventListener("mouseup", this.handleMouseUp)
  }
  
  handleMouseMove(event) {
    if (!this.isDragging) return
    
    event.preventDefault()
    this.translateX = event.clientX - this.dragStartX
    this.translateY = event.clientY - this.dragStartY
    
    this.updateTransform()
  }
  
  handleMouseUp(event) {
    event.preventDefault()
    this.isDragging = false
    
    if (this.hasZoomedImageTarget) {
      this.zoomedImageTarget.style.cursor = "grab"
    }
    
    document.removeEventListener("mousemove", this.handleMouseMove)
    document.removeEventListener("mouseup", this.handleMouseUp)
  }
  
  resetTransform() {
    this.scale = 1
    this.translateX = 0
    this.translateY = 0
    this.updateTransform()
  }
  
  updateTransform() {
    if (!this.hasZoomedImageTarget) return
    
    this.zoomedImageTarget.style.transform = `translate(${this.translateX}px, ${this.translateY}px) scale(${this.scale})`
  }
  
  zoomIn(event) {
    event.preventDefault()
    this.scale = Math.min(5, this.scale * 1.2)
    this.updateTransform()
  }
  
  zoomOut(event) {
    event.preventDefault()
    this.scale = Math.max(0.5, this.scale * 0.8)
    this.updateTransform()
  }
  
  resetZoom(event) {
    event.preventDefault()
    this.resetTransform()
  }
}