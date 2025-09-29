import { Controller } from "@hotwired/stimulus"
import "tomselect"

// Connects to data-controller="companies-select-search"
export default class extends Controller {
  static targets = ["companyInput"];

  connect() {
    this.baseUrl = window.location.origin
    this.apiEndPointWithParamsFullName = `/api/v1/companies?full_name=`
    if (this.hasCompanyInputTarget) { this.createTomSelectCompanyInput(); }
  }

  disconnect() {
    if (this.hasCompanyInputTarget) { this.companyInputTomSelect.destroy(); }
  }

  createTomSelectCompanyInput() {
    this.companyInputTomSelect = new TomSelect(this.companyInputTarget, {
      maxOptions: 20,
      load: (value, callback) => {
        this.fetchCompanies(callback, value)
      },
      onType: () => {
        if ( this.companyInputTomSelect.control_input.parentNode.getElementsByClassName("item").length > 0) {
          this.companyInputTomSelect.control_input.parentNode.getElementsByClassName("item")[0].classList.add("hidden");
        }
      },
      onChange: (value) => {
        this.companyInputTomSelect.blur()
      },
      render: {
        no_results: function (data, escape) {
          return (
            '<div class="no-results">Pas de résultat pour "' +
            escape(data.input) +
            '"</div>'
          );
        }
      }
    })
  }

  fetchCompanies(callback, value) { 
    fetch(`${this.baseUrl}${this.apiEndPointWithParamsFullName}${value}`,
      {
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json"
        },
        method: "GET",
      })
      .then(response => response.json())
      .then((data) => {
        callback(this.generateCompanyOptions(data));
      });
  }

  generateCompanyOptions(data) {
    const options = data.map(company => {
      return new Option(company.full_name, company.id, false, false)
    })
    return options
  }
}
