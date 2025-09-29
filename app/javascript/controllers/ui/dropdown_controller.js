import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="ui--dropdown"
export default class extends Controller {
  static targets = ["list"];

  toggle() {
    this.listTarget.classList.toggle("hidden");
  }

  hide(event) {
    if (
      !this.element.contains(event.target) &&
      !this.listTarget.classList.contains("hidden")
    ) {
      this.listTarget.classList.add("hidden");
    }
  }
}
