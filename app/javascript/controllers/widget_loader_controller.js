import { Controller } from "@hotwired/stimulus"

// Loads widget content dynamically with optional refresh and lazy loading
export default class extends Controller {
  static targets = ["content", "error"]
  static values = { 
    url: String,
    refreshInterval: { type: Number, default: 0 },
    lazy: { type: Boolean, default: false }
  }
  
  connect() {
    this.abortController = new AbortController()
    
    if (this.lazyValue) {
      this.setupLazyLoading()
    } else {
      this.loadContent()
    }
    
    if (this.refreshIntervalValue > 0) {
      this.startRefreshTimer()
    }
  }
  
  disconnect() {
    this.stopRefreshTimer()
    this.abortController.abort()
    if (this.intersectionObserver) {
      this.intersectionObserver.disconnect()
    }
  }
  
  async loadContent() {
    if (this.loading) return
    this.loading = true
    
    this.showSkeleton()
    this.hideError()
    
    try {
      const response = await fetch(this.urlValue, {
        signal: this.abortController.signal,
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }
      
      const html = await response.text()
      this.displayContent(html)
      
    } catch (error) {
      if (error.name !== 'AbortError') {
        this.displayError(error.message)
      }
    } finally {
      this.loading = false
    }
  }
  
  displayContent(html) {
    if (this.hasContentTarget) {
      this.contentTarget.innerHTML = html
      this.contentTarget.classList.remove('hidden')
    }
    this.hideSkeleton()
    this.hideError()
    
    // Dispatch event for other components to react
    this.dispatch('loaded', { detail: { html } })
  }
  
  displayError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.innerHTML = `
        <div class="bg-red-50 border border-red-200 rounded-md p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-red-800">Erreur de chargement</h3>
              <p class="mt-1 text-sm text-red-700">${message}</p>
              <button data-action="click->widget-loader#refresh" class="mt-2 text-sm font-medium text-red-600 hover:text-red-500">
                Réessayer
              </button>
            </div>
          </div>
        </div>
      `
      this.errorTarget.classList.remove('hidden')
    }
    this.hideSkeleton()
    this.hideContent()
  }
  
  refresh() {
    this.loadContent()
  }
  
  setupLazyLoading() {
    const options = {
      root: null,
      rootMargin: '100px',
      threshold: 0.01
    }
    
    this.intersectionObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && !this.loaded) {
          this.loaded = true
          this.loadContent()
          this.intersectionObserver.unobserve(entry.target)
        }
      })
    }, options)
    
    this.intersectionObserver.observe(this.element)
  }
  
  startRefreshTimer() {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, this.refreshIntervalValue)
  }
  
  stopRefreshTimer() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }
  
  showSkeleton() {
    const skeleton = this.element.querySelector('.widget-loader-skeleton')
    if (skeleton) {
      skeleton.classList.remove('hidden')
    }
  }
  
  hideSkeleton() {
    const skeleton = this.element.querySelector('.widget-loader-skeleton')
    if (skeleton) {
      skeleton.classList.add('hidden')
    }
  }
  
  showContent() {
    if (this.hasContentTarget) {
      this.contentTarget.classList.remove('hidden')
    }
  }
  
  hideContent() {
    if (this.hasContentTarget) {
      this.contentTarget.classList.add('hidden')
    }
  }
  
  showError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.remove('hidden')
    }
  }
  
  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add('hidden')
    }
  }
}