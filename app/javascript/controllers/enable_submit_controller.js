import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submit", "fieldToValidate"];

  connect() {
    this.element.addEventListener("input", this.evaluateFields.bind(this))
    this.evaluateFields();
  }

  evaluateFields() {
    const incompleteFields = Array.from(
      this.element.querySelectorAll("input,select,textarea")
    ).filter((input) => !input.checkValidity());
    this.submitTarget.disabled = incompleteFields.length > 0;
  }
}
