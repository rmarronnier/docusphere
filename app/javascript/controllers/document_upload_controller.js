import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["input", "progress", "preview"]

  connect() {
    this.input = this.inputTarget
    this.input.addEventListener("change", this.uploadFiles.bind(this))
  }

  uploadFiles() {
    Array.from(this.input.files).forEach(file => {
      this.uploadFile(file)
    })
  }

  uploadFile(file) {
    const upload = new DirectUpload(file, this.input.dataset.directUploadUrl, this)
    
    upload.create((error, blob) => {
      if (error) {
        console.error("Upload failed:", error)
      } else {
        this.createPreview(file, blob)
      }
    })
  }

  createPreview(file, blob) {
    const preview = document.createElement("div")
    preview.className = "flex items-center space-x-3 p-3 bg-gray-50 rounded-lg"
    
    preview.innerHTML = `
      <div class="flex-shrink-0">
        <svg class="h-8 w-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-sm font-medium text-gray-900">${file.name}</p>
        <p class="text-sm text-gray-500">${this.formatFileSize(file.size)}</p>
      </div>
      <div class="flex-shrink-0">
        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
          Téléversé
        </span>
      </div>
    `
    
    this.previewTarget.appendChild(preview)
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  directUploadWillStoreFileWithXHR(request) {
    request.upload.addEventListener("progress", 
      event => this.directUploadDidProgress(event))
  }

  directUploadDidProgress(event) {
    const progress = event.loaded / event.total * 100
    if (this.hasProgressTarget) {
      this.progressTarget.style.width = `${progress}%`
    }
  }
}