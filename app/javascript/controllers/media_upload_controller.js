import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["fileInput", "previewContainer"];

  connect() {
    console.log("Media preview controller connected");
  }

  preview(event) {
    const file = event.target.files[0];
    const previewContainer = this.previewContainerTarget;

    if (file) {
      const reader = new FileReader();

      reader.onload = (e) => {
        if (file.type.startsWith("image/")) {
          previewContainer.innerHTML = `<img src="${e.target.result}" alt="Image Preview" class="w-32 h-32 object-cover rounded-md" />`;
        } else if (file.type.startsWith("video/")) {
          previewContainer.innerHTML = `
            <video controls class="w-32 h-32 object-cover rounded-md">
              <source src="${e.target.result}" type="${file.type}">
              Your browser does not support the video tag.
            </video>
          `;
        }
      };

      reader.readAsDataURL(file);
    } else {
      previewContainer.innerHTML = ""; // Clear preview if no file is selected
    }
  }
}