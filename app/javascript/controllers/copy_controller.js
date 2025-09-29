import { Controller } from "@hotwired/stimulus";

export default class extends Controller {

  static values = { contentToCopy: String }

  copyToClipboard(event) {
    const textToCopy = this.contentToCopyValue
    const eventTarget = event.currentTarget
    const initialText = event.currentTarget.innerText
    navigator.clipboard.writeText(textToCopy)
    event.currentTarget.innerText = "Copié !"
    setTimeout(() => {
      eventTarget.innerText = initialText
    }, 2000)
  }
}

