import { Controller } from "@hotwired/stimulus"
import "tomselect";

export default class extends Controller {
  static targets = ["schoolType", "zipCode", "schoolList", "schoolLevelInput", "schoolLevelLevelInput"]


// Used in : 
// Registration Stepper Pupil uniquement.
// can be deleted because it will be replaced by "school_registration_form"

  connect() {
    setTimeout(() => {
      this.baseUrl = window.location.origin
      if (this.hasSchoolLevelInputTarget) { this._create_tom_select_school_level_input() }
      if (this.hasSchoolListTarget) { this._create_tom_select_school_input() }
      if (this.hasSchoolTypeTarget) { this._create_tom_select_school_type_input() }
      if (this.hasSchoolLevelLevelInputTarget) { this._createTomSelectSchoolLevelLevelInput() }
      this.setSchoolLevelLevelsCollection()
      if (this.hasSchoolLevelInputTarget) {
        if (this.schoolLevelInputTomSelect.getValue() == "") {
          this.fetchSchoolLevels()
          this._add_school_level_input_placeholder()
        }
      }
    }, 1);
  }

  disconnect() {
    this.schoolInputTomSelect.destroy()
    this.schoolTypeInputTomSelect.destroy()
    this.schoolLevelInputTomSelect.destroy()
  }

