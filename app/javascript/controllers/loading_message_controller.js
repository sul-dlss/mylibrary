import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ 'clickableElement', 'initialMessage', 'loadingMessage' ]

  show() {
    this.clickableElementTarget.classList.add('disabled')
    this.initialMessageTarget.classList.add('d-none')
    this.loadingMessageTarget.classList.remove('d-none')
  }

  disconnect() {
    this.clickableElementTarget.classList.remove('disabled')
    this.initialMessageTarget.classList.remove('d-none')
    this.loadingMessageTarget.classList.add('d-none')
  }
}
