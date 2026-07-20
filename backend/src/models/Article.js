const mongoose = require("mongoose");

const articleSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 200 },
    body: { type: String, required: true },
    author: { type: String, trim: true, maxlength: 100 },
    tags: [{ type: String, trim: true }],
  },
  { timestamps: true, versionKey: false }
);

module.exports = mongoose.model("Article", articleSchema);
