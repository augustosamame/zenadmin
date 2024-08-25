import { Controller } from "@hotwired/stimulus";
import Uppy from '@uppy/core';
import Dashboard from '@uppy/dashboard';
import Spanish from '@uppy/locales/lib/es_MX';
import AwsS3 from '@uppy/aws-s3';
import Compressor from '@uppy/compressor';


export default class extends Controller {
  static targets = ["fileInput", "previewContainer", "hiddenInput"];

  connect() {
    console.log("Uppy initialized in Stimulus controller");

    this.uppy = new Uppy({
      autoProceed: true,
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
    
    this.uppy.on('complete', (result) => {
      console.log('Upload complete! We’ve uploaded these files:', result.successful);

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