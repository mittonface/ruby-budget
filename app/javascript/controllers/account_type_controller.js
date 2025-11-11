import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["savingsFields", "mortgageFields", "creditFields", "personalLoanFields", "typeInput"]

  connect() {
    this.toggle()
  }

  toggle() {
    const accountType = this.getSelectedType()

    // Hide all field groups
    this.savingsFieldsTarget.classList.add("hidden")
    this.mortgageFieldsTarget.classList.add("hidden")
    this.creditFieldsTarget.classList.add("hidden")
    this.personalLoanFieldsTarget.classList.add("hidden")

    // Show the appropriate field group
    switch(accountType) {
      case "SavingsAccount":
        this.savingsFieldsTarget.classList.remove("hidden")
        break
      case "Mortgage":
        this.mortgageFieldsTarget.classList.remove("hidden")
        break
      case "CreditCard":
      case "LineOfCredit":
        this.creditFieldsTarget.classList.remove("hidden")
        break
      case "PersonalLoan":
        this.personalLoanFieldsTarget.classList.remove("hidden")
        break
    }
  }

  getSelectedType() {
    const checkedRadio = this.typeInputTargets.find(input => input.checked)
    return checkedRadio ? checkedRadio.value : "SavingsAccount"
  }
}
