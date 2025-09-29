import { Controller } from "@hotwired/stimulus"
import "tomselect"

// Connects to data-controller="add-project-member-selects"
export default class extends Controller {
  static targets = ["select"]

  connect() {
    this.initializeTomSelects()
  }

  disconnect() {
    this.tomSelects.forEach(ts => ts.destroy())
  }

  initializeTomSelects() {
    this.tomSelects = this.selectTargets.map(select => {
      let config = {}
      let availableUsers = []
      if (select.dataset.customLabels) {
        const roles = select.dataset.roles ? JSON.parse(select.dataset.roles) : {}
        config = {
          plugins: ['remove_button'],
          onFocus: function() {
            availableUsers = JSON.parse(document.getElementById('availableUsers').dataset.availableUsers)
            tomSelect.clearOptions()
            tomSelect.addOptions(availableUsers.map(user => ({ value: user.id, text: user.full_name, role: user.role, school: user.school })))
          },
          options: availableUsers,
          render: {
            option: function (data, escape) {
              const user = availableUsers.find(user => user.id == data.value)
              const role = data.data && data.data.role ? data.data.role : (roles[data.value] || 'Unknown Role')
              return '<div>' + '<span class="grey-01 fs-12 fw-400 pl-s">' + escape(user?.full_name || '') + '</span>' + '<p class="badge badge--grey mr-s ml-s">' + escape(user?.role || '') + '</p>' + '<span class="fs-4 fa-solid fa-circle mr-s"></span>' + '<span class="fw-400 fs-12 grey-03">' + escape(user?.school || '') + '</span>' + '</div>';
            },
            item: function (data, escape) {
              const user = availableUsers.find(user => user.id == data.value)
              return '<div>' + escape(user?.full_name || '') + '</div>';
            },
            no_results: function (data, escape) {
              return '<div class="no-results">No results found for "' + escape(data.input) + '"</div>';
            }
          }
        }
      } else {
        config = {
          render: {
            option: function (data, escape) {
              return '<div>' + escape(data.text) + '</div>';
            },
            item: function (data, escape) {
              return '<div>' + escape(data.text) + '</div>';
            },
            no_results: function (data, escape) {
              return '<div class="no-results">No results found for "' + escape(data.input) + '"</div>';
            }
          }
        }
      }

      if (select.multiple) {
        config.plugins.push('remove_button')
      }

      if (select.dataset.create) {
        config.create = true
      }

      const tomSelect = new TomSelect(select, config)
      return tomSelect
    })
  }
}