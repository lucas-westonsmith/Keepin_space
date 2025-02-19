import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["option"];

  addOption(event) {
    event.preventDefault();
    let newOption = this.optionTemplateTarget.cloneNode(true);
    newOption.querySelector("input").value = ""; // Reset the value
    this.element.querySelector("#poll-options").appendChild(newOption);
  }

  removeOption(event) {
    event.preventDefault();
    let option = event.target.closest('.poll-option-fields');
    option.remove();
  }
}
