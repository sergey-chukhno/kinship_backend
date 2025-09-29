import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="submit"
export default class extends Controller {
  submit(event) {
    event.target.form.requestSubmit();
  }
}
