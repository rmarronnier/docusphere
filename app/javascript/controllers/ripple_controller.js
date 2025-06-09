import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('click', this.createRipple.bind(this))
  }

  disconnect() {
    this.element.removeEventListener('click', this.createRipple.bind(this))
  }

  createRipple(event) {
    const button = event.currentTarget
    const ripple = document.createElement('span')
    const rect = button.getBoundingClientRect()
    const size = Math.max(rect.width, rect.height)
    const x = event.clientX - rect.left - size / 2
    const y = event.clientY - rect.top - size / 2

    ripple.style.width = ripple.style.height = size + 'px'
    ripple.style.left = x + 'px'
    ripple.style.top = y + 'px'
    ripple.classList.add('ripple-effect')

    button.style.position = 'relative'
    button.style.overflow = 'hidden'
    button.appendChild(ripple)

    ripple.addEventListener('animationend', () => {
      ripple.remove()
    })
  }
}

// Add this CSS to your application.css
const style = `
  .ripple-effect {
    position: absolute;
    border-radius: 50%;
    transform: scale(0);
    animation: ripple 0.6s ease-out;
    background-color: rgba(255, 255, 255, 0.5);
    pointer-events: none;
  }

  @keyframes ripple {
    to {
      transform: scale(4);
      opacity: 0;
    }
  }
`