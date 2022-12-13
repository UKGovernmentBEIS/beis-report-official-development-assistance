// adapted from https://github.com/OfficeForProductSafetyAndStandards/product-safety-database/blob/d070006b2d68ba28e6b204d9efb9807c241c1eeb/app/assets/javascripts/autocomplete.js

function rodaAccessibleAutocomplete () {
  const selectElement = document.getElementById("activity-linked-activity-id-field")

  if (!selectElement) { return }

  accessibleAutocomplete.enhanceSelectElement({
    autoselect: true,
    defaultValue: '',
    selectElement: selectElement,
    showAllValues: true,
    preserveNullOptions: true
  })

  const autocompleteElement = selectElement.parentNode.getElementsByTagName('input')[0]

  resetSelectWhenDesynced(selectElement, autocompleteElement)
  addClearButton(selectElement, autocompleteElement)
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

function addClearButton (selectElement, autocompleteElement) {
  const autocompleteOuterWrapper = autocompleteElement.parentNode.parentNode

  autocompleteOuterWrapper.className = 'autocomplete__outer-wrapper'

  const clearButton = createClearButton(selectElement, autocompleteElement)

  autocompleteOuterWrapper.append(clearButton)
}

function createClearButton (selectElement, autocompleteElement) {
  const clearButton = document.createElement('button')

  clearButton.type = 'button'
  clearButton.innerText = 'X'
  clearButton.ariaLabel = 'Clear selection'
  clearButton.className = 'autocomplete__clear-button'

  clearButton.addEventListener('click', () => {
    resetSelectAndAutocomplete(selectElement, autocompleteElement, clearButton)
  })

  clearButton.addEventListener('keydown', (event) => {
    if (event.key === ' ' || event.key === 'Enter') {
      resetSelectAndAutocomplete(selectElement, autocompleteElement, clearButton)
    }
  })

  return clearButton
}

function resetSelectAndAutocomplete (selectElement, autocompleteElement, clearButton) {
  selectElement.value = ''
  autocompleteElement.value = ''

  autocompleteElement.click()
  autocompleteElement.focus()
  autocompleteElement.blur()

  clearButton.focus()
}

document.addEventListener('DOMContentLoaded', () => rodaAccessibleAutocomplete())
