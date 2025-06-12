import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["activityItem", "actionsMenu"]
  
  connect() {
    this.activeFilter = 'all'
    this.visibleCount = 20
  }

  filterActivities(event) {
    const filterType = event.params.filter
    this.activeFilter = filterType
    
    // Update active tab styling
    const buttons = this.element.querySelectorAll('nav button')
    buttons.forEach(button => {
      const isActive = button.dataset.activityTimelineFilterParam === filterType
      if (isActive) {
        button.classList.add('border-blue-500', 'text-blue-600')
        button.classList.remove('border-transparent', 'text-gray-500', 'hover:text-gray-700', 'hover:border-gray-300')
      } else {
        button.classList.remove('border-blue-500', 'text-blue-600')
        button.classList.add('border-transparent', 'text-gray-500', 'hover:text-gray-700', 'hover:border-gray-300')
      }
    })
    
    // Filter activity items
    this.activityItemTargets.forEach(item => {
      const activityType = item.dataset.activityType
      const shouldShow = this.shouldShowActivity(activityType, filterType)
      
      if (shouldShow) {
        item.classList.remove('hidden')
      } else {
        item.classList.add('hidden')
      }
    })
    
    // Update counts
    this.updateFilterCounts()
  }

  shouldShowActivity(activityType, filterType) {
    if (filterType === 'all') return true
    
    const filterMap = {
      'updates': ['document_updated', 'document_created'],
      'validations': ['validation_requested', 'validation_approved', 'validation_rejected', 'validation_validated'],
      'shares': ['document_shared'],
      'versions': ['version_created']
    }
    
    return filterMap[filterType]?.includes(activityType) || false
  }

  updateFilterCounts() {
    const counts = {
      all: 0,
      updates: 0,
      validations: 0,
      shares: 0,
      versions: 0
    }
    
    this.activityItemTargets.forEach(item => {
      if (!item.classList.contains('hidden')) {
        counts.all++
        const type = item.dataset.activityType
        
        if (type.includes('update') || type.includes('created')) counts.updates++
        if (type.includes('validation')) counts.validations++
        if (type.includes('shared')) counts.shares++
        if (type.includes('version')) counts.versions++
      }
    })
    
    // Update count badges
    const buttons = this.element.querySelectorAll('nav button')
    buttons.forEach(button => {
      const filterType = button.dataset.activityTimelineFilterParam
      const badge = button.querySelector('span')
      if (badge && counts[filterType] !== undefined) {
        badge.textContent = counts[filterType]
      }
    })
  }

  toggleActions(event) {
    event.stopPropagation()
    const button = event.currentTarget
    const menu = button.nextElementSibling
    
    // Close all other menus
    this.actionsMenuTargets.forEach(m => {
      if (m !== menu) m.classList.add('hidden')
    })
    
    // Toggle this menu
    menu.classList.toggle('hidden')
    
    // Add click outside listener
    if (!menu.classList.contains('hidden')) {
      setTimeout(() => {
        document.addEventListener('click', this.closeMenus.bind(this), { once: true })
      }, 0)
    }
  }

  closeMenus() {
    this.actionsMenuTargets.forEach(menu => {
      menu.classList.add('hidden')
    })
  }

  loadMore(event) {
    const button = event.currentTarget
    button.disabled = true
    button.innerHTML = `
      <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-gray-700" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
      </svg>
      Loading...
    `
    
    // Fetch more activities
    const documentId = this.element.dataset.documentId
    const offset = this.activityItemTargets.length
    
    fetch(`/ged/documents/${documentId}/activities?offset=${offset}&limit=20`, {
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
      }
    })
    .then(response => response.text())
    .then(html => {
      // Handle Turbo Stream response
      Turbo.renderStreamMessage(html)
      
      // Re-enable button if more items might be available
      button.disabled = false
      button.innerHTML = `
        Load more activity
        <svg class="ml-2 -mr-1 h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
        </svg>
      `
    })
    .catch(error => {
      console.error('Error loading activities:', error)
      button.disabled = false
      button.textContent = 'Error loading activities. Try again.'
    })
  }

  disconnect() {
    this.closeMenus()
  }
}