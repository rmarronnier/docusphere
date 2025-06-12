import { Application } from "@hotwired/stimulus"
import TagInputController from "../../../app/javascript/controllers/tag_input_controller"
import '../setup'

describe("TagInputController", () => {
  let application
  let element

  beforeEach(() => {
    document.body.innerHTML = `
      <div>
        <input type="text" 
               name="document[tags]" 
               value="tag1, tag2" 
               data-controller="tag-input"
               data-action="keydown->tag-input#handleKeydown">
      </div>
    `

    application = Application.start()
    application.register("tag-input", TagInputController)
    element = document.querySelector('[data-controller="tag-input"]')
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })

  describe("initialization", () => {
    it("parses existing tags from input", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "tag-input")
      
      expect(controller.tags).toEqual(['tag1', 'tag2'])
    })

    it("renders existing tags", () => {
      const tagList = document.querySelector('.tag-input-list')
      
      expect(tagList).toBeTruthy()
      expect(tagList.querySelectorAll('span').length).toBe(2)
      expect(tagList.textContent).toContain('tag1')
      expect(tagList.textContent).toContain('tag2')
    })

    it("creates hidden input", () => {
      const hiddenInput = document.querySelector('input[type="hidden"][name="document[tags]"]')
      
      expect(hiddenInput).toBeTruthy()
      expect(hiddenInput.value).toBe('tag1, tag2')
    })

    it("removes name from visible input", () => {
      expect(element.hasAttribute('name')).toBe(false)
    })
  })

  describe("adding tags", () => {
    it("adds tag on Enter key", () => {
      element.value = 'newtag'
      
      const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true })
      element.dispatchEvent(event)
      
      const controller = application.getControllerForElementAndIdentifier(element, "tag-input")
      expect(controller.tags).toContain('newtag')
      expect(element.value).toBe('')
    })

    it("adds tag on comma key", () => {
      element.value = 'newtag'
      
      const event = new KeyboardEvent('keydown', { key: ',', bubbles: true })
      element.dispatchEvent(event)
      
      const controller = application.getControllerForElementAndIdentifier(element, "tag-input")
      expect(controller.tags).toContain('newtag')
    })

    it("prevents duplicate tags", () => {
      element.value = 'tag1'
      
      const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true })
      element.dispatchEvent(event)
      
      const controller = application.getControllerForElementAndIdentifier(element, "tag-input")
      expect(controller.tags.filter(tag => tag === 'tag1').length).toBe(1)
    })

    it("ignores empty tags", () => {
      element.value = '  '
      
      const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true })
      element.dispatchEvent(event)
      
      const controller = application.getControllerForElementAndIdentifier(element, "tag-input")
      expect(controller.tags.length).toBe(2) // Only original tags
    })

    it("dispatches tag-added event", () => {
      const eventSpy = jest.fn()
      element.addEventListener('tag-added', eventSpy)
      
      element.value = 'newtag'
      const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true })
      element.dispatchEvent(event)
      
      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: { tag: 'newtag' }
        })
      )
    })
  })

  describe("removing tags", () => {
    it("removes tag when clicking remove button", () => {
      const removeButton = document.querySelector('[data-tag="tag1"]')
      removeButton.click()
      
      const controller = application.getControllerForElementAndIdentifier(element, "tag-input")
      expect(controller.tags).not.toContain('tag1')
      expect(controller.tags).toContain('tag2')
    })

    it("removes last tag on Backspace when input is empty", () => {
      element.value = ''
      
      const event = new KeyboardEvent('keydown', { key: 'Backspace', bubbles: true })
      element.dispatchEvent(event)
      
      const controller = application.getControllerForElementAndIdentifier(element, "tag-input")
      expect(controller.tags).toEqual(['tag1'])
    })

    it("dispatches tag-removed event", () => {
      const eventSpy = jest.fn()
      element.addEventListener('tag-removed', eventSpy)
      
      const removeButton = document.querySelector('[data-tag="tag1"]')
      removeButton.click()
      
      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          detail: { tag: 'tag1' }
        })
      )
    })
  })

  describe("updating input", () => {
    it("updates hidden input value when tags change", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "tag-input")
      
      element.value = 'tag3'
      const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true })
      element.dispatchEvent(event)
      
      const hiddenInput = document.querySelector('input[type="hidden"]')
      expect(hiddenInput.value).toBe('tag1, tag2, tag3')
    })

    it("renders tag elements with proper styling", () => {
      const tagElements = document.querySelectorAll('.tag-input-list span')
      
      tagElements.forEach(tag => {
        expect(tag.classList.contains('bg-indigo-100')).toBe(true)
        expect(tag.classList.contains('text-indigo-800')).toBe(true)
        expect(tag.querySelector('button')).toBeTruthy()
        expect(tag.querySelector('svg')).toBeTruthy()
      })
    })
  })

  describe("edge cases", () => {
    it("handles empty initial value", () => {
      element.value = ''
      const newController = new TagInputController()
      newController.element = element
      newController.connect()
      
      expect(newController.tags).toEqual([])
    })

    it("trims whitespace from tags", () => {
      element.value = '  spacetag  '
      
      const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true })
      element.dispatchEvent(event)
      
      const controller = application.getControllerForElementAndIdentifier(element, "tag-input")
      expect(controller.tags).toContain('spacetag')
    })

    it("prevents default on handled keys", () => {
      const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true, cancelable: true })
      const preventDefaultSpy = jest.spyOn(event, 'preventDefault')
      
      element.dispatchEvent(event)
      
      expect(preventDefaultSpy).toHaveBeenCalled()
    })
  })
})