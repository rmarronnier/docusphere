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
  }

  async submitForm(form, url, errorContainerId, errorListId) {
    const formData = new FormData(form)
    const errorContainer = document.getElementById(errorContainerId)
    const errorList = document.getElementById(errorListId)

    // Cacher les erreurs précédentes
    errorContainer.classList.add('hidden')
    errorList.innerHTML = ''

    try {
      const response = await fetch(url, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      const data = await response.json()

      if (data.success) {
        // Fermer la modale
        const modal = form.closest('.fixed')
        if (modal) {
          modal.classList.add('hidden')
        }
        
        // Réinitialiser le formulaire
        form.reset()
        
        // Rediriger ou recharger la page
        if (data.redirect_url) {
          window.location.href = data.redirect_url
        } else {
          window.location.reload()
        }
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