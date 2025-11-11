import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["amountField", "balanceField", "amountInput", "balanceInput"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const mode = this.element.querySelector('input[name="mode"]:checked').value

    if (mode === "set_balance") {
      this.amountFieldTarget.classList.add("hidden")
      this.balanceFieldTarget.classList.remove("hidden")
      this.amountInputTarget.value = "" // Clear amount when switching
    } else {
      this.amountFieldTarget.classList.remove("hidden")
      this.balanceFieldTarget.classList.add("hidden")
      this.balanceInputTarget.value = "" // Clear balance when switching
    }
  }
}
