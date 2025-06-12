import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "tagList"]
  
  connect() {
    this.tags = this.getTagsFromInput()
    this.renderTags()
  }

  getTagsFromInput() {
    const value = this.element.value || ''
    return value.split(',').map(tag => tag.trim()).filter(tag => tag.length > 0)
  }

  handleKeydown(event) {
    if (event.key === 'Enter' || event.key === ',') {
      event.preventDefault()
      this.addTag()
    } else if (event.key === 'Backspace' && this.element.value === '') {
      event.preventDefault()
      this.removeLastTag()
    }
  }

  addTag() {
    const value = this.element.value.trim()
    
    if (value && !this.tags.includes(value)) {
      this.tags.push(value)
      this.updateInput()
      this.renderTags()
      this.element.value = ''
      
      // Dispatch custom event
      this.dispatch('tag-added', { detail: { tag: value } })
    }
  }

  removeTag(event) {
    const tagToRemove = event.currentTarget.dataset.tag
    this.tags = this.tags.filter(tag => tag !== tagToRemove)
    this.updateInput()
    this.renderTags()
    
    // Dispatch custom event
    this.dispatch('tag-removed', { detail: { tag: tagToRemove } })
  }

  removeLastTag() {
    if (this.tags.length > 0) {
      const removedTag = this.tags.pop()
      this.updateInput()
      this.renderTags()
      
      // Dispatch custom event
      this.dispatch('tag-removed', { detail: { tag: removedTag } })
    }
  }

  updateInput() {
    // Update a hidden input with the comma-separated tags
    let hiddenInput = this.element.parentElement.querySelector('input[type="hidden"][name="document[tags]"]')
    
    if (!hiddenInput) {
      hiddenInput = document.createElement('input')
      hiddenInput.type = 'hidden'
      hiddenInput.name = this.element.name
      this.element.parentElement.appendChild(hiddenInput)
      
      // Remove name from visible input to prevent double submission
      this.element.removeAttribute('name')
    }
    
    hiddenInput.value = this.tags.join(', ')
  }

  renderTags() {
    // Check if we have a tag list container
    let tagList = this.element.parentElement.querySelector('.tag-input-list')
    
    if (!tagList) {
      // Create tag list container
      tagList = document.createElement('div')
      tagList.className = 'tag-input-list flex flex-wrap gap-1 mb-2'
      this.element.parentElement.insertBefore(tagList, this.element)
    }
    
    // Clear existing tags
    tagList.innerHTML = ''
    
    // Render each tag
    this.tags.forEach(tag => {
      const tagElement = document.createElement('span')
      tagElement.className = 'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800'
      tagElement.innerHTML = `
        ${tag}
        <button type="button" 
                class="ml-1 inline-flex items-center justify-center w-4 h-4 text-indigo-400 hover:text-indigo-600"
                data-tag="${tag}"
                data-action="click->tag-input#removeTag">
          <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
      `
      tagList.appendChild(tagElement)
    })
  }

  dispatch(eventName, options = {}) {
    this.element.dispatchEvent(new CustomEvent(eventName, {
      bubbles: true,
      ...options
    }))
  }
}