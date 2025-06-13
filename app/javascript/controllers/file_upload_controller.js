import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="file-upload"
export default class extends Controller {
  static targets = [
    "dropZone", "input", "fileList", "progressArea", 
    "progressBar", "progressText", "errorArea", "errorList"
  ]

  connect() {
    this.selectedFiles = []
    this.maxFileSize = parseInt(this.data.get('maxFileSize')) || 10 * 1024 * 1024 // 10MB default
    this.maxFiles = parseInt(this.data.get('maxFiles')) || 10
    this.acceptedTypes = this.data.get('acceptedTypes')?.split(',').map(type => type.trim()) || []
  }

  openFileDialog() {
    this.inputTarget.click()
  }

  handleDragOver(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropZoneTarget.classList.add('border-indigo-500', 'bg-indigo-50')
  }

  handleDragLeave(event) {
    event.preventDefault()
    event.stopPropagation()
    // Only remove classes if we're actually leaving the drop zone
    if (!this.dropZoneTarget.contains(event.relatedTarget)) {
      this.dropZoneTarget.classList.remove('border-indigo-500', 'bg-indigo-50')
    }
  }

  handleDrop(event) {
    event.preventDefault()
    event.stopPropagation()
    this.dropZoneTarget.classList.remove('border-indigo-500', 'bg-indigo-50')
    
    const files = Array.from(event.dataTransfer.files)
    this.processFiles(files)
  }

  handleFileSelect(event) {
    const files = Array.from(event.target.files)
    this.processFiles(files)
  }

  processFiles(files) {
    this.clearErrors()
    
    const validFiles = []
    const errors = []

    // Validate each file
    files.forEach(file => {
      const validation = this.validateFile(file)
      if (validation.valid) {
        validFiles.push(file)
      } else {
        errors.push(...validation.errors)
      }
    })

    // Check total file count
    if (this.selectedFiles.length + validFiles.length > this.maxFiles) {
      errors.push(`Maximum ${this.maxFiles} files allowed`)
    }

    if (errors.length > 0) {
      this.showErrors(errors)
      return
    }

    // Add valid files
    validFiles.forEach(file => {
      if (!this.inputTarget.multiple) {
        this.selectedFiles = [file] // Replace for single file
      } else {
        this.selectedFiles.push(file)
      }
    })

    this.updateFileList()
    this.updateFileInput()
  }

  validateFile(file) {
    const errors = []

    // File size validation
    if (file.size > this.maxFileSize) {
      errors.push(`"${file.name}" is too large (max: ${this.humanizeFileSize(this.maxFileSize)})`)
    }

    // File type validation
    if (this.acceptedTypes.length > 0) {
      const fileType = file.type
      const fileExtension = '.' + file.name.split('.').pop().toLowerCase()
      
      const isValidType = this.acceptedTypes.some(acceptedType => {
        if (acceptedType.startsWith('.')) {
          return acceptedType.toLowerCase() === fileExtension
        } else {
          return fileType.match(new RegExp(acceptedType.replace('*', '.*')))
        }
      })

      if (!isValidType) {
        errors.push(`"${file.name}" is not an accepted file type`)
      }
    }

    return {
      valid: errors.length === 0,
      errors: errors
    }
  }

  updateFileList() {
    if (!this.hasFileListTarget) return

    this.fileListTarget.innerHTML = ''

    if (this.selectedFiles.length === 0) {
      this.fileListTarget.classList.add('hidden')
      // Reset drop zone to initial state
      this.dropZoneTarget.innerHTML = `
        <div class="space-y-1 text-center pointer-events-none">
          <svg class="mx-auto h-12 w-12 text-gray-400" stroke="currentColor" fill="none" viewBox="0 0 48 48" aria-hidden="true">
            <path d="M28 8H12a4 4 0 00-4 4v20m32-12v8m0 0v8a4 4 0 01-4 4H12a4 4 0 01-4-4v-4m32-4l-3.172-3.172a4 4 0 00-5.656 0L28 28M8 32l9.172-9.172a4 4 0 015.656 0L28 28m0 0l4 4m4-24h8m-4-4v8m-12 4h.02" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          <div class="flex text-sm text-gray-600">
            <span class="font-medium text-indigo-600 hover:text-indigo-500">
              Télécharger un fichier
            </span>
            <p class="pl-1">ou glisser-déposer</p>
          </div>
          <p class="text-xs text-gray-500">
            PDF, DOC, XLS, PNG jusqu'à 50MB
          </p>
        </div>
      `
      return
    }

    // Show the file in the drop zone for single file upload
    if (!this.inputTarget.multiple && this.selectedFiles.length === 1) {
      const file = this.selectedFiles[0]
      this.dropZoneTarget.innerHTML = `
        <div class="space-y-1 text-center">
          <svg class="mx-auto h-12 w-12 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <div class="text-sm text-gray-900">
            <p class="font-medium">${file.name}</p>
            <p class="text-gray-500">${this.humanizeFileSize(file.size)}</p>
          </div>
          <p class="text-sm text-indigo-600 hover:text-indigo-500">
            Cliquer pour changer de fichier
          </p>
        </div>
      `
      
      // Auto-fill title if empty
      const titleInput = document.getElementById('document_title')
      if (titleInput && !titleInput.value) {
        // Remove extension from filename for title
        const fileName = file.name.replace(/\.[^/.]+$/, "")
        titleInput.value = fileName
      }
    } else {
      // Show file list for multiple files
      this.fileListTarget.classList.remove('hidden')
      this.selectedFiles.forEach((file, index) => {
        const fileItem = this.createFileListItem(file, index)
        this.fileListTarget.appendChild(fileItem)
      })
    }
  }

