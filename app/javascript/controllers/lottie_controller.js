import { Controller } from "@hotwired/stimulus";
import 'lottie'

export default class extends Controller {
  connect() {
    console.log("Hello, Stimulus!")
    this.animation = lottie.loadAnimation({
      container: this.element,
      path: "https://assets-v2.lottiefiles.com/a/5e194760-1162-11ee-bf92-c7484325ebce/RjiPX2JIUt.json",
      renderer: "svg",
      loop: false,
      autoplay: true,
    });
  }

  disconnect() {
    this.animation.destroy();
  }
}
