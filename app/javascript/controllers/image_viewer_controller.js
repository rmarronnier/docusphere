import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "zoomLevel"]
  
  connect() {
    this.zoom = 1
    this.rotation = 0
    this.flipX = 1
    this.flipY = 1
    this.isDragging = false
    this.startX = 0
    this.startY = 0
    this.translateX = 0
    this.translateY = 0
    
    this.setupEventListeners()
  }

  disconnect() {
    this.removeEventListeners()
  }

  setupEventListeners() {
    // Mouse wheel zoom
    this.element.addEventListener('wheel', this.handleWheel.bind(this), { passive: false })
    
    // Drag to pan
    this.imageTarget.addEventListener('mousedown', this.startDrag.bind(this))
    document.addEventListener('mousemove', this.drag.bind(this))
    document.addEventListener('mouseup', this.endDrag.bind(this))
    
    // Touch support
    this.imageTarget.addEventListener('touchstart', this.startTouch.bind(this))
    document.addEventListener('touchmove', this.touchMove.bind(this))
    document.addEventListener('touchend', this.endTouch.bind(this))
  }

  removeEventListeners() {
    this.element.removeEventListener('wheel', this.handleWheel.bind(this))
    this.imageTarget.removeEventListener('mousedown', this.startDrag.bind(this))
    document.removeEventListener('mousemove', this.drag.bind(this))
    document.removeEventListener('mouseup', this.endDrag.bind(this))
    this.imageTarget.removeEventListener('touchstart', this.startTouch.bind(this))
    document.removeEventListener('touchmove', this.touchMove.bind(this))
    document.removeEventListener('touchend', this.endTouch.bind(this))
  }

  handleWheel(event) {
    if (event.ctrlKey || event.metaKey) {
      event.preventDefault()
      const delta = event.deltaY > 0 ? 0.9 : 1.1
      this.setZoom(this.zoom * delta)
    }
  }

  zoom(event) {
    if (event) {
      event.preventDefault()
    }
    this.handleWheel(event)
  }

  zoomIn() {
    this.setZoom(this.zoom * 1.25)
  }

  zoomOut() {
    this.setZoom(this.zoom * 0.8)
  }

  setZoom(newZoom) {
    this.zoom = Math.max(0.1, Math.min(5, newZoom))
    this.updateTransform()
    this.updateZoomDisplay()
  }

  fit() {
    this.zoom = 1
    this.translateX = 0
    this.translateY = 0
    this.updateTransform()
    this.updateZoomDisplay()
  }

  actualSize() {
    // Calculate zoom to show image at actual pixel size
    const containerWidth = this.element.offsetWidth
    const imageNaturalWidth = this.imageTarget.naturalWidth
    this.zoom = imageNaturalWidth / this.imageTarget.offsetWidth
    this.translateX = 0
    this.translateY = 0
    this.updateTransform()
    this.updateZoomDisplay()
  }

  rotate() {
    this.rotation = (this.rotation + 90) % 360
    this.updateTransform()
  }

  flipHorizontal() {
    this.flipX *= -1
    this.updateTransform()
  }

  flipVertical() {
    this.flipY *= -1
    this.updateTransform()
  }

  startDrag(event) {
    if (this.zoom > 1) {
      this.isDragging = true
      this.startX = event.clientX - this.translateX
      this.startY = event.clientY - this.translateY
      this.imageTarget.style.cursor = 'grabbing'
      event.preventDefault()
    }
  }

  drag(event) {
    if (this.isDragging) {
      this.translateX = event.clientX - this.startX
      this.translateY = event.clientY - this.startY
      this.updateTransform()
      event.preventDefault()
    }
  }

  endDrag() {
    this.isDragging = false
    this.imageTarget.style.cursor = this.zoom > 1 ? 'grab' : 'default'
  }

  // Touch support
  startTouch(event) {
    if (event.touches.length === 1 && this.zoom > 1) {
      const touch = event.touches[0]
      this.isDragging = true
      this.startX = touch.clientX - this.translateX
      this.startY = touch.clientY - this.translateY
      event.preventDefault()
    } else if (event.touches.length === 2) {
      // Pinch to zoom
      this.initialPinchDistance = this.getPinchDistance(event.touches)
      this.initialZoom = this.zoom
    }
  }

  touchMove(event) {
    if (event.touches.length === 1 && this.isDragging) {
      const touch = event.touches[0]
      this.translateX = touch.clientX - this.startX
      this.translateY = touch.clientY - this.startY
      this.updateTransform()
      event.preventDefault()
    } else if (event.touches.length === 2 && this.initialPinchDistance) {
      const currentDistance = this.getPinchDistance(event.touches)
      const scale = currentDistance / this.initialPinchDistance
      this.setZoom(this.initialZoom * scale)
      event.preventDefault()
    }
  }

  endTouch() {
    this.isDragging = false
    this.initialPinchDistance = null
  }

  getPinchDistance(touches) {
    const dx = touches[0].clientX - touches[1].clientX
    const dy = touches[0].clientY - touches[1].clientY
    return Math.sqrt(dx * dx + dy * dy)
  }

  updateTransform() {
    const transform = `
      translate(${this.translateX}px, ${this.translateY}px)
      scale(${this.zoom * this.flipX}, ${this.zoom * this.flipY})
      rotate(${this.rotation}deg)
    `
    this.imageTarget.style.transform = transform
    
    // Update cursor based on zoom
    if (this.zoom > 1) {
      this.imageTarget.style.cursor = this.isDragging ? 'grabbing' : 'grab'
    } else {
      this.imageTarget.style.cursor = 'default'
    }
  }

  updateZoomDisplay() {
    if (this.hasZoomLevelTarget) {
      this.zoomLevelTarget.textContent = `${Math.round(this.zoom * 100)}%`
    }
  }

  // Navigation between images in a collection
  previous() {
    const event = new CustomEvent('image-viewer:navigate', { 
      detail: { direction: 'previous' },
      bubbles: true 
    })
    this.element.dispatchEvent(event)
  }

  next() {
    const event = new CustomEvent('image-viewer:navigate', { 
      detail: { direction: 'next' },
      bubbles: true 
    })
    this.element.dispatchEvent(event)
  }
}