  fetchSchools(callback = {}) {
    this._clearSchoolInput()

    fetch(`${this.baseUrl}/schools?zip_code=${this.zipCodeTarget.value}&school_type=${this.schoolTypeTarget.value}&name=${this.schoolInputTomSelect.lastValue}`, { headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' } })
      .then(response => response.json())
      .then(data => {
        if (typeof callback != "function") {
          const options = this._generateSchoolOptions(data)
          this.schoolInputTomSelect.addOption(options);
        } else {
          callback(this._generateSchoolOptions(data))
        }
        this.schoolInputTomSelect.refreshOptions(false);
        this.schoolInputTomSelect.open()
      })

    if (this.schoolLevelInputTomSelect != undefined && this.hasSchoolLevelInputTarget) {
      this.fetchSchoolLevels()
    }
  }


  fetchSchoolLevels() {
    if (this.hasSchoolLevelInputTarget == false) { return }

    this.schoolLevelInputTomSelect.clear()
    this.schoolLevelInputTomSelect.clearOptions()

    if (this.schoolListTarget.value == "") {
      this._disableSchoolLevelInput()
      return
    }
    this._enableSchoolLevelInput()


    fetch(`${this.baseUrl}/school_levels?school_id=${this.schoolListTarget.value}`, { headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' } })
      .then(response => response.json())
      .then(data => {
        const options = data.map(school_level => new Option(school_level.full_name_without_school, school_level.id, false, false))
        this.schoolLevelInputTomSelect.addOption(options);
        this.schoolLevelInputTomSelect.refreshOptions(false);
        options.length == 0 ? this._disableSchoolLevelInput() : this._enableSchoolLevelInput()
    })
  }

  _clearSchoolInput() {
    this.schoolInputTomSelect.clear()
    this.schoolInputTomSelect.clearOptions()
    this.schoolInputTomSelect.refreshOptions(false);
  }

  setSchoolZipCodeAndSchoolType() {
    const schoolZipCode = this.schoolInputTomSelect.options[this.schoolInputTomSelect.getValue()].schoolZipCode
    const schoolType = this.schoolInputTomSelect.options[this.schoolInputTomSelect.getValue()].schoolType
    if (this.zipCodeTarget.value != undefined ) {
      this.zipCodeTarget.value = schoolZipCode
    }
    if (this.schoolTypeTarget.value != undefined) {
      this.schoolTypeInputTomSelect.setValue(schoolType)
    }
  }

  _generateSchoolOptions(data) {
    const options = data.map(school => {
      const option = {
        id: school.id,
        schoolName: school.full_name,
        schoolZipCode: school.zip_code,
        schoolType: school.school_type
      }
      return option
    })
    return options
  }

  setSchoolLevelLevelsCollection() {
    const primarySchoolLevelName = ["Petite section", "Moyenne section", "Grande section", "CP", "CE1", "CE2", "CM1", "CM2"]
    const primarySchoolLevelSym = ["petite_section", "moyenne_section", "grande_section", "cp", "ce1", "ce2", "cm1", "cm2"]
    const primarySchoolLevelOption = primarySchoolLevelName.map((schoolLevelName, index) =>
      new Option(schoolLevelName, primarySchoolLevelSym[index])
    )
    const secondarySchoolLevelName = ["6ème", "5ème", "4ème", "3ème"]
    const secondarySchoolLevelSym = ["sixieme", "cinquieme", "quatrieme", "troisieme"]
    const secondarySchoolLevelOption = secondarySchoolLevelName.map((schoolLevelName, index) =>
      new Option(schoolLevelName, secondarySchoolLevelSym[index])
    )
    const highSchoolLevelName = ["2nde", "1ère", "Terminale"]
    const highSchoolLevelSym = ["seconde", "premiere", "terminale"]
    const highSchoolLevelOption = highSchoolLevelName.map((schoolLevelName, index) =>
      new Option(schoolLevelName, highSchoolLevelSym[index])
    )

    let schoolLevelLevelOption

    if (this.schoolTypeInputTomSelect.items[0] == "primaire") {
      schoolLevelLevelOption = primarySchoolLevelOption
    } else if (this.schoolTypeInputTomSelect.items[0] == "college") {
      schoolLevelLevelOption = secondarySchoolLevelOption
    } else if (this.schoolTypeInputTomSelect.items[0] == "lycee") {
      schoolLevelLevelOption = highSchoolLevelOption
    } else {
      schoolLevelLevelOption = primarySchoolLevelOption.concat(secondarySchoolLevelOption).concat(highSchoolLevelOption)
    }

    this.schoolLevelLevelInputTargets.forEach(schoolLevelLevelInput => {
      if (schoolLevelLevelInput.tomselect) {
        if (Object.keys(schoolLevelLevelInput.tomselect.options).length == schoolLevelLevelOption.length) {
          return
        }
        schoolLevelLevelInput.tomselect.clear()
        schoolLevelLevelInput.tomselect.clearOptions()
        schoolLevelLevelInput.tomselect.addOption(schoolLevelLevelOption)
      } else {
        new TomSelect(schoolLevelLevelInput, {
          options: schoolLevelLevelOption
        })
      }
    })
  }

  _disableSchoolLevelInput() {
    this.schoolLevelInputTomSelect.disable()
    this.schoolLevelInputTomSelect.settings.placeholder = "Aucune classe enregistrée pour le moment"
    this.schoolLevelInputTomSelect.inputState()
  }

  _enableSchoolLevelInput() {
    this.schoolLevelInputTomSelect.enable()
    this.schoolLevelInputTomSelect.settings.placeholder = "Saisissez le niveau de votre établissement"
    this.schoolLevelInputTomSelect.inputState()
  }

  _create_tom_select_school_input() {
    this.schoolInputTomSelect = new TomSelect(this.schoolListTarget, {
      maxOptions: 20,
      placeholder: "Saisissez le nom de votre établissement",
      valueField: 'id',
	    labelField: 'schoolName',
      searchField: 'schoolName',
      sortField: {
        field: "schoolName",
        direction: "asc"
      },
      load: (value, callback) => {
        this.fetchSchools(callback)
      },
      onFocus: () => {
        this.fetchSchools()
      },
      onItemAdd: () => {
        this.setSchoolZipCodeAndSchoolType()
      },
      render: {
        no_results: function (data, escape) {
          return (
            '<div class="no-results">Pas de résultat "' +
            escape(data.input) +
            '"' +
            "<br />" +
            " " +
            "<i>Précisez un code postal et/ou un type d'établissement pour affiner la recherche</i>" +
            "</div>"
          );
        },
      },
    })
  }

  _create_tom_select_school_level_input() {
    this.schoolLevelInputTomSelect = new TomSelect(this.schoolLevelInputTarget, {
      plugins: ['remove_button'],
      maxOptions: 20,
      sortField: {
        field: "text",
        direction: "asc"
      },
      onChange: () => {
        if (this.schoolLevelInputTomSelect.getValue() == "") {
          this._add_school_level_input_placeholder()
        } else {
          this._remove_school_level_input_placeholder()
        }
      },
      render: {
        no_results: function (data, escape) {
          return (
            '<div class="no-results">Pas de résultat "' +
            escape(data.input) +
            '"</div>'
          );
        }
      }
    })
  }

  _create_tom_select_school_type_input() {
    this.schoolTypeInputTomSelect = new TomSelect(this.schoolTypeTarget, {
      maxOptions: 20,
      placeholder: "Type d'établissement",
      onFocus: () => {
        this._clearSchoolInput()
      },
      onChange: () => {
        this.setSchoolLevelLevelsCollection()
      },
      render: {
        no_results: function (data, escape) {
          return (
            '<div class="no-results">Pas de résultat "' +
            escape(data.input) +
            '"</div>'
          );
        }
      }
    })
  }

  _createTomSelectSchoolLevelLevelInput() {
    this.schoolLevelLevelInputTargets.forEach(schoolLevelLevelInput => {
      new TomSelect(schoolLevelLevelInput)
    })
  }

  _remove_school_level_input_placeholder() {
    this.schoolLevelInputTomSelect.settings.placeholder = ""
    this.schoolLevelInputTomSelect.inputState()
  }

  _add_school_level_input_placeholder() {
    this.schoolLevelInputTomSelect.settings.placeholder = "Sélectionner une ou plusieurs classes"
    this.schoolLevelInputTomSelect.inputState()
  }
}
