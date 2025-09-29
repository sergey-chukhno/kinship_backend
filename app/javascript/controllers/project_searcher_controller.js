import { Controller } from "@hotwired/stimulus"
import "tomselect"

// Connects to data-controller="project-searcher"
export default class extends Controller {
  static targets = ["projectInput"]

  connect() {
    if (this.hasProjectInputTarget) { this.createTomSelectProjectInput(); }
  }

  disconnect() {
    if (this.hasProjectInputTarget) { this.projectInputTomSelect.destroy(); }
  }

  createTomSelectProjectInput() {
    this.projectInputTomSelect = new TomSelect(this.projectInputTarget, {
      maxOptions: 20,
      allowEmptyOption: true,
      onType: () => {
        this.projectInputTomSelect.control_input.parentNode.getElementsByClassName("item")[0].classList.add("d-none");
      },
      onChange: () => {
        this.projectInputTomSelect.blur();
        this.refreshFilters(this.projectInputTarget.value)
      },
    })
  }

  refreshFilters(value) {
    let frame = document.querySelector('turbo-frame#filters')
    frame.src = `${window.location.pathname}?filters[project]=${value}`
    frame.reload()
  }
}
