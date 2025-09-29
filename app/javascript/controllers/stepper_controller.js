import { Controller } from "@hotwired/stimulus";

export default class extends Controller {

  static values = {
    currentStep: Number
  }

  connect() {
    this.updateStep(this.currentStepValue);
  }

  updateStep(currentStep) {
    this.element.querySelectorAll('.stepper').forEach((element, index) => {
      if (index + 1 === currentStep) {
        element.classList.add('current');
      }
      if (index + 1 < currentStep) {
        element.classList.add('completed');
      }
    });
  }
}
