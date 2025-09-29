import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "password",
    "passwordConfirmation",
    "submit",
    "matchMessage",
    "lowerCaseLetter",
    "upperCaseLetter",
    "minimumLength",
    "specialCharacter"
  ];

  connect() {
    this.checkInput()
  }

  checkInput() {
    this.changeClassBasedOnCondition(this.matchMessageTarget, this.passwordTarget.value === "" || this.passwordConfirmationTarget.value === "" || this.passwordTarget.value !== this.passwordConfirmationTarget.value);
    this.changeClassBasedOnCondition(this.lowerCaseLetterTarget, !this.hasRegexMatch(/[a-z]/g));
    this.changeClassBasedOnCondition(this.upperCaseLetterTarget, !this.hasRegexMatch(/[A-Z]/g));
    this.changeClassBasedOnCondition(this.minimumLengthTarget, !(this.passwordTarget.value.length >= 8 || this.passwordConfirmationTarget.value.length >= 8));
    this.changeClassBasedOnCondition(this.specialCharacterTarget, !this.hasRegexMatch(/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/g));
    this.disableSubmit()
  }

  disableSubmit() {
    this.submitTarget.disabled = !!this.element.querySelector(".invalid");
  }

  changeClassBasedOnCondition(element, condition) {
    condition ? this._addUnvalidClass(element) : this._removeUnvalidClass(element);
  }

  hasRegexMatch(regex) {
    return this.passwordTarget.value.match(regex) ||
            this.passwordConfirmationTarget.value.match(regex);
  }

  _removeUnvalidClass(element) {
    element.classList.remove("invalid");
    element.classList.add("valid");
  }

  _addUnvalidClass(element) {
    element.classList.remove("valid");
    element.classList.add("invalid");
  }
}
