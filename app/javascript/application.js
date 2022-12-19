import "./src/accessible-autocomplete";
import "./src/cookie-consent";
import initTableTreeView from "./src/table-tree-view";
import "./src/toggle-providing-org-fields";
import "./src/region-countries-checkbox";
import * as GOVUKFrontend from "govuk-frontend";

document.addEventListener("DOMContentLoaded", () => {
  GOVUKFrontend.initAll();
  initTableTreeView();
});
