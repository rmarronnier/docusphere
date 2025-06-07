import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["input", "progress", "preview", "form"]

  connect() {
    this.input = this.inputTarget
    this.input.addEventListener("change", this.uploadFiles.bind(this))
    this.statusCheckIntervals = new Map()
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
    preview.className = "flex items-center space-x-3 p-3 bg-gray-50 rounded-lg mb-2"
    preview.dataset.blobId = blob.signed_id
    
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
        <span class="status-badge inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
          Téléversé
        </span>
      </div>
    `
    
    this.previewTarget.appendChild(preview)
    
    // Submit form if needed and track processing
    if (this.hasFormTarget) {
      this.submitFormWithBlob(blob, preview)
    }
  }
  
  async submitFormWithBlob(blob, previewElement) {
    const form = this.formTarget
    const formData = new FormData(form)
    
    // Add the blob signed ID to form
    const fileInput = form.querySelector('input[type="file"]')
    const fieldName = fileInput.name.replace('[file]', '[file_blob_id]')
    formData.set(fieldName, blob.signed_id)
    
    try {
      const response = await fetch(form.action, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })
      
      const result = await response.json()
      
      if (result.success && result.document) {
        // Start checking processing status
        const interval = setInterval(() => {
          this.checkProcessingStatus(result.document.id, previewElement)
        }, 2000) // Check every 2 seconds
        
        this.statusCheckIntervals.set(result.document.id, interval)
        
        // Initial status check
        this.checkProcessingStatus(result.document.id, previewElement)
      }
    } catch (error) {
      console.error('Error submitting document:', error)
      const statusBadge = previewElement.querySelector('.status-badge')
      statusBadge.className = 'status-badge inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800'
      statusBadge.textContent = 'Erreur'
    }
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
  
  disconnect() {
    // Clear all status check intervals when controller disconnects
    this.statusCheckIntervals.forEach(interval => clearInterval(interval))
  }
  
  async checkProcessingStatus(documentId, previewElement) {
    try {
      const response = await fetch(`/ged/documents/${documentId}/status`)
      const status = await response.json()
      
      this.updatePreviewStatus(previewElement, status)
      
      // Stop checking if processing is complete or failed
      if (status.processing_status === 'completed' || status.processing_status === 'failed') {
        const interval = this.statusCheckIntervals.get(documentId)
        if (interval) {
          clearInterval(interval)
          this.statusCheckIntervals.delete(documentId)
        }
      }
    } catch (error) {
      console.error('Error checking document status:', error)
    }
  }
  
  updatePreviewStatus(previewElement, status) {
    const statusBadge = previewElement.querySelector('.status-badge')
    const processingInfo = previewElement.querySelector('.processing-info') || this.createProcessingInfo(previewElement)
    
    // Update status badge
    statusBadge.className = 'status-badge inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium'
    
    switch(status.processing_status) {
      case 'pending':
        statusBadge.className += ' bg-yellow-100 text-yellow-800'
        statusBadge.textContent = 'En attente'
        break
      case 'processing':
        statusBadge.className += ' bg-blue-100 text-blue-800'
        statusBadge.innerHTML = '<svg class="animate-spin -ml-1 mr-1 h-3 w-3 text-blue-800" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> Traitement...'
        break
      case 'completed':
        statusBadge.className += ' bg-green-100 text-green-800'
        statusBadge.textContent = 'Terminé'
        break
      case 'failed':
        statusBadge.className += ' bg-red-100 text-red-800'
        statusBadge.textContent = 'Échec'
        break
    }
    
    // Update processing info
    const infoItems = []
    if (status.virus_scan_status === 'clean') infoItems.push('✓ Scan antivirus')
    if (status.virus_scan_status === 'infected') infoItems.push('⚠️ Virus détecté!')
    if (status.preview_generated) infoItems.push('✓ Aperçu')
    if (status.thumbnail_generated) infoItems.push('✓ Miniature')
    if (status.extracted_content) infoItems.push('✓ Contenu extrait')
    if (status.ocr_performed) infoItems.push('✓ OCR')
    if (status.tags_count > 0) infoItems.push(`✓ ${status.tags_count} tags`)
    if (status.metadata_count > 0) infoItems.push(`✓ ${status.metadata_count} métadonnées`)
    
    processingInfo.innerHTML = infoItems.join(' • ')
    
    if (status.processing_error) {
      processingInfo.innerHTML += `<div class="text-red-600 text-xs mt-1">Erreur: ${status.processing_error}</div>`
    }
  }
  
  createProcessingInfo(previewElement) {
    const info = document.createElement('div')
    info.className = 'processing-info text-xs text-gray-500 mt-1'
    previewElement.querySelector('.flex-1').appendChild(info)
    return info
  }
}