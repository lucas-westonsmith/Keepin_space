import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  markAsRead(event) {
    event.preventDefault();
    const button = event.currentTarget;
    const notificationId = button.dataset.notificationsIdParam;
    const notificationItem = document.getElementById(`notification-${notificationId}`);

    fetch(`/notifications/${notificationId}`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: JSON.stringify({ read: true })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        notificationItem.classList.remove("unread");
        notificationItem.style.backgroundColor = "lightgray"; // Couleur pour notifications lues
        button.remove(); // Supprimer le bouton après l'action
      }
    })
    .catch(error => console.error("Error:", error));
  }

  redirect(event) {
    // Empêcher la redirection si on clique sur "Mark as read"
    if (event.target.closest("button")) return;

    const url = event.currentTarget.dataset.notificationsUrl;
    if (url) {
      window.location.href = url;
    }
  }
}
