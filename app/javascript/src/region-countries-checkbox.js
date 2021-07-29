function toggleAllRegionCountries(regionCheckbox) {
  var regionCode = regionCheckbox.getAttribute("data-region-code");

  // select all the countries in that region
  var regionCountries = document.querySelectorAll('.region-countries-wrapper[data-region-code="' + regionCode + '"] input');
  for (let checkbox of regionCountries) {
    checkbox.checked = regionCheckbox.checked;
  }
}

document.addEventListener("DOMContentLoaded", function() {
  var regionCheckboxes = document.querySelectorAll('input.region-checkbox');

  for (let elem of regionCheckboxes) {
    elem.addEventListener("change", function(event) {
      toggleAllRegionCountries(elem);
    });
  };
})
