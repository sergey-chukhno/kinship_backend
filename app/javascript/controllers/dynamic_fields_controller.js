import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";

// Connects to data-controller="dynamic-fields"
export default class extends Controller {
  static targets = ["select"];
  static values = {
    url: String,
    param: String,
  };

  connect() {
    this._toggleSelect();
  }

  change(event) {
    this._fetchValues(event.target.value);
  }

  _fetchValues(value) {
    let param = new URLSearchParams();
    param.append(this.paramValue, value);

    get(`${this.urlValue}?${param}`, {
      responseKind: "turbo-stream",
    }).then((response) => {
      response.responseText.then((_response) => {
        setTimeout(() => {
          this._toggleSelect();
        }, 100);
      });
    });
  }

  _toggleSelect() {
    console.log(this.selectTarget.options.length);

    if (this.selectTarget.options.length > 1) {
      this.selectTarget.disabled = false;
    } else {
      this.selectTarget.disabled = true;
    }
  }
}
