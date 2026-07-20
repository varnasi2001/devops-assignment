const mongoose = require("mongoose");

function buildUri() {
  if (process.env.MONGO_URI) return process.env.MONGO_URI;
  const host = process.env.MONGO_HOST || "mongodb-headless";
  const port = process.env.MONGO_PORT || "27017";
  const rs = process.env.MONGO_REPLICA_SET || "rs0";
  const db = process.env.MONGO_DB || "articles";
  const user = process.env.MONGO_USER;
  const pass = process.env.MONGO_PASSWORD;
  const replicas = parseInt(process.env.MONGO_REPLICAS || "3", 10);
  const seeds = Array.from({ length: replicas }, (_, i) => `mongodb-${i}.${host}:${port}`).join(",");
  const auth = user ? `${encodeURIComponent(user)}:${encodeURIComponent(pass || "")}@` : "";
  return `mongodb://${auth}${seeds}/${db}?replicaSet=${rs}&authSource=admin`;
}

async function connect() {
  const uri = buildUri();
  console.log("connecting to mongo:", uri.replace(/\/\/[^@]*@/, "//***@"));
  mongoose.set("strictQuery", true);
  await mongoose.connect(uri, {
    serverSelectionTimeoutMS: 10000,
    heartbeatFrequencyMS: 5000,
  });
  console.log("mongo connected");
}

module.exports = { connect };
