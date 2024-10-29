import { Controller } from "@hotwired/stimulus"
import confetti from 'canvas-confetti'

export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Handle initial page load
    this.playEffects()

    // Bind the event handler to the instance
    this.boundPlayEffects = this.playEffects.bind(this)

    // Handle Turbo navigation
    document.addEventListener("turbo:load", this.boundPlayEffects)
  }

  disconnect() {
    // Clean up event listener when leaving the page
    document.removeEventListener("turbo:load", this.boundPlayEffects)
    
    // Clean up any existing confetti canvases
    const canvases = document.querySelectorAll('canvas[class*="confetti"]')
    canvases.forEach(canvas => canvas.remove())
  }

  playEffects() {
    // Only play effects if we're on the ranking page
    if (!this.element.isConnected) return

    this.victorySound = document.getElementById('victory-sound')
    if (this.victorySound) {
      this.playVictorySound()
    }
    
    // Small delay to ensure DOM is ready
    requestAnimationFrame(() => {
      this.shootConfetti()
    })
  }

  playVictorySound() {
    this.victorySound.play()
  }

  shootConfetti() {
    // Create a new confetti instance each time
    const myConfetti = confetti.create(undefined, { 
      resize: true,
      useWorker: true 
    })
    
    const duration = 3 * 1000
    const end = Date.now() + duration
    const colors = ['#FFD700', '#FFA500', '#FF69B4']

    const frame = () => {
      myConfetti({
        particleCount: 3,
        angle: 60,
        spread: 55,
        origin: { x: 0 },
        colors: colors
      })
      myConfetti({
        particleCount: 3,
        angle: 120,
        spread: 55,
        origin: { x: 1 },
        colors: colors
      })

      if (Date.now() < end) {
        requestAnimationFrame(frame)
      } else {
        // Clean up this instance when done
        myConfetti.reset()
      }
    }

    frame()
  }
}