import { Application } from "@hotwired/stimulus"
import VersionComparisonController from "../../../app/javascript/controllers/version_comparison_controller"
import '../setup'

describe("VersionComparisonController", () => {
  let application
  let element

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="version-comparison">
        <form data-controller="version-selector">
          <select name="version1">
            <option value="3">Version 3 - 03/01/2025 10:00</option>
            <option value="2" selected>Version 2 - 02/01/2025 10:00</option>
            <option value="1">Version 1 - 01/01/2025 10:00</option>
          </select>
          <select name="version2">
            <option value="3" selected>Version 3 - 03/01/2025 10:00</option>
            <option value="2">Version 2 - 02/01/2025 10:00</option>
            <option value="1">Version 1 - 01/01/2025 10:00</option>
          </select>
        </form>
        <button data-action="click->version-comparison#previousVersion">Previous</button>
        <button data-action="click->version-comparison#nextVersion">Next</button>
      </div>
    `

    application = Application.start()
    application.register("version-comparison", VersionComparisonController)
    element = document.querySelector('[data-controller="version-comparison"]')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("initialization", () => {
    it("extracts versions from select options", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "version-comparison")
      
      expect(controller.versions).toHaveLength(3)
      expect(controller.versions[0].id).toBe(3)
      expect(controller.versions[2].id).toBe(1)
    })
  })

  describe("previousVersion", () => {
    it("moves to older version", () => {
      const form = document.querySelector('form')
      const submitSpy = jest.spyOn(form, 'requestSubmit').mockImplementation(() => {})
      const previousButton = document.querySelector('[data-action*="previousVersion"]')
      
      previousButton.click()
      
      const version1Select = document.querySelector('select[name="version1"]')
      expect(version1Select.value).toBe('1')
      expect(submitSpy).toHaveBeenCalled()
    })

    it("does nothing when at oldest version", () => {
      // Set to oldest version
      document.querySelector('select[name="version1"]').value = '1'
      
      const form = document.querySelector('form')
      const submitSpy = jest.spyOn(form, 'requestSubmit').mockImplementation(() => {})
      const previousButton = document.querySelector('[data-action*="previousVersion"]')
      
      previousButton.click()
      
      expect(submitSpy).not.toHaveBeenCalled()
    })
  })

  describe("nextVersion", () => {
    it("moves to newer version", () => {
      // Set version2 to middle version
      document.querySelector('select[name="version2"]').value = '2'
      
      const form = document.querySelector('form')
      const submitSpy = jest.spyOn(form, 'requestSubmit').mockImplementation(() => {})
      const nextButton = document.querySelector('[data-action*="nextVersion"]')
      
      nextButton.click()
      
      const version2Select = document.querySelector('select[name="version2"]')
      expect(version2Select.value).toBe('3')
      expect(submitSpy).toHaveBeenCalled()
    })

    it("does nothing when at newest version", () => {
      const form = document.querySelector('form')
      const submitSpy = jest.spyOn(form, 'requestSubmit').mockImplementation(() => {})
      const nextButton = document.querySelector('[data-action*="nextVersion"]')
      
      nextButton.click()
      
      expect(submitSpy).not.toHaveBeenCalled()
    })
  })

  describe("version selection helpers", () => {
    it("gets current version1", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "version-comparison")
      
      expect(controller.getCurrentVersion1()).toBe(2)
    })

    it("gets current version2", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "version-comparison")
      
      expect(controller.getCurrentVersion2()).toBe(3)
    })

    it("handles missing selects gracefully", () => {
      document.querySelector('select[name="version1"]').remove()
      document.querySelector('select[name="version2"]').remove()
      
      const controller = application.getControllerForElementAndIdentifier(element, "version-comparison")
      
      expect(controller.getCurrentVersion1()).toBeNull()
      expect(controller.getCurrentVersion2()).toBeNull()
      expect(controller.versions).toEqual([])
    })
  })

  describe("updateVersionSelectors", () => {
    it("updates both select values", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "version-comparison")
      const form = document.querySelector('form')
      jest.spyOn(form, 'requestSubmit').mockImplementation(() => {})
      
      controller.updateVersionSelectors(1, 2)
      
      expect(document.querySelector('select[name="version1"]').value).toBe('1')
      expect(document.querySelector('select[name="version2"]').value).toBe('2')
    })

    it("handles missing form gracefully", () => {
      document.querySelector('form').remove()
      
      const controller = application.getControllerForElementAndIdentifier(element, "version-comparison")
      
      // Should not throw
      expect(() => controller.updateVersionSelectors(1, 2)).not.toThrow()
    })
  })
})