import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "content", "originAddress", "destinationAddress", "transportista", "peso", "bultos", "comments"]

  connect() {
    console.log("[GuiaModalController] connected");
  }

  open(event) {
    console.log("[GuiaModalController] open() called");
    // Autofill modal fields if possible
    const button = event.currentTarget;
    const sourceType = button.getAttribute("data-source-type");
    const sourceId = button.getAttribute("data-source-id");
    document.getElementById("guia_source_type").value = sourceType;
    document.getElementById("guia_source_id").value = sourceId;
    // Show modal
    this.containerTarget.classList.remove("hidden");
    this.contentTarget.classList.remove("hidden");
    document.body.classList.add("overflow-hidden");
  }

  close(event) {
    console.log("[GuiaModalController] close() called");
    if (event) event.preventDefault();
    this.containerTarget.classList.add("hidden");
    this.contentTarget.classList.add("hidden");
    document.body.classList.remove("overflow-hidden");
  }

  submit(event) {
    console.log("[GuiaModalController] submit() called");
    event.preventDefault();
    const form = event.target;
    const data = new FormData(form);
    fetch("/admin/generate_guia", {
      method: "POST",
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: data
    })
      .then(response => response.json())
      .then(json => {
        if (json.success) {
          window.location.reload();
        } else {
          alert(json.error || "Error al generar la guía.");
        }
      });
  }
}
