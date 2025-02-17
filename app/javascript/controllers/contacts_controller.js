import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="contacts"
export default class extends Controller {
  static targets = ["contact"];

  redirect(event) {
    const contactItem = event.currentTarget;
    const contactUrl = contactItem.dataset.contactsUrl;

    if (contactUrl) {
      window.location.href = contactUrl;
    }
  }
}
