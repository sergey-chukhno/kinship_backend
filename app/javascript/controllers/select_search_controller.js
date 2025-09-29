import { Controller } from "@hotwired/stimulus";
import "tomselect"

// Connects to data-controller="select-search"

export default class extends Controller {
  static targets = [ "defaultSelect", "removableSelect", "removableCreatableSelect" ]
  static values = {
    resize: Boolean
  }

  connect() {
    this.hasDefaultSelectTarget && this.createDefaultSelect()
    this.hasRemovableSelectTarget && this.createRemovableSelect()
    this.hasRemovableCreatableSelectTarget && this.createRemovableCreatableSelect()
  }

  createDefaultSelect() {
    this.defaultSelectTargets.forEach((select) => {
      new TomSelect(select, {
        render: {
          no_results:function(data,escape) {
            return '<div class="no-results">Pas de résultat "'+escape(data.input)+'"</div>'
          }
        }
      })
    })
  }

  createRemovableSelect() {
    this.removableSelectTargets.forEach((select) => {
      new TomSelect(select, {
        plugins: ['remove_button'],
        render: {
          no_results:function(data,escape) {
            return '<div class="no-results">Pas de résultat "'+escape(data.input)+'"</div>'
          }
        },
        onDropdownOpen: (dropdown) => {
          this.resizeValue === true && (dropdown.parentNode.style.marginBottom = dropdown.offsetHeight + 20 + "px");
        },
        onDropdownClose: (dropdown) => {
          this.resizeValue === true && (dropdown.parentNode.style.marginBottom = "0");
        }
      })
    })
  }

  createRemovableCreatableSelect() {
    this.removableCreatableSelectTargets.forEach((select) => {
      const tomSelectRemovableCreatableSelect = new TomSelect(select, {
        create: true,
        plugins: ['remove_button'],
        render: {
          option: function(data, escape) { return },
          no_results:function(data,escape) { return },
          option_create: function(data, escape) { return }
        }
      })
      tomSelectRemovableCreatableSelect.wrapper.classList.add("hide-after");
    })
  }
}
