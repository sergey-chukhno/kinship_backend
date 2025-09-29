import { Controller } from "@hotwired/stimulus"
import "tomselect"

// Connects to data-controller="nested-form-multi-select"
// Targets: data-nested-form-multi-select-target=""
export default class extends Controller {
  static targets = [ "template", "container", "multiSelect", "miniMultiSelect" ]
  static values = { index: String }

  connect() {
    this.hasTemplateTarget && this._createTemplate()
    this.hasMultiSelectTarget && this._createMultiSelect()
    this.hasMiniMultiSelectTarget && this._createMiniMultiSelect()
  }

  _removeFields(value) {
    const field = this.containerTarget.querySelector(`[value='${value}']`)
    const parent = field.parentNode
    const destroyInput = parent.querySelector('input[type="hidden"]')

    if (destroyInput) {
      destroyInput.value = true
    } else {
      parent.remove()
    }
  }

  _addFields(value) {
    const field = this.containerTarget.querySelector(`[value='${value}']`)
    if (field) {
      const parent = field.parentNode
      const destroyInput = parent.querySelector('input[type="hidden"]')
      destroyInput.value = false
    } else {
      const fieldContainer = document.createElement('div')
      const newField = this.template.replace(this.indexValue, new Date().getTime())
      fieldContainer.innerHTML = newField
      fieldContainer.querySelector('input').setAttribute('value', value)
      this.containerTarget.append(fieldContainer)
    }
  }

  _createTemplate() {
    this.template = this.templateTarget.innerHTML
  }

  _createMultiSelect() {
    this.multiSelect = new TomSelect(this.multiSelectTarget, {
      plugins: ['remove_button'],
      render: {
        no_results:function(data,escape) {
          return '<div class="no-results">Pas de résultat "'+escape(data.input)+'"</div>'
        }
      },
      onItemRemove: (value, item) => {
        this._removeFields(value);
      },
      onItemAdd: (value, item) => {
        this._addFields(value);
      }
    })
  }

  _createMiniMultiSelect() {
    this.miniMultiSelect = new TomSelect(this.miniMultiSelectTarget, {
      plugins: {
        'checkbox_options': {
          'checkedClassNames':   ['ts-checked'],
          'uncheckedClassNames': ['ts-unchecked'],
        }
      },
      render: {
        no_results:function(data,escape) {
          return '<div class="no-results">Pas de résultat "'+escape(data.input)+'"</div>'
        }
      },
      onDropdownClose: () => {
        this.miniMultiSelectTarget.form.requestSubmit()
      },
      onItemRemove: (value, item) => {
        this._removeFields(value);
      },
      onItemAdd: (value, item) => {
        this._addFields(value);
      }
    })
  }
}
