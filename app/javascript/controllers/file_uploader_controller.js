import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"
import Dropzone from "dropzone"

// Connects to data-controller="file-uploader"
export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.dropZone = createDropZone(this);
    this.hideFileInput();
    this.bindEvents()
    this.showExistingFiles()
  }

  hideFileInput() {
    this.inputTarget.style.display = "none";
    this.inputTarget.disabled = true;
  }

  bindEvents() {
    this.dropZone.on("addedfile", (file) => {
      setTimeout(() => { file.accepted && createDirectUploadController(this, file).start() }, 500)
    })

    this.dropZone.on("removedfile", (file) => {
      const hiddenInput = file.controller || document.querySelector(`input[value="${file.signed_id}"]`)
      removeElement(hiddenInput)
      file.status != "error" && this.updateMaxFilesCount(-1)
    })

    this.dropZone.on("canceled", (file) => {
      file.controller && file.controller.xhr.abort()
    })

    this.dropZone.on("processing", (file) => {
      this.submitButton.disabled = true
    })

    this.dropZone.on("queuecomplete", (file) => {
      this.submitButton.disabled = false
    })
  }

  showExistingFiles() {
    const files = this.data.get("files")
    if (!files) { return }

    const jsonFiles = JSON.parse(files)
    jsonFiles.forEach(jsonFile => {
      const mockFile = { name: jsonFile.filename, size: jsonFile.byte_size, type: jsonFile.content_type, signed_id: jsonFile.signed_id }
      this.dropZone.files.push(mockFile)
      this.dropZone.displayExistingFile(mockFile, jsonFile.url, null, null, false)
      this.createHiddenInput(jsonFile)
    })

    this.updateMaxFilesCount(jsonFiles.length)
  }

  createHiddenInput(jsonFile) {
    const hiddenInput = document.createElement("input")
    hiddenInput.type = "hidden"
    hiddenInput.name = this.inputTarget.name
    hiddenInput.value = jsonFile.signed_id
    insertAfter(hiddenInput, this.inputTarget)
  }

  updateMaxFilesCount(localFilesCount) {
    this.dropZone.options.maxFiles = this.dropZone.options.maxFiles - localFilesCount
  }

  get headers() { return { "X-CSRF-Token": getMetaValue("csrf-token") } }

  get url() { return this.inputTarget.getAttribute("data-direct-upload-url") }

  get maxFiles() { return this.data.get("maxFiles") || 1 }

  get maxFileSize() { return this.data.get("maxFileSize") || 256 }

  get acceptedFiles() { return this.data.get("acceptedFiles") }

  get addRemoveLinks() { return this.data.get("addRemoveLinks") || true }

  get uploadMultiple() { return this.data.get("uploadMultiple") || false }

  get form() { return this.element.closest("form") }

  get submitButton() { return findElement(this.form, "input[type=submit], button[type=submit]") }
}

class DirectUploadController {
  constructor(source, file) {
    this.directUpload = createDirectUpload(file, source.url, this)
    this.source = source
    this.file = file
  }

  start() {
    this.file.controller = this
    this.hiddenInput = this.createHiddenInput()
    this.directUpload.create((error, attributes) => {
      if (error) {
        removeElement(this.hiddenInput)
        this.emitDropzoneError(error)
      } else {
        this.hiddenInput.value = attributes.signed_id
        this.emitDropzoneSuccess()
      }
    })
  }

// Private
  createHiddenInput() {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = this.source.inputTarget.name
    insertAfter(input, this.source.inputTarget)
    return input
  }

  directUploadWillStoreFileWithXHR(xhr) {
    this.bindProgressEvent(xhr)
    this.emitDropzoneUploading()
  }

  bindProgressEvent(xhr) {
    this.xhr = xhr
    this.xhr.upload.addEventListener("progress", event => this.uploadRequestDidProgress(event))
  }

  uploadRequestDidProgress(event) {
    const element = this.source.element
    const progress = event.loaded / event.total * 100
    findElement(this.file.previewTemplate, ".dz-upload").style.width = `${progress}%`
  }

  emitDropzoneUploading() {
    this.file.status = Dropzone.UPLOADING
    this.source.dropZone.emit("processing", this.file)
  }

  emitDropzoneError(error) {
    this.file.status = Dropzone.ERROR
    this.source.dropZone.emit("error", this.file, error)
    this.source.dropZone.emit("complete", this.file)
  }

  emitDropzoneSuccess() {
    this.file.status = Dropzone.SUCCESS
    this.source.dropZone.emit("success", this.file)
    this.source.dropZone.emit("complete", this.file)
  }
}

function createDirectUploadController(source, file) {
  return new DirectUploadController(source, file)
}

function createDirectUpload(file, url, controller) {
  return new DirectUpload(file, url, controller)
}

function createDropZone(controller) {
  return new Dropzone(controller.element, {
    url: controller.url,
    headers: controller.headers,
    maxFiles: controller.maxFiles,
    maxFilesize: controller.maxFileSize,
    acceptedFiles: controller.acceptedFiles,
    addRemoveLinks: controller.addRemoveLinks,
    uploadMultiple: controller.uploadMultiple,
    autoQueue: false,
    // translation
    dictCancelUpload: "Annuler",
    dictCancelUploadConfirmation: "Êtes-vous sûr de vouloir annuler ce téléchargement ?",
    dictRemoveFile: "Supprimer",
    dictMaxFilesExceeded: "Vous ne pouvez pas ajouter plus de fichiers",
    dictInvalidFileType: "Vous ne pouvez pas ajouter de fichiers de ce type",
    dictFileTooBig: "Ce fichier est trop volumineux ({{filesize}}Mo). Taille maximale : {{maxFilesize}}Mo",
    dictFallbackMessage: "Votre navigateur ne supporte pas le téléchargement de fichiers par glisser-déposer",
  })
}

function getMetaValue(name) {
  const element = findElement(document.head, `meta[name="${name}"]`)
  if (element) {
    return element.getAttribute("content")
  }
}

function findElement(root, selector) {
  if (typeof root == "string") {
    selector = root
    root = document
  }
  return root.querySelector(selector)
}

function removeElement(element) {
  if (element && element.parentNode) {
    element.parentNode.removeChild(element);
  }
}

function insertAfter(el, referenceNode) {
    return referenceNode.parentNode.insertBefore(el, referenceNode.nextSibling);
}
