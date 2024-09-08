import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container", "form"]

  connect() {
    console.log("Dynamic form controller connected")
  }

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML('beforeend', content)

    // Clean up Tom Select-specific elements and attributes in the new line
    const newLine = this.containerTarget.lastElementChild
    newLine.querySelectorAll(".ts-wrapper").forEach(wrapper => wrapper.remove())
    newLine.querySelectorAll("input, select").forEach(input => {
      input.value = ""
      input.classList.remove("tomselected", "ts-hidden-accessible")
      input.removeAttribute("id")
      input.style.display = ''
    })

    // Initialize Tom Select for the new row if needed
    // this.initializeTomSelect(newLine.querySelector('select[data-controller="select"]'))
  }

  remove(event) {
    event.preventDefault()
    const wrapper = event.target.closest('.nested-fields')
    if (wrapper.dataset.newRecord === "true") {
      wrapper.remove()
    } else {
      wrapper.style.display = 'none'
      wrapper.querySelector("input[name*='_destroy']").value = 1
    }
  }

  submitForm(event) {
    event.preventDefault()
    console.log("Form submission intercepted, updating indices...")
    this.updateIndices()
    this.formTarget.submit()
  }

  updateIndices() {
    const allLines = this.containerTarget.querySelectorAll('.nested-fields')
    allLines.forEach((line, index) => {
      const select = line.querySelector('select[id^="tomselect-"]')
      if (select) {
        const match = select.id.match(/tomselect-(\d+)/)
        if (match) {
          const extractedIndex = parseInt(match[1], 10) - 1
          line.querySelectorAll('input[name], select[name]').forEach(input => {
            let name = input.getAttribute('name')
            if (name) {
              const newName = name.replace(/\[\d*\]/, `[${extractedIndex}]`)
              input.setAttribute('name', newName)
              console.log(`Updated name: ${newName}`)
            }
          })
        }
      }
    })
  }
}