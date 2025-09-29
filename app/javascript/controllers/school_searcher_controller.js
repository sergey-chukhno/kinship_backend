import { Controller } from "@hotwired/stimulus";
import "tomselect";

export default class extends Controller {
  static targets = ["schoolInput", "projectSchoolInput", "schoolLevelInput", "participantSchoolInput"];
  static values = {
    teacher: Boolean,
    currentuserid: Number
  };

  // Used in :
  // Index participants + Form Project index project

  connect() {
    this.baseUrl = window.location.origin
    if (this.hasSchoolInputTarget) { this.createTomSelectSchoolInput(); }
    if (this.hasProjectSchoolInputTarget) { this.createTomSelectProjectSchoolInput(); }
    if (this.hasSchoolLevelInputTarget) { this.createTomSelectSchoolLevelInput(); }
    if (this.hasParticipantSchoolInputTarget) { this.createTomSelectParticipantSchoolInput(); }
  }
  disconnect() {
    if (this.hasSchoolInputTarget) { this.schoolInputTomSelect.destroy(); }
    if (this.hasSchoolLevelInputTarget) { this.schoolLevelInputTomSelect.destroy(); }
    if (this.hasParticipantSchoolInputTarget) { this.participantSchoolInputTomSelect.destroy(); }
  }
  clearSchoolLevelOptions() {
    this.schoolLevelInputTomSelect.clear()
    this.schoolLevelInputTomSelect.clearOptions()
  }
  toggleSchoolLevelInput(toggle) {
    toggle.length > 0 ? this.schoolLevelInputTomSelect.enable() : this.schoolLevelInputTomSelect.disable()
  }
  refreshSchoolLevelOptions(options, teacher = true, customOption = false) {
    if (customOption) {
      this.schoolLevelInputTomSelect.addOption(new Option(`Toutes ${teacher ? "les" : "mes"} classes`, "all_levels", false, false))
    } else {
      this.schoolLevelInputTomSelect.addOption(new Option(`Toutes ${teacher ? "les" : "mes"} classes`, "", false, false))
    }
    options.map((school_level) => {
      this.schoolLevelInputTomSelect.addOption(new Option(school_level.full_name_without_school, school_level.id, false, false))
    })
  }
  fetchAllSchoolsLevels(school_id, customOption = false) {
    this.toggleSchoolLevelInput(school_id)

    if (school_id) {
      fetch(
        `${this.baseUrl}/school_levels?school_id=${school_id}`,
        {
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
          },
        }
      )
      .then((response) => response.json())
      .then((data) => {
        this.toggleSchoolLevelInput(data)
        this.refreshSchoolLevelOptions(data, true, customOption)
      })
    }
  }
  fetchParticipantsSchoolLevel(school_id, teacher, currentuserid) {
    this.toggleSchoolLevelInput(school_id)

    if (teacher) {
      return this.fetchAllSchoolsLevels(school_id)
    }

    if (school_id) {
      fetch(
        `${this.baseUrl}/school_levels?school_id=${school_id}&current_user_id=${currentuserid}`,
        {
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
          },
        }
      )
      .then((response) => response.json())
      .then((data) => {
        this.toggleSchoolLevelInput(data)
        this.refreshSchoolLevelOptions(data, teacher)
      })
    }
  }
  selectAllSchoolsLevels() {
    if (this.schoolLevelInputTomSelect.getValue().includes("all_levels")) {
      const optionsObject = this.schoolLevelInputTomSelect.options
      delete optionsObject["all_levels"]
      const optionsArray = Object.keys(optionsObject)

      this.schoolLevelInputTomSelect.removeItem("all_levels")

      optionsArray.forEach((option) => {
        this.schoolLevelInputTomSelect.addItem(option)
      })

      this.schoolLevelInputTomSelect.addOption(new Option(`Toutes les classes`, "all_levels", false, false))
    }
  }
  createTomSelectSchoolInput() {
    this.schoolInputTomSelect = new TomSelect(this.schoolInputTarget, {
      maxOptions: 20,
      allowEmptyOption: true,
      onType: () => {
        this.schoolInputTomSelect.control_input.parentNode.getElementsByClassName("item")[0].classList.add("d-none");
      },
      onChange: () => {
        this.schoolInputTomSelect.blur();
      },
      onBlur: () => {
        this.clearSchoolLevelOptions()
        this.fetchAllSchoolsLevels(this.schoolInputTarget.value)
      },
    });
  }
  createTomSelectProjectSchoolInput() {
    this.projectSchoolInputTomSelect = new TomSelect(this.projectSchoolInputTarget, {
      maxOptions: 20,
      allowEmptyOption: true,
      onType: () => {
        this.projectSchoolInputTomSelect.control_input.parentNode.getElementsByClassName("item")[0].classList.add("d-none");
      },
      onChange: () => {
        this.projectSchoolInputTomSelect.blur();
      },
      onBlur: () => {
        this.clearSchoolLevelOptions()
        this.fetchAllSchoolsLevels(this.projectSchoolInputTarget.value, true)
      },
    });
  }
  createTomSelectParticipantSchoolInput() {
    this.participantSchoolInputTomSelect = new TomSelect(this.participantSchoolInputTarget, {
      maxOptions: 20,
      allowEmptyOption: true,
      onType: () => {
        this.participantSchoolInputTomSelect.control_input.parentNode.getElementsByClassName("item")[0].classList.add("d-none");
      },
      onChange: () => {
        this.participantSchoolInputTomSelect.blur();
        this.refreshFilters(this.participantSchoolInputTarget.value)
      },
      onBlur: () => {
        this.clearSchoolLevelOptions()
        this.fetchParticipantsSchoolLevel(this.participantSchoolInputTarget.value, this.teacherValue, this.currentuseridValue)
      },
    });
  }
  createTomSelectSchoolLevelInput() {
    this.schoolLevelInputTomSelect = new TomSelect(this.schoolLevelInputTarget, {
      maxOptions: 20,
      allowEmptyOption: true,
      onInitialize: () => {
        // TODO : remove this timeout when tomselect will be updated
        setTimeout(() => {
          Object.keys(this.schoolLevelInputTomSelect.options).length === 1 && this.schoolLevelInputTomSelect.disable()
        }, 1);
      },
      onType: () => {
        this.schoolLevelInputTomSelect.control_input.parentNode.getElementsByClassName("item")[0].classList.add("d-none");
      },
      onChange: () => {
        this.schoolLevelInputTomSelect.blur();
        this.selectAllSchoolsLevels()
      },
    });
  }

  refreshFilters(value) {
    let frame = document.querySelector('turbo-frame#filters')
    frame.src = `${window.location.pathname}?filters[school]=${value}`
    frame.reload()
  }
}

// TODO : Use only one method for fetchSchoolLevels but add more params to it with an object
