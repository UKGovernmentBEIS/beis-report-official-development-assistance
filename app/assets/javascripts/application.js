// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require accessible-autocomplete/dist/accessible-autocomplete.min.js
//= require rails-ujs
//= require govuk-frontend/govuk/all
//= require_tree .

function toggleProvidingOrgFields() {
  // Detect which budget type is currently selected
  var budgetTypeRadios = document.querySelectorAll('input[name="budget[budget_type]"].govuk-radios__input');
  var selectedBudgetType = Array.from(budgetTypeRadios).find((node) => node.checked);

  if (!selectedBudgetType) return;

  var budgetType = parseInt(selectedBudgetType.value, 10);

  if (TRANSFERRED_BUDGET_TYPES.includes(budgetType)) { // transferred
    document.querySelector("#providing-org-transferred").classList.remove("js-hidden");
    document.querySelector("#providing-org-external").classList.add("js-hidden");
  } else if (DIRECT_BUDGET_TYPES.includes(budgetType)) { // direct
    document.querySelector("#providing-org-external").classList.add("js-hidden");
    document.querySelector("#providing-org-transferred").classList.add("js-hidden");
  } else { // assume external
    document.querySelector("#providing-org-external").classList.remove("js-hidden");
    document.querySelector("#providing-org-transferred").classList.add("js-hidden");
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
