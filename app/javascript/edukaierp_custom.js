export function initializeNotificationSound() {
  document.addEventListener("turbo:before-render", function (event) {
    if (event.detail.newBody.querySelector("#notification_feed")) {
      const audio = document.getElementById("notification-sound");
      if (audio) {
        const playPromise = audio.play();
        if (playPromise !== undefined) {
          playPromise.catch(error => {
            console.error('Failed to play the sound:', error);
          });
        }
      }
    }
  });
}