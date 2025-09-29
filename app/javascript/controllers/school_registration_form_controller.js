import { Controller } from "@hotwired/stimulus"
import "tomselect"



// Used in  : 
// Registration Stepper + Edit Profil 

// Connects to data-controller="school-registration-form"
export default class extends Controller {
  static targets = ["schoolInput", "schoolLevelInput", "schoolIds", "customSchoolLevelInput"]

  connect() {
    this.baseUrl = window.location.origin
    this.apiEndPointWithParamsName = `/api/v1/schools?name=`
    if (this.hasSchoolInputTarget) {this.createTomSelectSchoolInput();}
    if (this.hasSchoolLevelInputTarget) {this.createTomSelectSchoolLevelInput();}
    if (this.hasCustomSchoolLevelInputTarget) { this.changeCustomSchoolLevelInputIds(this.customSchoolLevelInputTargets); }
  }

  disconnect() {
    if (this.hasSchoolInputTarget) {this.schoolInputTomSelect.destroy();}
    if (this.hasSchoolLevelInputTarget) {this.schoolLevelInputTomSelect.destroy();}
  }

  createTomSelectSchoolInput() {
    this.schoolInputTomSelect = new TomSelect(this.schoolInputTarget, {
      maxOptions: 20,
      load: (value, callback) => {
        this.fetchSchools(callback);
      },
      onChange: (value) => {
        this.schoolInputTomSelect.blur();
        this.fetchSchoolLevelsofCurrentSchool(value);
        this.changeSchoolIds(value);
      },
    });
  }

  createTomSelectSchoolLevelInput() {
    this.schoolLevelInputTomSelect = new TomSelect(this.schoolLevelInputTarget, {
      plugins: ['remove_button'],
      maxOptions: 20,
    })
    this.schoolLevelInputTomSelect.disable();
  }

  fetchSchools(callback) {
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
        callback(this.refreshSchoolOptions(data));
      });
  }

  refreshSchoolOptions(data) {
    const options = data.map(school => {
      return new Option(school.full_name, school.id, false, false)
    })
    return options;
  }

  fetchSchoolLevelsofCurrentSchool(school_id) {
    if (school_id === "") { return this.schoolLevelInputTomSelect.disable() }

    if (this.hasSchoolLevelInputTarget) {
      fetch(`${this.baseUrl}/school_levels?school_id=${school_id}`,
        {
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
          },
          method: "GET",
        }
      )
      .then((response) => response.json())
      .then((data) => {
        this.refreshSchoolLevelOptions(data);
      })
    }
  }

  refreshSchoolLevelOptions(data) {
    const options = data.map(school_level => {
      return new Option(school_level.full_name_without_school, school_level.id, false, false)
    })
    this.schoolLevelInputTomSelect.clear();
    this.schoolLevelInputTomSelect.clearOptions();
    this.schoolLevelInputTomSelect.addOptions(options);
    this.schoolLevelInputTomSelect.refreshOptions(false);
    options.length > 0 ? this.schoolLevelInputTomSelect.enable() : this.schoolLevelInputTomSelect.disable();
  }

  changeSchoolIds(value) {
    if (!this.hasSchoolIdsTarget) { return }

    this.schoolIdsTargets.forEach((schoolId) => {
      schoolId.value = value;
    })
  }

  changeCustomSchoolLevelInputIds(inputs) {
    const index =  new Date().getTime()

    inputs.forEach((input) => {
      input.name = input.name.replace("NEW_RECORD", index);
    })
  }
}
