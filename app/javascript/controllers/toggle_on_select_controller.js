import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle-on-select"
export default class extends Controller {
  static targets = [ "select", "toggleable" ]
  static values = { wanted: String }

  toggle(event) {
    this.selectTarget.value === this.wantedValue ? this.show() : this.hide();
  }

  hide() {
    if (!this.toggleableTarget.classList.contains("d-none")) {
      this.toggleableTarget.classList.add("d-none");
    }
  }

  show() {
    if (this.toggleableTarget.classList.contains("d-none")) {
      this.toggleableTarget.classList.remove("d-none");
    }
  }
}
