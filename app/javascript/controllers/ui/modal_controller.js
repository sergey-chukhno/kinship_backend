import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="ui--modal"
export default class extends Controller {
  static targets = ["content"];

  open() {
    this.element.classList.add("open");
  }

  close(event) {
    if (
      !this.contentTarget.contains(event.target) &&
      this.element.classList.contains("open") &&
      !event.target.classList.contains("dz-hidden-input")
    ) {
      this.element.classList.remove("open");
    }
  }

  closeBtn(event) {
    this.element.classList.remove("open");
  }
}
