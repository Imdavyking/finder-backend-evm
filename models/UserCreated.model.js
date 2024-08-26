const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const UserCreated = new Schema(
  {
    userAddress: String,

    username: String,
    userId: Number,
    accountType: Number,
    address: String,
    transactionHash: String,
    eventName: String,
    signature: String,
  },
  {
    timestamps: {
      createdAt: "created_at",
      updatedAt: "updated_at",
    },
  },
  {
    collection: "userCreated", // Specify the desired table name here
  }
);

module.exports = mongoose.model("userCreated", UserCreated);
