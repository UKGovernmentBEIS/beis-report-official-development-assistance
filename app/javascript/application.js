import Rails from "@rails/ujs"
import "./src/accessible-autocomplete";
import "./src/cookie-consent";
import initTableTreeView from "./src/table-tree-view";
import "./src/toggle-providing-org-fields";
import "./src/region-countries-checkbox";
import "./src/edit-user-additional-organisations";
import "./src/warn-dsit-organisation-change";
import * as GOVUKFrontend from "govuk-frontend";

document.addEventListener("DOMContentLoaded", () => {
  GOVUKFrontend.initAll();
  initTableTreeView();
});
