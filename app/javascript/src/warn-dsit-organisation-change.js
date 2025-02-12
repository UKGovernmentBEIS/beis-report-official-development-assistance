/*
  Show a standard JavaScript `confirm` modal with a warning message if a new
  user is being created whose email address is not in the DSIT whitelist and
  their organisation is being set to DSIT, or when an existing user is being
  edited whose email address is not in the DIST whitelist and their
  organisation is being set to DSIT from a different organisation.
*/
document.addEventListener("DOMContentLoaded", function() {
  const userForm = document.querySelector("form[data-warn-on-non-dsit]");
  
  if (!userForm) return;
  
  const VALID_DSIT_DOMAINS = userForm.dataset["domains"].split(",");
  const WARNING = userForm.dataset["warnOnNonDsit"];
  const DSIT_ORGANISATION_INDEX = 0;

  const checkEmail = email => VALID_DSIT_DOMAINS.includes(email.split("@").pop());
  const getEmail = () => document.querySelector("#user-email-field").value;
  const getOrganisationIndex = () => document.querySelector("#user_organisation_id").selectedIndex;

  const initialEmail = getEmail();
  const initialOrganisation = getOrganisationIndex();

  userForm.addEventListener("submit", (event) => {
    const email = getEmail();
    const organisation = getOrganisationIndex();

    let confirms = false;

    if (initialEmail === "") {
      confirms = !checkEmail(email) && organisation === DSIT_ORGANISATION_INDEX;        
    } else {
      confirms = !checkEmail(email) && organisation === DSIT_ORGANISATION_INDEX && initialOrganisation !== organisation;
    }

    if (confirms) {
      return confirm(WARNING) ? true : event.preventDefault();
    }
  });
});
