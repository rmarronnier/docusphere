import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.setupFormSubmissions()
    this.setupSpaceChanges()
  }

  setupFormSubmissions() {
    // Formulaire de création d'espace
    const createSpaceForm = document.getElementById('createSpaceForm')
    if (createSpaceForm) {
      createSpaceForm.addEventListener('submit', (e) => {
        e.preventDefault()
        this.submitForm(createSpaceForm, '/ged/spaces', 'createSpaceErrors', 'createSpaceErrorsList')
      })
    }

    // Formulaire de création de dossier
    const createFolderForm = document.getElementById('createFolderForm')
    if (createFolderForm) {
      createFolderForm.addEventListener('submit', (e) => {
        e.preventDefault()
        this.submitForm(createFolderForm, '/ged/folders', 'createFolderErrors', 'createFolderErrorsList')
      })
    }

    // Formulaire d'upload
    const uploadForm = document.getElementById('uploadForm')
    if (uploadForm) {
      uploadForm.addEventListener('submit', (e) => {
        e.preventDefault()
        this.submitForm(uploadForm, '/ged/documents', 'uploadErrors', 'uploadErrorsList')
      })
    }
  }

  setupSpaceChanges() {
    // Charger les dossiers quand l'espace change dans la modale de dossier
    const folderSpaceSelect = document.getElementById('folder_space_id')
    if (folderSpaceSelect) {
      folderSpaceSelect.addEventListener('change', (e) => {
        this.loadFoldersForSpace(e.target.value, 'folder_parent_id')
      })
    }

    // Charger les dossiers quand l'espace change dans la modale d'upload
    const documentSpaceSelect = document.getElementById('document_space_id')
    if (documentSpaceSelect) {
      documentSpaceSelect.addEventListener('change', (e) => {
        this.loadFoldersForSpace(e.target.value, 'document_folder_id')
      })
    }
    
    // Auto-remplir le titre avec le nom du fichier
    const fileInput = document.getElementById('document_file')
    const titleInput = document.getElementById('document_title')
    if (fileInput && titleInput) {
      fileInput.addEventListener('change', (e) => {
        if (e.target.files.length > 0 && !titleInput.value) {
          const fileName = e.target.files[0].name
          const titleWithoutExt = fileName.replace(/\.[^/.]+$/, '')
          titleInput.value = titleWithoutExt
        }
      })
    }
  }

  async submitForm(form, url, errorContainerId, errorListId) {
    console.log('Submitting form to:', url)
    const formData = new FormData(form)
    const errorContainer = document.getElementById(errorContainerId)
    const errorList = document.getElementById(errorListId)

    // Cacher les erreurs précédentes
    if (errorContainer) errorContainer.classList.add('hidden')
    if (errorList) errorList.innerHTML = ''

    try {
      console.log('Form data:', Object.fromEntries(formData))
      const response = await fetch(url, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      console.log('Response status:', response.status)
      const data = await response.json()
      console.log('Response data:', data)

      if (data.success) {
        // Fermer la modale
        const modal = form.closest('.fixed')
        if (modal) {
          modal.classList.add('hidden')
        }
        
        // Réinitialiser le formulaire
        form.reset()
        
        // Afficher le message de succès
        if (data.message) {
          this.showSuccessMessage(data.message)
        }
        
        // Rediriger ou recharger la page après un court délai
        setTimeout(() => {
          if (data.redirect_url) {
            window.location.href = data.redirect_url
          } else {
            window.location.reload()
          }
        }, 1500)
      } else {
        // Afficher les erreurs
        if (data.errors && data.errors.length > 0) {
          data.errors.forEach(error => {
            const li = document.createElement('li')
            li.textContent = error
            errorList.appendChild(li)
          })
          errorContainer.classList.remove('hidden')
        }
      }
    } catch (error) {
      console.error('Erreur lors de la soumission:', error)
      const li = document.createElement('li')
      li.textContent = 'Une erreur est survenue lors de la soumission'
      errorList.appendChild(li)
      errorContainer.classList.remove('hidden')
    }
  }

  async loadFoldersForSpace(spaceId, targetSelectId) {
    const targetSelect = document.getElementById(targetSelectId)
    if (!targetSelect) return

    // Vider les options existantes sauf la première
    while (targetSelect.children.length > 1) {
      targetSelect.removeChild(targetSelect.lastChild)
    }

    if (!spaceId) return

    try {
      // Note: Il faudrait créer une route API pour récupérer les dossiers d'un espace
      // Pour l'instant, on laisse vide
    } catch (error) {
      console.error('Erreur lors du chargement des dossiers:', error)
    }
  }

  showSuccessMessage(message) {
    // Créer une div pour le message de succès
    const alertDiv = document.createElement('div')
    alertDiv.className = 'fixed top-4 right-4 z-50 max-w-sm w-full bg-green-50 border border-green-200 rounded-md p-4'
    alertDiv.innerHTML = `
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium text-green-800">${message}</p>
        </div>
      </div>
    `
    
    document.body.appendChild(alertDiv)
    
    // Retirer le message après 3 secondes
    setTimeout(() => {
      alertDiv.remove()
    }, 3000)
  }
}

// Fonctions globales pour les modales
window.openModal = function(modalId) {
  const modal = document.getElementById(modalId)
  if (modal) {
    modal.classList.remove('hidden')
  }
}

window.closeModal = function(modalId) {
  const modal = document.getElementById(modalId)
  if (modal) {
    modal.classList.add('hidden')
    
    // Réinitialiser le formulaire
    const form = modal.querySelector('form')
    if (form) {
      form.reset()
      
      // Cacher les erreurs
      const errorContainer = modal.querySelector('[id$="Errors"]')
      if (errorContainer) {
        errorContainer.classList.add('hidden')
      }
    }
  }
}

window.setSpaceContext = function(spaceId) {
  // Pré-sélectionner l'espace dans les modales
  const folderSpaceSelect = document.getElementById('folder_space_id')
  const documentSpaceSelect = document.getElementById('document_space_id')
  
  if (folderSpaceSelect) {
    folderSpaceSelect.value = spaceId
  }
  if (documentSpaceSelect) {
    documentSpaceSelect.value = spaceId
  }
}

window.setFolderContext = function(spaceId, folderId) {
  // Pré-sélectionner l'espace et le dossier dans les modales
  window.setSpaceContext(spaceId)
  
  const folderParentSelect = document.getElementById('folder_parent_id')
  const documentFolderSelect = document.getElementById('document_folder_id')
  
  if (folderParentSelect) {
    folderParentSelect.value = folderId
  }
  if (documentFolderSelect) {
    documentFolderSelect.value = folderId
  }
}