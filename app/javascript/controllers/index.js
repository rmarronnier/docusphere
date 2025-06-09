// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Import specific controllers
import ChartController from "./chart_controller"
import DataGridController from "./data_grid_controller"
import DocumentGridController from "./document_grid_controller"
import LazyLoadController from "./lazy_load_controller"
import RippleController from "./ripple_controller"

// Register controllers
application.register("chart", ChartController)
application.register("data-grid", DataGridController)
application.register("document-grid", DocumentGridController)
application.register("lazy-load", LazyLoadController)
application.register("ripple", RippleController)

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)