  createFileListItem(file, index) {
    const item = document.createElement('div')
    item.className = 'flex items-center justify-between p-3 bg-gray-50 rounded-md'
    
    const fileInfo = document.createElement('div')
    fileInfo.className = 'flex items-center space-x-3'
    
    const icon = this.createFileIcon(file)
    const details = document.createElement('div')
    details.innerHTML = `
      <p class="text-sm font-medium text-gray-900">${file.name}</p>
      <p class="text-sm text-gray-500">${this.humanizeFileSize(file.size)}</p>
    `
    
    fileInfo.appendChild(icon)
    fileInfo.appendChild(details)
    
    const removeButton = document.createElement('button')
    removeButton.type = 'button'
    removeButton.className = 'text-red-600 hover:text-red-800 text-sm'
    removeButton.innerHTML = 'Remove'
    removeButton.addEventListener('click', () => this.removeFile(index))
    
    item.appendChild(fileInfo)
    item.appendChild(removeButton)
    
    return item
  }

  createFileIcon(file) {
    const icon = document.createElement('div')
    icon.className = 'flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-indigo-100'
    
    // Simple file type icon
    if (file.type.startsWith('image/')) {
      icon.innerHTML = '🖼️'
    } else if (file.type.includes('pdf')) {
      icon.innerHTML = '📄'
    } else if (file.type.includes('word') || file.type.includes('document')) {
      icon.innerHTML = '📝'
    } else if (file.type.includes('sheet') || file.type.includes('excel')) {
      icon.innerHTML = '📊'
    } else {
      icon.innerHTML = '📎'
    }
    
    return icon
  }

  removeFile(index) {
    this.selectedFiles.splice(index, 1)
    this.updateFileList()
    this.updateFileInput()
  }

  updateFileInput() {
    // Create a new FileList-like object
    const dt = new DataTransfer()
    this.selectedFiles.forEach(file => dt.items.add(file))
    this.inputTarget.files = dt.files
    
    // Trigger change event
    this.inputTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }

  showProgress(percentage, text = 'Uploading...') {
    if (!this.hasProgressAreaTarget) return
    
    this.progressAreaTarget.classList.remove('hidden')
    this.progressBarTarget.style.width = `${percentage}%`
    this.progressTextTarget.textContent = text
  }

  hideProgress() {
    if (!this.hasProgressAreaTarget) return
    this.progressAreaTarget.classList.add('hidden')
  }

  showErrors(errors) {
    if (!this.hasErrorAreaTarget) return
    
    this.errorListTarget.innerHTML = ''
    errors.forEach(error => {
      const li = document.createElement('li')
      li.textContent = error
      this.errorListTarget.appendChild(li)
    })
    
    this.errorAreaTarget.classList.remove('hidden')
  }

  clearErrors() {
    if (!this.hasErrorAreaTarget) return
    this.errorAreaTarget.classList.add('hidden')
    this.errorListTarget.innerHTML = ''
  }

  humanizeFileSize(bytes) {
    if (bytes === 0) return '0 B'
    
    const units = ['B', 'KB', 'MB', 'GB']
    const exp = Math.floor(Math.log(bytes) / Math.log(1024))
    const size = (bytes / Math.pow(1024, Math.min(exp, units.length - 1))).toFixed(1)
    
    return `${size} ${units[Math.min(exp, units.length - 1)]}`
  }
}