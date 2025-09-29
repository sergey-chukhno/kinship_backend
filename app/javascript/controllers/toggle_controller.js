import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = [
                    "element",
                    "drop_down_arrow",
                    "more_filter"
                  ]

  show() {
    this.elementTarget.classList.remove("d-none")
  }

  hide() {
    this.elementTarget.classList.add("d-none")
  }

  toggle_more_filter(event) {
    const actual_display = window.getComputedStyle(this.more_filterTarget).getPropertyValue("display");
    if (actual_display == "none") {
      this.more_filterTarget.style.display = "flex"
      event.target.innerText = "- de filtres"
    } else{
      this.more_filterTarget.style.display = "none"
      event.target.innerText = "+ de filtres"
    }
  }

  toggle() {
    this.elementTarget.classList.toggle("d-none")

    if (this.elementTarget.classList.contains("d-none")) {
      this.clear_inputs()
    }

    if (this.hasDrop_down_arrowTarget) {
      this.turn_arrow_up_and_down()
    }
  }

  turn_arrow_up_and_down() {
    this.drop_down_arrowTarget.classList.toggle("active")
  }

  clear_inputs() {
    this.elementTargets.forEach(target => {
      target.value = ""
    });
  }

  toggle_if_other_selected(event) {
    if (event.target.value == "autres") {
      this.show()
    } else {
      this.hide()
      this.clear_inputs()
    }
  }
}
