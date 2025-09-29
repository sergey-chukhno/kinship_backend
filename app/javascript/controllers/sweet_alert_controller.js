import { Controller } from "@hotwired/stimulus"
import Swal from 'sweetalert2'

export default class extends Controller {

  delete_account(event) {
    event.preventDefault()

    Swal.fire({
      customClass: {
        title: "paragraph text-align-left",
        htmlContainer: "s-paragraph grey-03 text-align-left p-16px",
        confirmButton: 'btn-success',
        cancelButton: 'btn-danger',
        actions: 'flex flex-wrap align-center gap-16px justify-center'
      },
      buttonsStyling: false,
      title: 'Souhaitez-vous demander la suppression de votre compte ?',
      text: "En soumettant cette demande, vous consentez à la suppression définitive de toutes les données associées à votre compte utilisateur, conformément aux règles de protection des données RGPD.",
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Oui, demander la suppression',
      cancelButtonText: 'Non, annuler',
      reverseButtons: true
    }).then((result) => {
      if (result.isConfirmed) {
        fetch(event.target.href, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': document.querySelector("meta[name=csrf-token]").content
          }
        })
        .then(response => {
          if (response.ok) {
            Swal.fire({
              customClass: {
                title: "paragraph text-align-left",
                htmlContainer: "s-paragraph grey-03 text-align-left p-16px",
                confirmButton: 'btn-success',
                actions: 'flex flex-wrap align-center gap-16px justify-center'
              },
              title: 'Votre compte a été supprimé avec succès',
              icon: 'success',
              confirmButtonText: 'Ok',
            })
            setTimeout(() => {
              window.location.href = "/";
            }, 3000);
          } else {
            Swal.fire({
              customClass: {
                title: "paragraph text-align-left",
                htmlContainer: "s-paragraph grey-03 text-align-left p-16px",
                confirmButton: 'btn-success',
                actions: 'flex flex-wrap align-center gap-16px justify-center'
              },
              title: 'Une erreur est survenue, merci de réessayer plus tard.',
              icon: 'error',
              confirmButtonText: 'Ok',
            })
          }
        })
        }
    })
  }
}
