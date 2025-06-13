import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["infoTab", "metadataTab", "activityTab", "versionsTab"]
  
  connect() {
    console.log('Document sidebar controller connected')
    // Set initial active tab
    this.activeTab = 'info'
    console.log('Available targets:', {
      hasInfo: this.hasInfoTabTarget,
      hasMetadata: this.hasMetadataTabTarget,
      hasActivity: this.hasActivityTabTarget,
      hasVersions: this.hasVersionsTabTarget
    })
  }

  showTab(event) {
    event.preventDefault()
    
    // Get the tab name from the data attribute
    const button = event.currentTarget
    const tabName = button.dataset.documentSidebarTabParam
    console.log('Switching to tab:', tabName)
    console.log('Button clicked:', button)
    console.log('Tab param value:', tabName)
    
    // Update button states
    const buttons = this.element.querySelectorAll('nav button')
    buttons.forEach(button => {
      const isActive = button.dataset.documentSidebarTabParam === tabName
      if (isActive) {
        button.classList.add('text-blue-600', 'border-blue-600', 'bg-white')
        button.classList.remove('text-gray-600', 'border-transparent', 'hover:text-gray-900', 'hover:border-gray-300')
      } else {
        button.classList.remove('text-blue-600', 'border-blue-600', 'bg-white')
        button.classList.add('text-gray-600', 'border-transparent', 'hover:text-gray-900', 'hover:border-gray-300')
      }
    })
    
    // Show/hide tab content
    this.hideAllTabs()
    this.showTabContent(tabName)
    
    this.activeTab = tabName
  }

  hideAllTabs() {
    if (this.hasInfoTabTarget) this.infoTabTarget.classList.add('hidden')
    if (this.hasMetadataTabTarget) this.metadataTabTarget.classList.add('hidden')
    if (this.hasActivityTabTarget) this.activityTabTarget.classList.add('hidden')
    if (this.hasVersionsTabTarget) this.versionsTabTarget.classList.add('hidden')
  }

  showTabContent(tabName) {
    console.log('Showing tab content for:', tabName)
    const target = this[`${tabName}TabTarget`]
    console.log('Target element:', target)
    if (target) {
      target.classList.remove('hidden')
      
      // Load content if needed
      if (tabName === 'activity' && !target.dataset.loaded) {
        this.loadActivityContent()
      }
    } else {
      console.error(`No target found for tab: ${tabName}`)
    }
  }

  loadActivityContent() {
    // This could fetch activity data via AJAX if needed
    // For now, we assume activity is loaded server-side
    if (this.hasActivityTabTarget) {
      this.activityTabTarget.dataset.loaded = 'true'
    }
  }

  toggleSidebar() {
    const sidebar = this.element
    sidebar.classList.toggle('w-80')
    sidebar.classList.toggle('w-0')
    sidebar.classList.toggle('hidden')
    
    // Dispatch event for other components to react
    const event = new CustomEvent('sidebar:toggled', {
      detail: { visible: !sidebar.classList.contains('hidden') },
      bubbles: true
    })
    this.element.dispatchEvent(event)
  }
}