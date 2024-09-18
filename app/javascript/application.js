// Entry point for the build script in your package.json
import "./add_jquery"
import "./modules/datatables"
import "./modules/datetime-moment"
// import "./modules"
import "./controllers"

import "@hotwired/turbo-rails"

import "tom-select"

import "trix"
import "@rails/actiontext"

// Add this line to import ApexCharts CSS
import "apexcharts/dist/apexcharts.css"

import { initializeNotificationSound } from "./edukaierp_custom"
initializeNotificationSound();