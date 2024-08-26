const Web3 = require("web3");
const fs = require("fs");
const path = require("path");
require("dotenv").config();
const matchABI = JSON.parse(
  fs.readFileSync(path.join(__dirname, "./match.abi.json"), "utf8")
);

// get websocket from aurora api
const web3 = new Web3(process.env.CONTRACT_RPC);
const matchContract = new web3.eth.Contract(
  matchABI,
  process.env.CONTRACT_ADDRESS
);

module.exports = {
  matchContract,
  web3,
};
