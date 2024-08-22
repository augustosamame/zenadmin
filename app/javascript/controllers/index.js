// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import ComboSelectController from "./combo_select_controller"
application.register("combo-select", ComboSelectController)

import CustomModalController from "./custom_modal_controller"
application.register("custom-modal", CustomModalController)

import DatatableController from "./datatable_controller"
application.register("datatable", DatatableController)

import DropdownController from "./dropdown_controller"
application.register("dropdown", DropdownController)

import HelloController from "./hello_controller"
application.register("hello", HelloController)

import ModalController from "./modal_controller"
application.register("modal", ModalController)

import ObjectTableModalController from "./object_table_modal_controller"
application.register("object-table-modal", ObjectTableModalController)

import NavController from "./nav_controller"
application.register("nav", NavController)

import Pos__ButtonsController from "./pos/buttons_controller"
application.register("pos--buttons", Pos__ButtonsController)

import Pos__CommentModalController from "./pos/comment_modal_controller"
application.register("pos--comment-modal", Pos__CommentModalController)

import Pos__KeypadController from "./pos/keypad_controller"
application.register("pos--keypad", Pos__KeypadController)

import Pos__OrderItemsController from "./pos/order_items_controller"
application.register("pos--order-items", Pos__OrderItemsController)

import Pos__PaymentController from "./pos/payment_controller"
application.register("pos--payment", Pos__PaymentController)

import Pos__ProductGridController from "./pos/product_grid_controller"
application.register("pos--product-grid", Pos__ProductGridController)

import TabsController from "./tabs_controller"
application.register("tabs", TabsController)

import TooltipController from "./tooltip_controller"
application.register("tooltip", TooltipController)
