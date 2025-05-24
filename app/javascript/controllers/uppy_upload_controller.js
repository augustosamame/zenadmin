import { Controller } from "@hotwired/stimulus";
import Uppy from '@uppy/core';
import Dashboard from '@uppy/dashboard';
import Spanish from '@uppy/locales/lib/es_MX';
import AwsS3 from '@uppy/aws-s3';
import Compressor from '@uppy/compressor';


export default class extends Controller {
  static targets = ["fileInput", "previewContainer", "hiddenInput"];
  static values = {
    deletedFiles: { type: Array, default: [] }
  };

  connect() {
    console.log("Uppy initialized in Stimulus controller");

    this.uppy = new Uppy({
      autoProceed: false,
      locale: Spanish,
      restrictions: {
        maxNumberOfFiles: 10,
        allowedFileTypes: ['image/*', 'video/*']
      }
    });

    this.uppy.use(Dashboard, {
      inline: true,
      target: this.previewContainerTarget,
      replaceTargetContent: true,
      showProgressDetails: true,
      showSelectedFiles: true,
      note: 'Solo imágenes y videos (max 10)',
      width: '100%',
      height: 400,
      browserBackButtonClose: true,
      proudlyDisplayPoweredByUppy: false
    });

    this.uppy.use(Compressor, {
      locale: {
        strings: {
          compressingImages: 'Comprimiendo imágenes...',
          compressedX: 'Ahorraste %{size} al comprimir imágenes',
        },
      },
    });

    this.uppy.use(AwsS3, {
      getUploadParameters: (file) => {
        // Fetch presigned URL and fields from your backend
        return fetch(`/s3/params?filename=${file.name}&type=${file.type}`, {
          method: 'GET',
          headers: {
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          }
        }).then(response => response.json())
          .then(data => {
            console.log('Data from /s3/params', data);
            return {
              method: data.method,  // This should be 'POST'
              url: data.url,        // S3 bucket URL
              fields: data.fields,  // Fields to include in the form data
              headers: data.headers || {}, // Any additional headers if needed
            };
          });
      }
    });

    this.loadExistingFiles().then(() => {
      // Set autoProceed and update the state only after all files have been loaded

      console.log('Setting autoProceed to true');
      this.uppy.setOptions({ autoProceed: true });

      this.uppy.getFiles().forEach(file => {
        console.log('Setting progress for existing file:', file);
        this.uppy.setFileState(file.id, {
          progress: { uploadComplete: true, uploadStarted: true }
        });
      });

      this.addRemoveButtons();

    });
    
    this.uppy.on('complete', (result) => {
      console.log('Upload complete! We’ve uploaded these files:', result.successful);

      // hide uppy button with class uppy-StatusBar-actionBtn--done
      const uppyResetButton = document.querySelector('.uppy-StatusBar-actionBtn--done');
      console.log('Uppy Reset Button:', uppyResetButton);
      if (uppyResetButton) {
        uppyResetButton.style.display = 'none';
      }

      result.successful.forEach((file, index) => {
        const s3Key = file.meta['key'].startsWith('cache/') ? file.meta['key'].replace('cache/', '') : file.meta['key'];

        const shrineObject = {
          id: s3Key,
          storage: 'cache',
          metadata: {
            filename: file.name,
            size: file.size,
            mime_type: file.type
          }
        };

        console.log('Shrine Object:', shrineObject);

        this.addUploadedFilesToForm(shrineObject, index);

      });

      this.addRemoveButtons();

    });

    this.uppy.on('file-removed', (file) => {
      console.log('File removed:', file);
      
      // If this is an existing file (has an ID from the server), track it for deletion
      if (file.meta && file.meta.key && file.meta.existingFile) {
        const fileId = file.meta.fileId;
        if (fileId) {
          console.log('Adding file ID to deleted files:', fileId);
          const currentDeleted = this.deletedFilesValue || [];
          this.deletedFilesValue = [...currentDeleted, fileId];
          
          // Add a hidden input to track deleted files
          const deletedInput = document.createElement('input');
          deletedInput.type = 'hidden';
          deletedInput.name = 'product[deleted_media_ids][]';
          deletedInput.value = fileId;
          this.element.appendChild(deletedInput);
        }
      }
      
      // set a timeout to re-add the remove buttons
      setTimeout(() => {
        this.addRemoveButtons();
      }, 100);
    });
  }

