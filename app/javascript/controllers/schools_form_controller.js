import { Controller } from "@hotwired/stimulus"
import "tomselect";

// Connects to data-controller="schools-form"
// Targets: data-schools-form-target="targetName"
// Actions: data-action="schools-form#action"

// Used in :
// Account/schools. 
// TODO : can be deleted because it will be replaced by "school_registration_form"

export default class extends Controller {
  static targets = ["schoolInput", "schoolLevelInput", "requestSchoolLevelCreationInputSchoolId"]

  connect() {
    this.baseUrl = window.location.origin
    this.apiEndPointWithParamsName = `/api/v1/schools?name=`
    if (this.hasSchoolInputTarget) { this._createTomSelectSchoolInput(); }
  }

  _createTomSelectSchoolInput() {
    this.schoolInputTomSelect = new TomSelect(this.schoolInputTarget, {
      maxOptions: 20,
      load: (value, callback) => {
        this._fetchSchools(callback)
      },
      onType: () => {
        if ( this.schoolInputTomSelect.control_input.parentNode.getElementsByClassName("item").length > 0) {
          this.schoolInputTomSelect.control_input.parentNode.getElementsByClassName("item")[0].classList.add("hidden");
        }
      },
      onChange: (value) => {
        this.schoolInputTomSelect.blur()
        this._fetchSchoolLevels(value)
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

  _fetchSchools(callback = null) {
    fetch(`${this.baseUrl}${this.apiEndPointWithParamsName}${this.schoolInputTomSelect.lastValue}`,
      {
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json"
        },
        method: "GET",
      })
      .then(response => response.json())
      .then((data) => {
        callback(this._generateSchoolOptions(data));
      });
  }

  _generateSchoolOptions(data) {
    const options = data.map(school => {
      return new Option(school.full_name, school.id, false, false)
    })
    return options;
  }

  _fetchSchoolLevels(school_id) {
    fetch(`${this.baseUrl}/school_levels?school_id=${school_id}`,
      {
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json"
        },
        method: "GET",
      })
      .then(response => response.json())
      .then((data) => {
        this._generateSchoolLevelOptions(data);
      });
  }

  _generateSchoolLevelOptions(data) {
    const options = data.map(school_level => {
      return new Option(school_level.full_name_without_school, school_level.id, false, false)
    })
    this.schoolLevelInputTarget.tomselect.clear();
    this.schoolLevelInputTarget.tomselect.clearOptions();
    this.schoolLevelInputTarget.tomselect.addOptions(options);
    this.schoolLevelInputTarget.tomselect.refreshOptions(false);
  }

  updateSchoolIdValueOfCustomSchoolLevel() {
    this.requestSchoolLevelCreationInputSchoolIdTarget.value = this.schoolInputTarget.value;
  }
}
