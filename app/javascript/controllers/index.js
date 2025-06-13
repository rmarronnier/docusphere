// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Import specific controllers
import ActionsPanelController from "./actions_panel_controller"
import ActivityTimelineController from "./activity_timeline_controller"
import ChartController from "./chart_controller"
import DashboardController from "./dashboard_controller"
import DashboardSortableController from "./dashboard_sortable_controller"
import DataGridController from "./data_grid_controller"
import DocumentGridController from "./document_grid_controller"
import DocumentPreviewController from "./document_preview_controller"
import DocumentShareController from "./document_share_controller"
import DocumentSidebarController from "./document_sidebar_controller"
import DocumentViewerController from "./document_viewer_controller"
import DropdownController from "./dropdown_controller"
import GedController from "./ged_controller"
import ImageViewerController from "./image_viewer_controller"
import ImageZoomController from "./image_zoom_controller"
import LazyLoadController from "./lazy_load_controller"
import MobileMenuController from "./mobile_menu_controller"
import ModalController from "./modal_controller"
import NotificationBellController from "./notification_bell_controller"
import PdfViewerController from "./pdf_viewer_controller"
import RippleController from "./ripple_controller"
import SearchAutocompleteController from "./search_autocomplete_controller"
import WidgetLoaderController from "./widget_loader_controller"

// Register controllers
application.register("actions-panel", ActionsPanelController)
application.register("activity-timeline", ActivityTimelineController)
application.register("chart", ChartController)
application.register("dashboard", DashboardController)
application.register("dashboard-sortable", DashboardSortableController)
application.register("data-grid", DataGridController)
application.register("document-grid", DocumentGridController)
application.register("document-preview", DocumentPreviewController)
application.register("document-share", DocumentShareController)
application.register("document-sidebar", DocumentSidebarController)
application.register("document-viewer", DocumentViewerController)
application.register("dropdown", DropdownController)
application.register("ged", GedController)
application.register("image-viewer", ImageViewerController)
application.register("image-zoom", ImageZoomController)
application.register("lazy-load", LazyLoadController)
application.register("mobile-menu", MobileMenuController)
application.register("modal", ModalController)
application.register("notification-bell", NotificationBellController)
application.register("pdf-viewer", PdfViewerController)
application.register("ripple", RippleController)
application.register("search-autocomplete", SearchAutocompleteController)
application.register("widget-loader", WidgetLoaderController)

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)