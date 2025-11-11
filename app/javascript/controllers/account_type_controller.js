import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["savingsFields", "mortgageFields", "typeInput"]

  connect() {
    this.toggle()
  }

  toggle() {
    const accountType = this.getSelectedType()

    if (accountType === "Mortgage") {
      this.savingsFieldsTarget.classList.add("hidden")
      this.mortgageFieldsTarget.classList.remove("hidden")
    } else {
      this.savingsFieldsTarget.classList.remove("hidden")
      this.mortgageFieldsTarget.classList.add("hidden")
    }
  }

  getSelectedType() {
    const checkedRadio = this.typeInputTargets.find(input => input.checked)
    return checkedRadio ? checkedRadio.value : "SavingsAccount"
  }
}
