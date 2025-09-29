import { Controller } from "@hotwired/stimulus"
import Splide from "@splidejs/splide";

// Connects to data-controller="registration-slide"
export default class extends Controller {
  static targets = ["submitButton"]

  connect() {
    this._initializeSplide();
  }

  _initializeSplide() {
    this.splide = new Splide('.splide', {
      autoHeight: true,
      pagination: false,
      drag: false,
      gap: 20,
      speed: 0
    })
    this.splide.on('mounted', () => {
      this._hideInactiveSlides();
      this._toggleSubmitButton();
    })
    this.splide.on('move', (newIndex, prevIndex, destIndex) => {
      this._showNextSlide(newIndex, prevIndex, destIndex);
    })
    this.splide.on('moved', (newIndex, prevIndex, destIndex) => {
      setTimeout(() => {
        this._toggleSubmitButton();
      }, 1);
    })
    this.splide.mount();
  }

  _toggleSubmitButton() {
    const slidesNumber = this.splide.length;
    const currentIndex = this.splide.index;

    if (currentIndex === slidesNumber - 1) {
      this.submitButtonTarget.innerText = 'Enregistrer';
      this.submitButtonTarget.setAttribute('type', 'submit');
      this.submitButtonTarget.removeAttribute('disabled');
    } else {
      this.submitButtonTarget.setAttribute('type', 'button');
      this.submitButtonTarget.innerText = 'Continuer';
    }
  }

  _showNextSlide(newIndex, prevIndex, destIndex) {
    this.splide.Components.Elements.slides[newIndex].style.display = 'block';
    this.splide.Components.Elements.slides[prevIndex].style.display = 'none';
    if (newIndex !== destIndex) {
      this.splide.Components.Elements.slides[destIndex].style.display = 'none'
    }
  }

  _hideInactiveSlides() {
    const slidesNumber = this.splide.length;

    for (let i = 1; i < slidesNumber; i++) {
      console.log(this.splide.Components.Elements.slides[i])
      this.splide.Components.Elements.slides[i].style.display = 'none';
    }
  }
}
