import { Application } from "@hotwired/stimulus"
import MetadataEditorController from "../../../app/javascript/controllers/metadata_editor_controller"
import '../setup'

describe("MetadataEditorController", () => {
  let application
  let element

  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="metadata-editor" data-metadata-editor-document-id-value="123">
        <form data-metadata-editor-target="form" action="/update_metadata/123" method="post">
          <input name="document[description]" value="Test description">
          <input name="document[tags]" value="tag1, tag2">
          <button type="submit">Save</button>
        </form>
        <button data-action="click->metadata-editor#edit">Edit</button>
        <button data-action="click->metadata-editor#cancel">Cancel</button>
        <div id="metadata-save-notification" class="hidden" data-metadata-editor-target="notification">
          Success
        </div>
      </div>
      <meta name="csrf-token" content="test-token">
    `

    application = Application.start()
    application.register("metadata-editor", MetadataEditorController)
    element = document.querySelector('[data-controller="metadata-editor"]')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("edit action", () => {
    let fetchMock

    beforeEach(() => {
      fetchMock = jest.fn()
      global.fetch = fetchMock
    })

    it("fetches edit form", async () => {
      fetchMock.mockResolvedValue({
        ok: true,
        text: async () => '<form>Edit form content</form>'
      })

      const editButton = document.querySelector('[data-action*="edit"]')
      editButton.click()

      await new Promise(resolve => setTimeout(resolve, 10))

      expect(fetchMock).toHaveBeenCalledWith(
        '/ged/documents/123/edit_metadata',
        expect.objectContaining({
          headers: expect.objectContaining({
            'Accept': 'text/vnd.turbo-stream.html',
            'X-CSRF-Token': 'test-token'
          })
        })
      )
    })

    it("replaces element content with response", async () => {
      const newContent = '<form>New edit form</form>'
      fetchMock.mockResolvedValue({
        ok: true,
        text: async () => newContent
      })

      const editButton = document.querySelector('[data-action*="edit"]')
      editButton.click()

      await new Promise(resolve => setTimeout(resolve, 10))

      expect(element.innerHTML).toBe(newContent)
    })
  })

  describe("cancel action", () => {
    let fetchMock

    beforeEach(() => {
      fetchMock = jest.fn()
      global.fetch = fetchMock
    })

    it("fetches view content", async () => {
      fetchMock.mockResolvedValue({
        ok: true,
        text: async () => '<div>View content</div>'
      })

      const cancelButton = document.querySelector('[data-action*="cancel"]')
      cancelButton.click()

      await new Promise(resolve => setTimeout(resolve, 10))

      expect(fetchMock).toHaveBeenCalledWith(
        '/ged/documents/123/metadata',
        expect.objectContaining({
          headers: expect.objectContaining({
            'Accept': 'text/vnd.turbo-stream.html',
            'X-CSRF-Token': 'test-token'
          })
        })
      )
    })
  })

  describe("save action", () => {
    let fetchMock

    beforeEach(() => {
      fetchMock = jest.fn()
      global.fetch = fetchMock
    })

    it("submits form data", async () => {
      fetchMock.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true, metadata: {} })
      })

      const form = document.querySelector('form')
      const event = new Event('submit', { bubbles: true, cancelable: true })
      form.dispatchEvent(event)

      await new Promise(resolve => setTimeout(resolve, 10))

      expect(fetchMock).toHaveBeenCalledWith(
        '/update_metadata/123',
        expect.objectContaining({
          method: 'POST',
          body: expect.any(FormData),
          headers: expect.objectContaining({
            'X-CSRF-Token': 'test-token'
          })
        })
      )
    })

    it("shows success notification", async () => {
      fetchMock.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true })
      })

      const controller = application.getControllerForElementAndIdentifier(element, "metadata-editor")
      const showNotificationSpy = jest.spyOn(controller, 'showNotification')

      const form = document.querySelector('form')
      const event = new Event('submit', { bubbles: true, cancelable: true })
      form.dispatchEvent(event)

      await new Promise(resolve => setTimeout(resolve, 10))

      expect(showNotificationSpy).toHaveBeenCalled()
    })

    it("dispatches saved event", async () => {
      fetchMock.mockResolvedValue({
        ok: true,
        json: async () => ({ success: true, metadata: { key: 'value' } })
      })

      const eventSpy = jest.fn()
      element.addEventListener('saved', eventSpy)

      const form = document.querySelector('form')
      const event = new Event('submit', { bubbles: true, cancelable: true })
      form.dispatchEvent(event)

      await new Promise(resolve => setTimeout(resolve, 10))

      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: {
            documentId: 123,
            metadata: { key: 'value' }
          }
        })
      )
    })

    it("shows error on failure", async () => {
      fetchMock.mockResolvedValue({
        ok: false,
        json: async () => ({ message: 'Validation error' })
      })

      const controller = application.getControllerForElementAndIdentifier(element, "metadata-editor")
      const showErrorSpy = jest.spyOn(controller, 'showError')

      const form = document.querySelector('form')
      const event = new Event('submit', { bubbles: true, cancelable: true })
      form.dispatchEvent(event)

      await new Promise(resolve => setTimeout(resolve, 10))

      expect(showErrorSpy).toHaveBeenCalledWith('Validation error')
    })
  })

  describe("notifications", () => {
    it("shows notification element when it exists", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "metadata-editor")
      const notification = document.querySelector('[data-metadata-editor-target="notification"]')

      controller.showNotification()

      expect(notification.classList.contains('hidden')).toBe(false)
    })

    it("creates notification when element doesn't exist", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "metadata-editor")
      document.querySelector('[data-metadata-editor-target="notification"]').remove()

      controller.showNotification()

      const notification = document.querySelector('.bg-green-500')
      expect(notification).toBeTruthy()
      expect(notification.textContent).toContain('Métadonnées enregistrées')
    })

    it("hides notification after delay", async () => {
      const controller = application.getControllerForElementAndIdentifier(element, "metadata-editor")
      const notification = document.querySelector('[data-metadata-editor-target="notification"]')

      controller.showNotification()

      await new Promise(resolve => setTimeout(resolve, 3500))

      expect(notification.classList.contains('hidden')).toBe(true)
    })

    it("creates error notification", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "metadata-editor")

      controller.showError('Test error')

      const notification = document.querySelector('.bg-red-500')
      expect(notification).toBeTruthy()
      expect(notification.textContent).toBe('Test error')
    })
  })
})