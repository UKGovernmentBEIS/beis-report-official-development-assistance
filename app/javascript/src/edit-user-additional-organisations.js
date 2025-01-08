/*
  This progressively enhances the "Create/Edit user" form such that a primary
  organisation will be hidden from the list of additional organisations (and
  also unchecked), because a user's primary organisation can never be a member
  of that user's additional organisations.
*/
document.addEventListener("DOMContentLoaded", function() {
  const primaryOrgSelect = document.querySelector("#user_organisation_id");

  if (!primaryOrgSelect) return;

  const handleCheckboxes = () => {
    const val = primaryOrgSelect.querySelector("option:checked").value;

    document.querySelectorAll(".additional-organisations .govuk-checkboxes__item").forEach((checkboxItem) => {
      const match = checkboxItem.querySelector(`input[value="${val}"`);
      checkboxItem.style.display = match ? (match.checked = false, "none") : "block";
    });
  }

  primaryOrgSelect.addEventListener("change", handleCheckboxes);
  handleCheckboxes();
});
