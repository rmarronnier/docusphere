import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["newProjectModal", "mobileMenu"]
  
  connect() {
    console.log("Immo Promo Navbar controller connected")
  }
  
  openNewProjectModal() {
    this.newProjectModalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }
  
  closeNewProjectModal() {
    this.newProjectModalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }
  
  toggleMobileMenu() {
    this.mobileMenuTarget.classList.toggle("hidden")
  }
}