import { Controller } from "@hotwired/stimulus";
import axios from "axios";

export default class extends Controller {
  static targets = ["product1", "product2", "qty1", "qty2", "normalPrice"];

  connect() {
    console.log("combo_product_normal_price_controller connected");
    this.calculateNormalPrice();
  }

  async calculateNormalPrice() {
    if (!this.hasProduct1Target || !this.hasProduct2Target || !this.hasQty1Target || !this.hasQty2Target || !this.hasNormalPriceTarget) {
      console.error("One or more targets are missing");
      return;
    }

    const product1Id = this.product1Target.value;
    const product2Id = this.product2Target.value;
    const qty1 = parseInt(this.qty1Target.value);
    const qty2 = parseInt(this.qty2Target.value);

    if (!product1Id || !product2Id || !qty1 || !qty2) {
      this.normalPriceTarget.value = "0.00";
      return;
    }

    let product1Price = 0;
    let product2Price = 0;

    if (product1Id) {
      product1Price = await this.getProductPrice(product1Id);
    }

    if (product2Id) {
      product2Price = await this.getProductPrice(product2Id);
    }

    const normalPrice = (product1Price * qty1) + (product2Price * qty2);
    this.normalPriceTarget.value = normalPrice.toFixed(2);
  }

  async getProductPrice(productId) {
    try {
      const response = await axios.get(`/admin/products/${productId}/combo_products_show`);
      return response.data.price_cents / 100;
    } catch (error) {
      console.error("Error fetching product price:", error);
      return 0;
    }
  }
}