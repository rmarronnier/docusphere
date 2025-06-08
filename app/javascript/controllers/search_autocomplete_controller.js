import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "suggestions", "form"]
  static values = { url: String }

  connect() {
    this.hideOnClickOutside = this.hideOnClickOutside.bind(this)
  }

  disconnect() {
    this.hideSuggestions()
  }

  search() {
    const query = this.inputTarget.value

    if (query.length < 2) {
      this.hideSuggestions()
      return
    }

    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.fetchSuggestions(query)
    }, 300)
  }

  async fetchSuggestions(query) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) throw new Error('Network response was not ok')
      
      const data = await response.json()
      this.showSuggestions(data.suggestions)
    } catch (error) {
      console.error('Error fetching suggestions:', error)
      this.hideSuggestions()
    }
  }

  showSuggestions(suggestions) {
    if (suggestions.length === 0) {
      this.hideSuggestions()
      return
    }

    const html = suggestions.map((suggestion, index) => `
      <a href="${suggestion.url}" 
         class="block px-4 py-3 hover:bg-gray-50 focus:bg-gray-50 focus:outline-none"
         data-action="click->search-autocomplete#selectSuggestion"
         data-search-autocomplete-index="${index}">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <div class="ml-3 flex-1">
            <p class="text-sm font-medium text-gray-900">${this.highlightMatch(suggestion.title, this.inputTarget.value)}</p>
            ${suggestion.description ? `<p class="text-sm text-gray-500">${suggestion.description}</p>` : ''}
            <p class="text-xs text-gray-400 mt-1">${suggestion.type} • ${suggestion.space}</p>
          </div>
        </div>
      </a>
    `).join('')

    this.suggestionsTarget.innerHTML = html
    this.suggestionsTarget.classList.remove('hidden')
    
    // Add click outside listener
    document.addEventListener('click', this.hideOnClickOutside)
  }

  highlightMatch(text, query) {
    const regex = new RegExp(`(${query})`, 'gi')
    return text.replace(regex, '<mark class="bg-yellow-200">$1</mark>')
  }

  hideSuggestions() {
    this.suggestionsTarget.classList.add('hidden')
    this.suggestionsTarget.innerHTML = ''
    document.removeEventListener('click', this.hideOnClickOutside)
  }

  hideOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideSuggestions()
    }
  }

  selectSuggestion(event) {
    event.preventDefault()
    const url = event.currentTarget.getAttribute('href')
    window.location.href = url
  }

  submitForm(event) {
    if (this.inputTarget.value.trim() === '') {
      event.preventDefault()
      return
    }
  }

  handleKeydown(event) {
    const suggestions = this.suggestionsTarget.querySelectorAll('a')
    const currentIndex = Array.from(suggestions).findIndex(s => s.classList.contains('bg-gray-50'))

    switch(event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.navigateSuggestions(suggestions, currentIndex, 1)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.navigateSuggestions(suggestions, currentIndex, -1)
        break
      case 'Enter':
        if (currentIndex >= 0 && !this.suggestionsTarget.classList.contains('hidden')) {
          event.preventDefault()
          suggestions[currentIndex].click()
        }
        break
      case 'Escape':
        this.hideSuggestions()
        break
    }
  }

  navigateSuggestions(suggestions, currentIndex, direction) {
    if (suggestions.length === 0) return

    // Remove current highlight
    if (currentIndex >= 0) {
      suggestions[currentIndex].classList.remove('bg-gray-50')
    }

    // Calculate new index
    let newIndex = currentIndex + direction
    if (newIndex < 0) newIndex = suggestions.length - 1
    if (newIndex >= suggestions.length) newIndex = 0

    // Add new highlight
    suggestions[newIndex].classList.add('bg-gray-50')
    suggestions[newIndex].scrollIntoView({ block: 'nearest' })
  }
}