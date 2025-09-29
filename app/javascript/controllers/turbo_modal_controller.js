import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="turbo-modal"
export default class extends Controller {
  static targets = ["modal"]

  hideModal() {
    this.element.parentElement.removeAttribute("src") // it might be nice to also remove the modal SRC
    this.element.remove()
  }

  closeWithKeyboard(event) {
    if (event.code == "Escape") {
      this.hideModal()
    }
  }

  closeBackground(event) {
    if (event && this.modalTarget.contains(event.target)) {
      return
    }
    this.hideModal()
  }

  submitEnd(event) {
    if (event.detail.success) {
      this.hideModal()
    }
  }
}
