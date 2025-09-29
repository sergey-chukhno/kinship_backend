import { Controller } from "@hotwired/stimulus";
import "tomselect";

// Connects to data-controller="company-searcher"
export default class extends Controller {
  static targets = ["companyInput"];

  connect() {
    if (this.hasCompanyInputTarget) {
      this.createTomSelectCompanyInput();
    }
  }

  disconnect() {
    if (this.hasCompanyInputTarget) {
      this.companyInputTomSelect.destroy();
    }
  }

  createTomSelectCompanyInput() {
    this.companyInputTomSelect = new TomSelect(this.companyInputTarget, {
      maxOptions: 20,
      allowEmptyOption: true,
      onType: () => {
        this.companyInputTomSelect.control_input.parentNode
          .getElementsByClassName("item")[0]
          .classList.add("d-none");
      },
      onChange: () => {
        this.companyInputTomSelect.blur();
        this.refreshFilters(this.companyInputTarget.value);
      },
    });
  }

  refreshFilters(value) {
    let frame = document.querySelector("turbo-frame#filters");
    if (!frame) return;

    frame.src = `${window.location.pathname}?filters[company]=${value}`;
    frame?.reload();
  }
}
