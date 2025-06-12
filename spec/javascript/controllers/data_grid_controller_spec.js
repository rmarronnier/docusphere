import { Application } from "@hotwired/stimulus"
import DataGridController from "../../../app/javascript/controllers/data_grid_controller"

describe("DataGridController", () => {
  let application
  let element
  
  beforeEach(() => {
    document.body.innerHTML = `
      <div data-controller="data-grid" 
           data-data-grid-selected-value="[]"
           data-data-grid-sort-key-value=""
           data-data-grid-sort-direction-value="asc">
        <table>
          <thead>
            <tr>
              <th>
                <input type="checkbox" data-action="change->data-grid#toggleAll" />
              </th>
              <th data-sortable data-sort-key="name" data-action="click->data-grid#sort">
                Name
                <svg class="text-gray-400">
                  <path d="M5 12l5-5 5 5"/>
                </svg>
              </th>
              <th data-sortable data-sort-key="date" data-action="click->data-grid#sort">
                Date
                <svg class="text-gray-400">
                  <path d="M5 12l5-5 5 5"/>
                </svg>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr data-data-grid-target="row" data-row-id="1" data-action="click->data-grid#rowClick">
              <td><input type="checkbox" value="1" data-action="change->data-grid#toggleRow" /></td>
              <td>Document 1</td>
              <td>2024-01-01</td>
            </tr>
            <tr data-data-grid-target="row" data-row-id="2" data-action="click->data-grid#rowClick">
              <td><input type="checkbox" value="2" data-action="change->data-grid#toggleRow" /></td>
              <td>Document 2</td>
              <td>2024-01-02</td>
            </tr>
            <tr data-data-grid-target="row" data-row-id="3" data-action="click->data-grid#rowClick">
              <td><input type="checkbox" value="3" data-action="change->data-grid#toggleRow" /></td>
              <td>Document 3</td>
              <td>2024-01-03</td>
            </tr>
          </tbody>
        </table>
        <button data-action="click->data-grid#exportSelected">Export Selected</button>
        <button data-action="click->data-grid#clearSelection">Clear Selection</button>
      </div>
    `
    
    application = Application.start()
    application.register("data-grid", DataGridController)
    
    element = document.querySelector('[data-controller="data-grid"]')
  })
  
  afterEach(() => {
    application.stop()
    document.body.innerHTML = ""
  })
  
  describe("#connect", () => {
    it("initializes with empty selected array if not provided", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      expect(controller.selectedValue).toEqual([])
    })
  })
  
  describe("#toggleAll", () => {
    it("selects all checkboxes when select all is checked", () => {
      const selectAll = element.querySelector('thead input[type="checkbox"]')
      const checkboxes = element.querySelectorAll('tbody input[type="checkbox"]')
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      
      selectAll.checked = true
      selectAll.dispatchEvent(new Event('change'))
      
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(true)
      })
      
      expect(controller.selectedValue).toEqual(["1", "2", "3"])
    })
    
    it("deselects all checkboxes when select all is unchecked", () => {
      const selectAll = element.querySelector('thead input[type="checkbox"]')
      const checkboxes = element.querySelectorAll('tbody input[type="checkbox"]')
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      
      // First select all
      selectAll.checked = true
      selectAll.dispatchEvent(new Event('change'))
      
      // Then deselect all
      selectAll.checked = false
      selectAll.dispatchEvent(new Event('change'))
      
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(false)
      })
      
      expect(controller.selectedValue).toEqual([])
    })
    
    it("dispatches selection-changed event", () => {
      const selectAll = element.querySelector('thead input[type="checkbox"]')
      let eventDetail = null
      
      element.addEventListener('data-grid:selection-changed', (event) => {
        eventDetail = event.detail
      })
      
      selectAll.checked = true
      selectAll.dispatchEvent(new Event('change'))
      
      expect(eventDetail).toEqual({ selected: ["1", "2", "3"] })
    })
  })
  
  describe("#toggleRow", () => {
    it("adds row ID to selected when checkbox is checked", () => {
      const checkbox = element.querySelector('tbody input[value="2"]')
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      
      checkbox.checked = true
      checkbox.dispatchEvent(new Event('change'))
      
      expect(controller.selectedValue).toEqual(["2"])
    })
    
    it("removes row ID from selected when checkbox is unchecked", () => {
      const checkbox = element.querySelector('tbody input[value="2"]')
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      
      // First check it
      checkbox.checked = true
      checkbox.dispatchEvent(new Event('change'))
      expect(controller.selectedValue).toEqual(["2"])
      
      // Then uncheck it
      checkbox.checked = false
      checkbox.dispatchEvent(new Event('change'))
      expect(controller.selectedValue).toEqual([])
    })
    
    it("updates select all checkbox state", () => {
      const selectAll = element.querySelector('thead input[type="checkbox"]')
      const checkboxes = element.querySelectorAll('tbody input[type="checkbox"]')
      
      // Select all individual checkboxes
      checkboxes.forEach(checkbox => {
        checkbox.checked = true
        checkbox.dispatchEvent(new Event('change'))
      })
      
      expect(selectAll.checked).toBe(true)
      expect(selectAll.indeterminate).toBe(false)
    })
    
    it("sets select all to indeterminate when some are selected", () => {
      const selectAll = element.querySelector('thead input[type="checkbox"]')
      const firstCheckbox = element.querySelector('tbody input[value="1"]')
      
      firstCheckbox.checked = true
      firstCheckbox.dispatchEvent(new Event('change'))
      
      expect(selectAll.checked).toBe(false)
      expect(selectAll.indeterminate).toBe(true)
    })
  })
  
  describe("#sort", () => {
    it("sets sort key and direction on first click", () => {
      const nameHeader = element.querySelector('th[data-sort-key="name"]')
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      
      nameHeader.click()
      
      expect(controller.sortKeyValue).toBe("name")
      expect(controller.sortDirectionValue).toBe("asc")
    })
    
    it("toggles sort direction on second click", () => {
      const nameHeader = element.querySelector('th[data-sort-key="name"]')
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      
      nameHeader.click()
      expect(controller.sortDirectionValue).toBe("asc")
      
      nameHeader.click()
      expect(controller.sortDirectionValue).toBe("desc")
      
      nameHeader.click()
      expect(controller.sortDirectionValue).toBe("asc")
    })
    
    it("changes sort key when clicking different header", () => {
      const nameHeader = element.querySelector('th[data-sort-key="name"]')
      const dateHeader = element.querySelector('th[data-sort-key="date"]')
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      
      nameHeader.click()
      expect(controller.sortKeyValue).toBe("name")
      
      dateHeader.click()
      expect(controller.sortKeyValue).toBe("date")
      expect(controller.sortDirectionValue).toBe("asc")
    })
    
    it("updates visual indicators", () => {
      const nameHeader = element.querySelector('th[data-sort-key="name"]')
      const nameIcon = nameHeader.querySelector('svg')
      
      nameHeader.click()
      
      expect(nameIcon.classList.contains('text-gray-900')).toBe(true)
      expect(nameIcon.classList.contains('text-gray-400')).toBe(false)
    })
    
    it("rotates icon for descending sort", () => {
      const nameHeader = element.querySelector('th[data-sort-key="name"]')
      const nameIcon = nameHeader.querySelector('svg')
      
      nameHeader.click() // asc
      nameHeader.click() // desc
      
      expect(nameIcon.classList.contains('transform')).toBe(true)
      expect(nameIcon.classList.contains('rotate-180')).toBe(true)
    })
    
    it("dispatches sort event", () => {
      const nameHeader = element.querySelector('th[data-sort-key="name"]')
      let eventDetail = null
      
      element.addEventListener('data-grid:sort', (event) => {
        eventDetail = event.detail
      })
      
      nameHeader.click()
      
      expect(eventDetail).toEqual({ key: "name", direction: "asc" })
    })
    
    it("ignores click on header without sort key", () => {
      const header = document.createElement('th')
      header.setAttribute('data-sortable', '')
      element.querySelector('thead tr').appendChild(header)
      
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      const initialSortKey = controller.sortKeyValue
      
      header.click()
      
      expect(controller.sortKeyValue).toBe(initialSortKey)
    })
  })
  
  describe("#rowClick", () => {
    it("dispatches row-click event with row data", () => {
      const row = element.querySelector('tr[data-row-id="2"]')
      let eventDetail = null
      
      element.addEventListener('data-grid:row-click', (event) => {
        eventDetail = event.detail
      })
      
      row.click()
      
      expect(eventDetail.id).toBe("2")
      expect(eventDetail.row).toBe(row)
    })
    
    it("ignores clicks on interactive elements", () => {
      const checkbox = element.querySelector('tbody input[value="1"]')
      let eventFired = false
      
      element.addEventListener('data-grid:row-click', () => {
        eventFired = true
      })
      
      checkbox.click()
      
      expect(eventFired).toBe(false)
    })
    
    it("ignores clicks on buttons", () => {
      const row = element.querySelector('tr[data-row-id="1"]')
      const button = document.createElement('button')
      button.textContent = 'Action'
      row.querySelector('td').appendChild(button)
      
      let eventFired = false
      
      element.addEventListener('data-grid:row-click', () => {
        eventFired = true
      })
      
      button.click()
      
      expect(eventFired).toBe(false)
    })
    
    it("ignores clicks on links", () => {
      const row = element.querySelector('tr[data-row-id="1"]')
      const link = document.createElement('a')
      link.href = '#'
      link.textContent = 'Link'
      row.querySelector('td').appendChild(link)
      
      let eventFired = false
      
      element.addEventListener('data-grid:row-click', () => {
        eventFired = true
      })
      
      link.click()
      
      expect(eventFired).toBe(false)
    })
  })
  
  describe("#exportSelected", () => {
    it("dispatches export event with selected IDs", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      const exportButton = element.querySelector('button[data-action*="exportSelected"]')
      let eventDetail = null
      
      // Select some items
      controller.selectedValue = ["1", "3"]
      
      element.addEventListener('data-grid:export', (event) => {
        eventDetail = event.detail
      })
      
      exportButton.click()
      
      expect(eventDetail).toEqual({ selected: ["1", "3"] })
    })
  })
  
  describe("#clearSelection", () => {
    it("clears all selections", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      const clearButton = element.querySelector('button[data-action*="clearSelection"]')
      const checkboxes = element.querySelectorAll('input[type="checkbox"]')
      
      // Select some items first
      checkboxes[1].checked = true
      checkboxes[1].dispatchEvent(new Event('change'))
      checkboxes[2].checked = true
      checkboxes[2].dispatchEvent(new Event('change'))
      
      expect(controller.selectedValue.length).toBeGreaterThan(0)
      
      clearButton.click()
      
      expect(controller.selectedValue).toEqual([])
      checkboxes.forEach(checkbox => {
        expect(checkbox.checked).toBe(false)
      })
    })
    
    it("dispatches selection-changed event with empty selection", () => {
      const clearButton = element.querySelector('button[data-action*="clearSelection"]')
      let eventDetail = null
      
      element.addEventListener('data-grid:selection-changed', (event) => {
        eventDetail = event.detail
      })
      
      clearButton.click()
      
      expect(eventDetail).toEqual({ selected: [] })
    })
  })
  
  describe("integration tests", () => {
    it("maintains selection state across sort operations", () => {
      const controller = application.getControllerForElementAndIdentifier(element, "data-grid")
      const checkbox = element.querySelector('tbody input[value="2"]')
      const nameHeader = element.querySelector('th[data-sort-key="name"]')
      
      // Select an item
      checkbox.checked = true
      checkbox.dispatchEvent(new Event('change'))
      
      // Sort the table
      nameHeader.click()
      
      // Selection should be maintained
      expect(controller.selectedValue).toEqual(["2"])
    })
  })
})