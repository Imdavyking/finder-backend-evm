const mongoose = require("mongoose");
const Schema = mongoose.Schema;

/**
 * Request Schema
 */

const Request = new Schema(
  {
    address: String,
    transactionHash: String,
    eventName: String,
    signature: String,
    requestId: Number,
    buyerAddress: String,
    images: [String],
    lifecycle: Number,
    requestName: String,
    description: String,
    latitude: Number,
    longitude: Number,
    buyerId: Number,
    sellerIds: [Number],
    sellersPriceQuote: Number,
    lockedSellerId: Number,
    createdAt: Number,
    updatedAt: Number,
  },
  {
    timestamps: {
      createdAt: "created_at",
      updatedAt: "updated_at",
    },
  },
  {
    collection: "request", // Specify the desired table name here
  }
);

module.exports = mongoose.model("request", Request);
