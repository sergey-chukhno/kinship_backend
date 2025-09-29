import { Controller } from "@hotwired/stimulus";
import Noty from "noty";

export default class extends Controller {
  connect() {
    const innerText = this.element.innerText;

    // if no text in the alert than don't show anything and return directly
    if (innerText === "") return;

    const type = this.element.classList.contains("alert")
      ? "error"
      : "information";
    new Noty({
      type: type,
      text: this.element.innerText,
      theme: "metroui",
      layout: "bottomRight",
      timeout: 3000,
    }).show();
  }
}
