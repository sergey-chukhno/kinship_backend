import { Controller } from "@hotwired/stimulus"
import Splide from "@splidejs/splide";

// Connects to data-controller="carousel"
export default class extends Controller {
  connect() {
    new Splide( '.splide', {
      type   : 'loop',
      drag   : true,
    } ).mount();
  }
}
