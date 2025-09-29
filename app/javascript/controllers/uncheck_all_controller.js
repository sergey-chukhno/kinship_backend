import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="uncheck-all"
export default class extends Controller {
  static targets = ["checkbox"]


  uncheckAll(event) {
    if (event.target.value == "Oui") { return }

    this.checkboxTargets.forEach((checkbox) => {
      if (checkbox != event.target) {
        checkbox.checked = false;
      }
    });
  }
}
