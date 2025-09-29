// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application";
import Dropdown from "stimulus-dropdown";
import NestedForm from "stimulus-rails-nested-form";
import Reveal from "stimulus-reveal-controller";

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";
eagerLoadControllersFrom("controllers", application);

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)

application.register("nested-form", NestedForm);
application.register("dropdown", Dropdown);
application.register("reveal", Reveal);
