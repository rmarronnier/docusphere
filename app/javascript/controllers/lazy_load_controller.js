import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "placeholder"]
  static values = { 
    src: String,
    threshold: { type: Number, default: 0.1 },
    rootMargin: { type: String, default: "50px" }
  }

  connect() {
    // Use Intersection Observer for efficient lazy loading
    this.observer = new IntersectionObserver(
      this.handleIntersection.bind(this),
      {
        threshold: this.thresholdValue,
        rootMargin: this.rootMarginValue
      }
    )

    // Observe all lazy load targets
    if (this.hasImageTarget) {
      this.imageTargets.forEach(image => this.observer.observe(image))
    } else {
      this.observer.observe(this.element)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  handleIntersection(entries) {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        this.loadImage(entry.target)
        this.observer.unobserve(entry.target)
      }
    })
  }

  loadImage(element) {
    const imgElement = element.tagName === 'IMG' ? element : element.querySelector('img')
    
    if (!imgElement) return

    // Get the data-src or use the value from controller
    const src = imgElement.dataset.src || this.srcValue
    
    if (!src) return

    // Create a new image to preload
    const tempImg = new Image()
    
    tempImg.onload = () => {
      // Add fade-in animation
      imgElement.style.opacity = '0'
      imgElement.src = src
      
      // Remove placeholder if exists
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.style.opacity = '0'
        setTimeout(() => {
          this.placeholderTarget.remove()
        }, 300)
      }
      
      // Fade in the loaded image
      requestAnimationFrame(() => {
        imgElement.style.transition = 'opacity 300ms ease-in-out'
        imgElement.style.opacity = '1'
      })
      
      // Remove the data-src attribute
      imgElement.removeAttribute('data-src')
      
      // Add loaded class
      element.classList.add('lazy-loaded')
      
      // Dispatch custom event
      this.dispatch('loaded', { detail: { src } })
    }
    
    tempImg.onerror = () => {
      // Handle error - maybe show a placeholder
      element.classList.add('lazy-error')
      this.dispatch('error', { detail: { src } })
    }
    
    // Start loading
    tempImg.src = src
  }

  // Manual trigger for loading
  load() {
    if (this.hasImageTarget) {
      this.imageTargets.forEach(image => this.loadImage(image))
    } else {
      this.loadImage(this.element)
    }
  }

  // Preload images for better performance
  static preload(urls) {
    urls.forEach(url => {
      const img = new Image()
      img.src = url
    })
  }
}