// adapted from https://github.com/OfficeForProductSafetyAndStandards/product-safety-database/blob/d070006b2d68ba28e6b204d9efb9807c241c1eeb/app/assets/javascripts/autocomplete.js

function rodaAccessibleAutocomplete () {
  const selectElement = document.getElementById("activity-linked-activity-id-field")

  if (selectElement) {
    accessibleAutocomplete.enhanceSelectElement({
      autoselect: false, // this was not present in simple original
      defaultValue: '',
      selectElement: selectElement,
      showAllValues: true,
      preserveNullOptions: true // this was false in simple original
    })
    
    const autocompleteElement = selectElement.parentNode.getElementsByTagName('input')[0]
    
    resetSelectWhenDesynced(selectElement, autocompleteElement)
  }
}

function resetSelectWhenDesynced (selectElement, autocompleteElement) {
  // if the autocomplete element's value no longer matches the selected option
  // in the select element, reset the select element - in particular, this
  // avoids submitting the last selected value after clearing the input
  // @see https://github.com/alphagov/accessible-autocomplete/issues/205

  autocompleteElement.addEventListener('keyup', () => {
    const optionSelectedInSelectElement = selectElement.querySelector('option:checked')

    if (autocompleteElement.value !== optionSelectedInSelectElement.innerText) {
      selectElement.value = ''
    }
  })
}

document.addEventListener('DOMContentLoaded', () => rodaAccessibleAutocomplete())
