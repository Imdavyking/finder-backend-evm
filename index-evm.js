const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const { ethers } = require("ethers");
const cors = require("cors");
require("dotenv").config();
const RequestModel = require("./models/Request.model");
const OfferModel = require("./models/Offer.model");
const { isWithinThreshold, threshold } = require("./location");
const UserCreatedModel = require("./models/UserCreated.model");
const { matchContract } = require("./evm_base");
const app = express();
const port = process.env.PORT || 5100;

app.use(cors());
app.use(bodyParser.json());

function connectWithRetry() {
  mongoose
    .connect(process.env.MONGO_URI)
    .then(() => {
      console.log("Connected to Database");
    })
    .catch((err) => {
      console.error(
        "Failed to connect to MongoDB, retrying in 5 seconds...",
        err
      );
      setTimeout(connectWithRetry, 5000);
    });
  mongoose.set("debug", process.env.NODE_ENV != "production");
}

connectWithRetry();

app.get("/requests/:buyerAddress", async (req, res) => {
  try {
    const buyers = await RequestModel.find({
      buyerAddress: {
        $regex: new RegExp(`^${req.params.buyerAddress}$`, "i"),
      },
    });

    return res.json(buyers);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

app.get("/offers/:requestId", async (req, res) => {
  try {
    const offers = await OfferModel.find({
      requestId: req.params.requestId,
    });

    return res.json(offers);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});
app.get("/offers/:sellerAddress", async (req, res) => {
  try {
    const offers = await OfferModel.find({
      sellerAddress: req.params.sellerAddress,
    });

    return res.json(offers);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});
app.get("/requestId/:id", async (req, res) => {
  try {
    const request = await RequestModel.find({
      requestId: req.params.id,
    });

    return res.json(request);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

app.post("/requests", async (req, res) => {
  const { sellerLat, sellerLong } = req.body;
  try {
    const requests = await RequestModel.find();
    const availableRequests = [];
    for (let i = 0; i < requests.length; i++) {
      const request = requests[i];
      const { latitude, longitude } = request;
      const isAvailable = isWithinThreshold(
        latitude,
        longitude,
        sellerLat,
        sellerLong,
        threshold
      );
      if (isAvailable) {
        availableRequests.push(request);
      }
    }

    return res.json(availableRequests);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

app.get("/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const userInfo = await UserCreatedModel.findOne({
      userId: userId,
    });

    const userData = await matchContract.methods
      .users(userInfo.userAddress)
      .call();

    return res.json({ ...userData, userAddress: userInfo.userAddress });
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

app.get("/accepted-requests/:sellerAddress", async (req, res) => {
  try {
    const { sellerAddress } = req.params;

    const acceptedRequests = await OfferModel.find({
      sellerAddress: { $regex: new RegExp(`^${sellerAddress}$`, "i") },
    });

    const requestIds = acceptedRequests.map((request) => request.requestId);
    const requests = await RequestModel.find({
      requestId: { $in: requestIds },
    });

    return res.json(requests);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

app.listen(port, () => {
  console.log(`Server is running on port http://localhost:${port}`);
});
