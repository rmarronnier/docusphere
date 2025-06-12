import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["version1Select", "version2Select"]
  
  connect() {
    this.versions = this.getVersionsFromSelects()
  }

  getVersionsFromSelects() {
    const select = document.querySelector('select[name="version1"]')
    if (!select) return []
    
    return Array.from(select.options).map(option => ({
      id: parseInt(option.value),
      text: option.text
    }))
  }

  previousVersion(event) {
    event.preventDefault()
    
    const currentVersion1 = this.getCurrentVersion1()
    const currentIndex = this.versions.findIndex(v => v.id === currentVersion1)
    
    if (currentIndex < this.versions.length - 1) {
      const newVersion = this.versions[currentIndex + 1]
      this.updateVersionSelectors(newVersion.id, currentVersion1)
    }
  }

  nextVersion(event) {
    event.preventDefault()
    
    const currentVersion2 = this.getCurrentVersion2()
    const currentIndex = this.versions.findIndex(v => v.id === currentVersion2)
    
    if (currentIndex > 0) {
      const newVersion = this.versions[currentIndex - 1]
      this.updateVersionSelectors(currentVersion2, newVersion.id)
    }
  }

  getCurrentVersion1() {
    const select = document.querySelector('select[name="version1"]')
    return select ? parseInt(select.value) : null
  }

  getCurrentVersion2() {
    const select = document.querySelector('select[name="version2"]')
    return select ? parseInt(select.value) : null
  }

  updateVersionSelectors(version1Id, version2Id) {
    const form = document.querySelector('form[data-controller="version-selector"]')
    if (!form) return
    
    // Update select values
    const version1Select = form.querySelector('select[name="version1"]')
    const version2Select = form.querySelector('select[name="version2"]')
    
    if (version1Select) version1Select.value = version1Id
    if (version2Select) version2Select.value = version2Id
    
    // Submit form to reload comparison
    form.requestSubmit()
  }
}