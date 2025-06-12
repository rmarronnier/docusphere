import { Application } from "@hotwired/stimulus"
import VersionSelectorController from "../../../app/javascript/controllers/version_selector_controller"
import '../setup'

describe("VersionSelectorController", () => {
  let application
  let element

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="version-selector">
        <form data-action="submit->version-selector#submit">
          <select name="version1" data-action="change->version-selector#updateComparison">
            <option value="3">Version 3</option>
            <option value="2" selected>Version 2</option>
            <option value="1">Version 1</option>
          </select>
          <select name="version2" data-action="change->version-selector#updateComparison">
            <option value="3" selected>Version 3</option>
            <option value="2">Version 2</option>
            <option value="1">Version 1</option>
          </select>
          <button type="submit">Compare</button>
        </form>
      </div>
    `

    application = Application.start()
    application.register("version-selector", VersionSelectorController)
    element = document.querySelector('[data-controller="version-selector"]')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("updateComparison", () => {
    it("shows error when same versions selected", () => {
      const select1 = document.querySelector('select[name="version1"]')
      const select2 = document.querySelector('select[name="version2"]')
      
      select1.value = '2'
      select2.value = '2'
      
      const event = new Event('change', { bubbles: true })
      select1.dispatchEvent(event)
      
      expect(document.querySelector('.text-red-600')).toBeTruthy()
      expect(document.querySelector('.text-red-600').textContent).toContain('différentes')
    })

    it("shows error when version order is wrong", () => {
      const select1 = document.querySelector('select[name="version1"]')
      const select2 = document.querySelector('select[name="version2"]')
      
      select1.value = '3'
      select2.value = '1'
      
      const event = new Event('change', { bubbles: true })
      select1.dispatchEvent(event)
      
      expect(document.querySelector('.text-red-600')).toBeTruthy()
      expect(document.querySelector('.text-red-600').textContent).toContain('plus ancienne')
    })

    it("clears error when valid selection", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "version-selector")
      
      // First create an error
      controller.showError("Test error")
      expect(document.querySelector('.text-red-600')).toBeTruthy()
      
      // Then make valid selection
      const select1 = document.querySelector('select[name="version1"]')
      select1.value = '1'
      
      const event = new Event('change', { bubbles: true })
      select1.dispatchEvent(event)
      
      expect(document.querySelector('.text-red-600')).toBeFalsy()
    })
  })

  describe("submit", () => {
    it("prevents submission when same versions selected", () => {
      const form = document.querySelector('form')
      const submitSpy = jest.spyOn(form, 'requestSubmit').mockImplementation(() => {})
      
      document.querySelector('select[name="version1"]').value = '2'
      document.querySelector('select[name="version2"]').value = '2'
      
      const event = new Event('submit', { bubbles: true, cancelable: true })
      form.dispatchEvent(event)
      
      expect(submitSpy).not.toHaveBeenCalled()
      expect(document.querySelector('.text-red-600')).toBeTruthy()
    })

    it("allows submission with valid selection", () => {
      const form = document.querySelector('form')
      const submitSpy = jest.spyOn(form, 'requestSubmit').mockImplementation(() => {})
      
      document.querySelector('select[name="version1"]').value = '1'
      document.querySelector('select[name="version2"]').value = '3'
      
      const event = new Event('submit', { bubbles: true, cancelable: true })
      form.dispatchEvent(event)
      
      expect(submitSpy).toHaveBeenCalled()
    })
  })

  describe("error handling", () => {
    it("shows error message", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "version-selector")
      
      controller.showError("Test error message")
      
      const error = document.querySelector('.text-red-600')
      expect(error).toBeTruthy()
      expect(error.textContent).toBe("Test error message")
      expect(error.dataset.versionSelectorTarget).toBe('error')
    })

    it("clears existing error before showing new one", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "version-selector")
      
      controller.showError("First error")
      controller.showError("Second error")
      
      const errors = document.querySelectorAll('.text-red-600')
      expect(errors.length).toBe(1)
      expect(errors[0].textContent).toBe("Second error")
    })

    it("removes error element", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "version-selector")
      
      controller.showError("Test error")
      expect(document.querySelector('.text-red-600')).toBeTruthy()
      
      controller.clearError()
      expect(document.querySelector('.text-red-600')).toBeFalsy()
    })
  })

  describe("getVersionIndex", () => {
    it("returns correct index for version", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "version-selector")
      
      expect(controller.getVersionIndex('3')).toBe(0)
      expect(controller.getVersionIndex('2')).toBe(1)
      expect(controller.getVersionIndex('1')).toBe(2)
    })

    it("returns -1 for non-existent version", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "version-selector")
      
      expect(controller.getVersionIndex('999')).toBe(-1)
    })
  })
})