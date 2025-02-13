import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { apiKey: String };
  static targets = ["input"];

  connect() {
    if (typeof google === "undefined" || !google.maps) {
      this.loadGoogleMapsScript();
    } else {
      this.initAutocomplete();
    }
  }

  loadGoogleMapsScript() {
    if (document.querySelector("script#google-maps")) return;

    const script = document.createElement("script");
    script.src = `https://maps.googleapis.com/maps/api/js?key=${this.apiKeyValue}&libraries=places&callback=initAutocomplete`;
    script.id = "google-maps";
    script.async = true;
    script.defer = true;
    document.head.appendChild(script);

    window.initAutocomplete = this.initAutocomplete.bind(this);
  }

  initAutocomplete() {
    if (!this.hasInputTarget) return;

    this.autocomplete = new google.maps.places.Autocomplete(this.inputTarget, {
      types: ["geocode"],
    });

    this.autocomplete.addListener("place_changed", () => {
      const place = this.autocomplete.getPlace();
      if (!place.geometry) return;

      this.inputTarget.value = place.formatted_address || "";
    });
  }
}
