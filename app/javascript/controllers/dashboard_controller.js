import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["widgets"]
  
  connect() {
    // Initialize dashboard
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
  }
  
  async updateWidget(event) {
    const { widgetId, config } = event.detail
    
    try {
      const response = await fetch(`/dashboard/widgets/${widgetId}/update`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ widget: { config } })
      })
      
      if (!response.ok) {
        console.error(`Server error: ${response.status} ${response.statusText}`)
        return
      }
      
      const data = await response.json()
      this.dispatch("widget-updated", { detail: { widgetId, data } })
    } catch (error) {
      console.error('Error updating widget:', error)
    }
  }
  
  async reorderWidgets(event) {
    const { widgetIds } = event.detail
    
    try {
      const response = await fetch('/dashboard/widgets/reorder', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ widget_ids: widgetIds })
      })
      
      if (!response.ok) {
        console.error(`Server error: ${response.status} ${response.statusText}`)
        return
      }
      
      const data = await response.json()
      this.dispatch("widgets-reordered", { detail: { data } })
    } catch (error) {
      console.error('Error reordering widgets:', error)
    }
  }
  
  async refreshWidget(event) {
    const widgetId = event.currentTarget.getAttribute('data-widget-id')
    const widgetElement = this.element.querySelector(`[data-widget-id="${widgetId}"]`)
    
    if (!widgetElement) return
    
    // Show loading state
    widgetElement.classList.add('loading')
    
    try {
      const response = await fetch(`/dashboard/widgets/${widgetId}/refresh`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'application/json'
        }
      })
      
      if (!response.ok) {
        console.error(`Server error: ${response.status} ${response.statusText}`)
        return
      }
      
      const data = await response.json()
      
      // Update widget content if provided
      if (data.widget && data.widget.content) {
        const contentElement = widgetElement.querySelector('.widget-content')
        if (contentElement) {
          contentElement.innerHTML = data.widget.content
        }
      }
      
      this.dispatch("widget-refreshed", { detail: { widgetId, data } })
    } catch (error) {
      console.error('Error refreshing widget:', error)
    } finally {
      // Remove loading state
      widgetElement.classList.remove('loading')
    }
  }
  
  async resizeWidget(event) {
    const { widgetId, width, height } = event.detail
    
    try {
      const response = await fetch(`/dashboard/widgets/${widgetId}/update`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({ 
          widget: { 
            width: width,
            height: height
          } 
        })
      })
      
      if (!response.ok) {
        console.error(`Server error: ${response.status} ${response.statusText}`)
        return
      }
      
      const data = await response.json()
      this.dispatch("widget-resized", { detail: { widgetId, data } })
    } catch (error) {
      console.error('Error resizing widget:', error)
    }
  }
}