  async loadExistingFiles() {
    // Parse the existing files from the data attribute
    let existingFiles;

    console.log('Existing files:', this.element.dataset.existingFiles);

    try {
      existingFiles = JSON.parse(this.element.dataset.existingFiles || '[]');
    } catch (error) {
      console.error('Error parsing existing files:', error);
      return;
    }

    const promises = existingFiles.map(file => {
      console.log('Fetching blob for existing file:', file);

      // Fetch the Blob data from S3 for each existing file
      const bucketName = this.element.dataset.s3Bucket || '';
      // Use the storage prefix from the file data (cache, public, private)
      const storagePrefix = file.storage || 'cache';
      
      // Handle file IDs that already contain a full path
      const fileId = file.id;
      
      // If the file ID already includes the storage prefix, don't add it again
      const url = fileId.startsWith(storagePrefix + '/') ?
        `https://${bucketName}.s3.amazonaws.com/${fileId}` :
        `https://${bucketName}.s3.amazonaws.com/${storagePrefix}/${fileId}`;
      
      console.log('Fetching file from URL:', url);
      return fetch(url)
        .then(response => response.blob())
        .then(blob => {
          console.log('Fetched blob:', blob);

          this.uppy.addFile({
            source: file.id,
            name: file.metadata.filename,
            type: blob.type,
            data: blob,
            meta: {
              key: file.id,
              fileId: file.metadata.media_id, // Store the actual media record ID
              existingFile: true // Flag to identify existing files
            }
          });
        })
        .catch(error => {
          console.error('Error fetching file from S3:', error);
        });
    });

    // Wait for all files to be processed
    await Promise.all(promises);
  }

  addRemoveButtons() {
    console.log('Adding custom remove buttons');
    // Add custom remove buttons for each file
    this.uppy.getFiles().forEach(file => {
      const fileId = file.id;
      console.log('File ID:', fileId);
      const fileElementId = `uppy_${fileId}`; // Match Uppy's ID format
      const fileElement = document.getElementById(fileElementId);

      if (fileElement) {
        console.log('File element found:', fileElement);

        // Find the specific container within the file element
        const fileInfoAndButtonsContainer = fileElement.querySelector('.uppy-Dashboard-Item-fileInfoAndButtons');

        if (fileInfoAndButtonsContainer) {
          console.log('File info and buttons container found:', fileInfoAndButtonsContainer);

          let existingRemoveButton = fileInfoAndButtonsContainer.querySelector('.custom-remove-button');

          if (!existingRemoveButton) {
          // Create a remove button with a trash icon
          const removeButton = document.createElement('button');
          removeButton.innerHTML = '🗑'; // Unicode trash bin icon
          removeButton.className = 'block ml-auto text-lg text-red-500 bg-transparent border-none cursor-pointer custom-remove-button'; // Tailwind classes


          console.log('Added Remove button:', removeButton);
          removeButton.addEventListener('click', () => {
            this.uppy.removeFile(fileId);
            console.log('File removed:', file);
          });

          // Append the remove button to the fileInfoAndButtonsContainer
          fileInfoAndButtonsContainer.appendChild(removeButton);
          }
        }
      }
    });
  }

  disconnect() {
    this.uppy.close();
  }

  addUploadedFilesToForm(file, index) {
    // Create a hidden input for file_data using the constructed Shrine object
    const hiddenInput = document.createElement('input');
    hiddenInput.type = 'hidden';
    hiddenInput.name = `product[media_attributes][${index}][file_data]`;
    hiddenInput.value = JSON.stringify(file);
    this.element.appendChild(hiddenInput);

    // Add another hidden input for media_type
    const mediaTypeInput = document.createElement('input');
    mediaTypeInput.type = 'hidden';
    mediaTypeInput.name = `product[media_attributes][${index}][media_type]`;
    mediaTypeInput.value = 'image'; // dynamically set this if needed
    this.element.appendChild(mediaTypeInput);
  }
}