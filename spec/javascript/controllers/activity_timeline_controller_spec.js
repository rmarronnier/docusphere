import '../setup.js'  // TOUJOURS en premier
import { Application } from "@hotwired/stimulus"
import ActivityTimelineController from "../../../app/javascript/controllers/activity_timeline_controller"

// Mock Turbo
global.Turbo = {
  renderStreamMessage: global.createMockFunction()
}

describe("ActivityTimelineController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="activity-timeline" data-document-id="123">
        <nav>
          <button data-action="click->activity-timeline#filterActivities" 
                  data-activity-timeline-filter-param="all"
                  class="border-blue-500 text-blue-600">
            All <span>10</span>
          </button>
          <button data-action="click->activity-timeline#filterActivities" 
                  data-activity-timeline-filter-param="updates"
                  class="border-transparent text-gray-500">
            Updates <span>4</span>
          </button>
          <button data-action="click->activity-timeline#filterActivities" 
                  data-activity-timeline-filter-param="validations"
                  class="border-transparent text-gray-500">
            Validations <span>3</span>
          </button>
          <button data-action="click->activity-timeline#filterActivities" 
                  data-activity-timeline-filter-param="shares"
                  class="border-transparent text-gray-500">
            Shares <span>2</span>
          </button>
          <button data-action="click->activity-timeline#filterActivities" 
                  data-activity-timeline-filter-param="versions"
                  class="border-transparent text-gray-500">
            Versions <span>1</span>
          </button>
        </nav>
        
        <div data-activity-timeline-target="activityItem" data-activity-type="document_created">
          Document created
        </div>
        <div data-activity-timeline-target="activityItem" data-activity-type="document_updated">
          Document updated
          <button data-action="click->activity-timeline#toggleActions">Actions</button>
          <div data-activity-timeline-target="actionsMenu" class="hidden">Menu</div>
        </div>
        <div data-activity-timeline-target="activityItem" data-activity-type="validation_requested">
          Validation requested
        </div>
        <div data-activity-timeline-target="activityItem" data-activity-type="validation_approved">
          Validation approved
          <button data-action="click->activity-timeline#toggleActions">Actions</button>
          <div data-activity-timeline-target="actionsMenu" class="hidden">Menu</div>
        </div>
        <div data-activity-timeline-target="activityItem" data-activity-type="document_shared">
          Document shared
        </div>
        <div data-activity-timeline-target="activityItem" data-activity-type="version_created">
          Version created
        </div>
        
        <button data-action="click->activity-timeline#loadMore">
          Load more activity
          <svg class="ml-2 -mr-1 h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>
    `
    
    // Add CSRF token
    const csrfMeta = document.createElement('meta')
    csrfMeta.name = 'csrf-token'
    csrfMeta.content = 'test-csrf-token'
    document.head.appendChild(csrfMeta)
    
    application = Application.start()
    application.register("activity-timeline", ActivityTimelineController)
    
    element = document.querySelector('[data-controller="activity-timeline"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
    document.head.innerHTML = ""
    jest.clearAllMocks()
  })
  
  describe("#connect", () => {
    it("initializes with default values", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "activity-timeline")
      expect(controller.activeFilter).toBe('all')
      expect(controller.visibleCount).toBe(20)
    })
  })
  
  describe("#filterActivities", () => {
    it("filters activities by type", () => {
      const updatesButton = element.querySelector('[data-activity-timeline-filter-param="updates"]')
      updatesButton.click()
      
      const activities = element.querySelectorAll('[data-activity-timeline-target="activityItem"]')
      
      // Check visible activities
      expect(activities[0].classList.contains('hidden')).toBe(false) // document_created
      expect(activities[1].classList.contains('hidden')).toBe(false) // document_updated
      expect(activities[2].classList.contains('hidden')).toBe(true)  // validation_requested
      expect(activities[3].classList.contains('hidden')).toBe(true)  // validation_approved
      expect(activities[4].classList.contains('hidden')).toBe(true)  // document_shared
      expect(activities[5].classList.contains('hidden')).toBe(true)  // version_created
    })
    
    it("shows all activities when 'all' filter is selected", () => {
      // First filter by updates
      const updatesButton = element.querySelector('[data-activity-timeline-filter-param="updates"]')
      updatesButton.click()
      
      // Then show all
      const allButton = element.querySelector('[data-activity-timeline-filter-param="all"]')
      allButton.click()
      
      const activities = element.querySelectorAll('[data-activity-timeline-target="activityItem"]')
      activities.forEach(activity => {
        expect(activity.classList.contains('hidden')).toBe(false)
      })
    })
    
    it("updates button styles for active filter", () => {
      const validationsButton = element.querySelector('[data-activity-timeline-filter-param="validations"]')
      const allButton = element.querySelector('[data-activity-timeline-filter-param="all"]')
      
      validationsButton.click()
      
      // Active button styles
      expect(validationsButton.classList.contains('border-blue-500')).toBe(true)
      expect(validationsButton.classList.contains('text-blue-600')).toBe(true)
      expect(validationsButton.classList.contains('border-transparent')).toBe(false)
      expect(validationsButton.classList.contains('text-gray-500')).toBe(false)
      
      // Inactive button styles
      expect(allButton.classList.contains('border-blue-500')).toBe(false)
      expect(allButton.classList.contains('text-blue-600')).toBe(false)
      expect(allButton.classList.contains('border-transparent')).toBe(true)
      expect(allButton.classList.contains('text-gray-500')).toBe(true)
    })
    
    it("updates activeFilter property", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "activity-timeline")
      const sharesButton = element.querySelector('[data-activity-timeline-filter-param="shares"]')
      
      sharesButton.click()
      
      expect(controller.activeFilter).toBe('shares')
    })
    
    it("filters validation activities correctly", () => {
      const validationsButton = element.querySelector('[data-activity-timeline-filter-param="validations"]')
      validationsButton.click()
      
      const activities = element.querySelectorAll('[data-activity-timeline-target="activityItem"]')
      
      expect(activities[0].classList.contains('hidden')).toBe(true)  // document_created
      expect(activities[1].classList.contains('hidden')).toBe(true)  // document_updated
      expect(activities[2].classList.contains('hidden')).toBe(false) // validation_requested
      expect(activities[3].classList.contains('hidden')).toBe(false) // validation_approved
      expect(activities[4].classList.contains('hidden')).toBe(true)  // document_shared
      expect(activities[5].classList.contains('hidden')).toBe(true)  // version_created
    })
  })
  
  describe("#shouldShowActivity", () => {
    let controller
    
    beforeEach(() => {
      controller = application.getControllerForElementAndIdentifier(element, "activity-timeline")
    })
    
    it("returns true for 'all' filter", () => {
      expect(controller.shouldShowActivity('any_type', 'all')).toBe(true)
    })
    
    it("filters updates correctly", () => {
      expect(controller.shouldShowActivity('document_updated', 'updates')).toBe(true)
      expect(controller.shouldShowActivity('document_created', 'updates')).toBe(true)
      expect(controller.shouldShowActivity('validation_requested', 'updates')).toBe(false)
    })
    
    it("filters validations correctly", () => {
      expect(controller.shouldShowActivity('validation_requested', 'validations')).toBe(true)
      expect(controller.shouldShowActivity('validation_approved', 'validations')).toBe(true)
      expect(controller.shouldShowActivity('validation_rejected', 'validations')).toBe(true)
      expect(controller.shouldShowActivity('validation_validated', 'validations')).toBe(true)
      expect(controller.shouldShowActivity('document_updated', 'validations')).toBe(false)
    })
    
    it("filters shares correctly", () => {
      expect(controller.shouldShowActivity('document_shared', 'shares')).toBe(true)
      expect(controller.shouldShowActivity('document_updated', 'shares')).toBe(false)
    })
    
    it("filters versions correctly", () => {
      expect(controller.shouldShowActivity('version_created', 'versions')).toBe(true)
      expect(controller.shouldShowActivity('document_updated', 'versions')).toBe(false)
    })
    
    it("returns false for unknown filter types", () => {
      expect(controller.shouldShowActivity('document_updated', 'unknown')).toBe(false)
    })
  })
  
  describe("#updateFilterCounts", () => {
    it("updates count badges after filtering", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "activity-timeline")
      
      // Filter to show only updates
      const updatesButton = element.querySelector('[data-activity-timeline-filter-param="updates"]')
      updatesButton.click()
      
      controller.updateFilterCounts()
      
      // Check that counts are updated (only visible items counted)
      const allBadge = element.querySelector('[data-activity-timeline-filter-param="all"] span')
      const updatesBadge = element.querySelector('[data-activity-timeline-filter-param="updates"] span')
      
      expect(allBadge.textContent).toBe('2') // Only 2 visible
      expect(updatesBadge.textContent).toBe('2')
    })
  })
  
  describe("#toggleActions", () => {
    it("toggles action menu visibility", () => {
      const actionButton = element.querySelector('[data-action*="toggleActions"]')
      const menu = actionButton.nextElementSibling
      
      expect(menu.classList.contains('hidden')).toBe(true)
      
      actionButton.click()
      expect(menu.classList.contains('hidden')).toBe(false)
      
      actionButton.click()
      expect(menu.classList.contains('hidden')).toBe(true)
    })
    
    it("closes other menus when opening a new one", () => {
      const buttons = element.querySelectorAll('[data-action*="toggleActions"]')
      const menu1 = buttons[0].nextElementSibling
      const menu2 = buttons[1].nextElementSibling
      
      // Open first menu
      buttons[0].click()
      expect(menu1.classList.contains('hidden')).toBe(false)
      expect(menu2.classList.contains('hidden')).toBe(true)
      
      // Open second menu - first should close
      buttons[1].click()
      expect(menu1.classList.contains('hidden')).toBe(true)
      expect(menu2.classList.contains('hidden')).toBe(false)
    })
    
    it("stops event propagation", () => {
      const actionButton = element.querySelector('[data-action*="toggleActions"]')
      let propagated = false
      
      element.addEventListener('click', () => {
        propagated = true
      })
      
      const event = new MouseEvent('click', { bubbles: true })
      const stopPropagationSpy = jest.spyOn(event, 'stopPropagation')
      
      actionButton.dispatchEvent(event)
      
      expect(stopPropagationSpy).toHaveBeenCalled()
    })
    
    it("adds click outside listener when opening menu", (done) => {
      const actionButton = element.querySelector('[data-action*="toggleActions"]')
      const menu = actionButton.nextElementSibling
      
      actionButton.click()
      expect(menu.classList.contains('hidden')).toBe(false)
      
      // Click outside should close menu
      setTimeout(() => {
        document.body.click()
        expect(menu.classList.contains('hidden')).toBe(true)
        done()
      }, 10)
    })
  })
  
  describe("#closeMenus", () => {
    it("closes all action menus", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "activity-timeline")
      const buttons = element.querySelectorAll('[data-action*="toggleActions"]')
      
      // Open all menus
      buttons.forEach(button => {
        button.click()
      })
      
      // Verify menus are open
      const menus = element.querySelectorAll('[data-activity-timeline-target="actionsMenu"]')
      menus.forEach(menu => {
        expect(menu.classList.contains('hidden')).toBe(false)
      })
      
      // Close all menus
      controller.closeMenus()
      
      // Verify all menus are closed
      menus.forEach(menu => {
        expect(menu.classList.contains('hidden')).toBe(true)
      })
    })
  })
  
  describe("#loadMore", () => {
    beforeEach(() => {
      global.fetch = jest.fn().mockResolvedValue({
        text: jest.fn().mockResolvedValue('<turbo-stream>test</turbo-stream>')
      })
    })
    
    afterEach(() => {
      delete global.fetch
    })
    
    it("disables button while loading", () => {
      const loadMoreButton = element.querySelector('[data-action*="loadMore"]')
      
      loadMoreButton.click()
      
      expect(loadMoreButton.disabled).toBe(true)
      expect(loadMoreButton.innerHTML).toContain('animate-spin')
      expect(loadMoreButton.innerHTML).toContain('Loading...')
    })
    
    it("fetches more activities with correct parameters", () => {
      const loadMoreButton = element.querySelector('[data-action*="loadMore"]')
      const activityCount = element.querySelectorAll('[data-activity-timeline-target="activityItem"]').length
      
      loadMoreButton.click()
      
      expect(global.fetch).toHaveBeenCalledWith(
        `/ged/documents/123/activities?offset=${activityCount}&limit=20`,
        expect.objectContaining({
          headers: expect.objectContaining({
            'Accept': 'text/vnd.turbo-stream.html',
            'X-CSRF-Token': 'test-csrf-token'
          })
        })
      )
    })
    
    it("renders Turbo Stream response", async () => {
      const loadMoreButton = element.querySelector('[data-action*="loadMore"]')
      
      loadMoreButton.click()
      
      await new Promise(resolve => setTimeout(resolve, 0))
      
      expect(global.Turbo.renderStreamMessage).toHaveBeenCalledWith('<turbo-stream>test</turbo-stream>')
    })
    
    it("re-enables button after successful load", async () => {
      const loadMoreButton = element.querySelector('[data-action*="loadMore"]')
      
      loadMoreButton.click()
      
      await new Promise(resolve => setTimeout(resolve, 0))
      
      expect(loadMoreButton.disabled).toBe(false)
      expect(loadMoreButton.innerHTML).toContain('Load more activity')
      expect(loadMoreButton.innerHTML).toContain('<svg')
    })
    
    it("handles errors gracefully", async () => {
      global.fetch = jest.fn().mockRejectedValue(new Error('Network error'))
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation()
      const loadMoreButton = element.querySelector('[data-action*="loadMore"]')
      
      loadMoreButton.click()
      
      await new Promise(resolve => setTimeout(resolve, 0))
      
      expect(consoleSpy).toHaveBeenCalledWith('Error loading activities:', expect.any(Error))
      expect(loadMoreButton.disabled).toBe(false)
      expect(loadMoreButton.textContent).toBe('Error loading activities. Try again.')
      
      consoleSpy.mockRestore()
    })
  })
  
  describe("#disconnect", () => {
    it("closes all menus on disconnect", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "activity-timeline")
      const buttons = element.querySelectorAll('[data-action*="toggleActions"]')
      
      // Open some menus
      buttons.forEach(button => button.click())
      
      controller.disconnect()
      
      const menus = element.querySelectorAll('[data-activity-timeline-target="actionsMenu"]')
      menus.forEach(menu => {
        expect(menu.classList.contains('hidden')).toBe(true)
      })
    })
  })
  
  describe("integration tests", () => {
    it("maintains filter state across multiple operations", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "activity-timeline")
      const validationsButton = element.querySelector('[data-activity-timeline-filter-param="validations"]')
      
      // Apply filter
      validationsButton.click()
      expect(controller.activeFilter).toBe('validations')
      
      // Open an action menu
      const actionButton = element.querySelector('[data-activity-type="validation_approved"] [data-action*="toggleActions"]')
      actionButton.click()
      
      // Filter should remain active
      expect(controller.activeFilter).toBe('validations')
      
      // Close menu by clicking outside
      document.body.click()
      
      // Filter should still be active
      expect(controller.activeFilter).toBe('validations')
    })
    
    it("updates counts correctly when switching filters", () => {
      // Start with all
      const allButton = element.querySelector('[data-activity-timeline-filter-param="all"]')
      allButton.click()
      
      // Switch to updates
      const updatesButton = element.querySelector('[data-activity-timeline-filter-param="updates"]')
      updatesButton.click()
      
      // Switch to validations
      const validationsButton = element.querySelector('[data-activity-timeline-filter-param="validations"]')
      validationsButton.click()
      
      // Check that only validation items are visible
      const visibleItems = element.querySelectorAll('[data-activity-timeline-target="activityItem"]:not(.hidden)')
      visibleItems.forEach(item => {
        expect(item.dataset.activityType).toMatch(/validation/)
      })
    })
  })
})