function toggleProvidingOrgFields() {
  // Detect which budget type is currently selected
  var budgetTypeRadios = document.querySelectorAll('input[name="budget[budget_type]"].govuk-radios__input');
  var selectedBudgetType = Array.from(budgetTypeRadios).find((node) => node.checked)?.value;

  if (selectedBudgetType === undefined)
    return;

  if (selectedBudgetType === "direct") { // direct
    document.querySelector("#providing-org-external").classList.add("js-hidden");
  } else { // assume external
    document.querySelector("#providing-org-external").classList.remove("js-hidden");
  }
}

document.addEventListener("DOMContentLoaded", function() {
  toggleProvidingOrgFields();

  var budgetTypeRadios = document.querySelectorAll('input[name="budget[budget_type]"].govuk-radios__input');

  for (let elem of budgetTypeRadios) {
    elem.addEventListener("change", function(event) {
      toggleProvidingOrgFields();
    });
  };
})
