import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="update-admin-panel-member-status-text"
export default class extends Controller {
  static targets = ["textStatus"];

  updateStatus() {
    if (this.textStatusTarget.textContent == "Rattaché") {
      this.textStatusTarget.textContent = "En attente";
      this.textStatusTarget.classList.replace("color-var-2", "grey-03");
    } else {
      this.textStatusTarget.textContent = "Rattaché";
      this.textStatusTarget.classList.replace("grey-03", "color-var-2");
    }
  }

  // updateAdminText() {
  //   if (this.textTarget.textContent == "Admin") {
  //     this.textTarget.textContent = "Admin"
  //     this.textTarget.classList.replace("color-var-2", "grey-03")
  //   } else {
  //     this.textTarget.textContent = "Admin"
  //     this.textTarget.classList.replace("grey-03", "color-var-2")
  //   }
  // }
}
