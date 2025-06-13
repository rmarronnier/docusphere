import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="auto-resize"
export default class extends Controller {
  connect() {
    this.resize()
  }

  resize() {
    // Reset height to auto to get the correct scrollHeight
    this.element.style.height = 'auto'
    
    // Calculate the new height based on scroll height
    const newHeight = Math.max(this.element.scrollHeight, this.minHeight)
    
    // Set the new height with a maximum limit
    this.element.style.height = Math.min(newHeight, this.maxHeight) + 'px'
  }

  get minHeight() {
    // Minimum height based on rows attribute or default
    const rows = parseInt(this.element.getAttribute('rows') || '3')
    const lineHeight = parseInt(getComputedStyle(this.element).lineHeight || '20')
    const padding = this.getVerticalPadding()
    return (rows * lineHeight) + padding
  }

  get maxHeight() {
    // Maximum height to prevent excessive growth
    return parseInt(this.data.get('maxHeight')) || 400
  }

  getVerticalPadding() {
    const computedStyle = getComputedStyle(this.element)
    const paddingTop = parseInt(computedStyle.paddingTop || '0')
    const paddingBottom = parseInt(computedStyle.paddingBottom || '0')
    const borderTop = parseInt(computedStyle.borderTopWidth || '0')
    const borderBottom = parseInt(computedStyle.borderBottomWidth || '0')
    return paddingTop + paddingBottom + borderTop + borderBottom
  }
}