const express = require("express");
const mongoose = require("mongoose");
const Article = require("../models/Article");

const router = express.Router();

const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);

router.post("/", async (req, res, next) => {
  try {
    const doc = await Article.create(req.body);
    res.status(201).json(doc);
  } catch (err) {
    if (err.name === "ValidationError") err.status = 400;
    next(err);
  }
});

router.get("/", async (req, res, next) => {
  try {
    const page = Math.max(parseInt(req.query.page || "1", 10), 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit || "20", 10), 1), 100);
    const [items, total] = await Promise.all([
      Article.find().sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit).lean(),
      Article.countDocuments(),
    ]);
    res.json({ page, limit, total, items });
  } catch (err) {
    next(err);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    if (!isValidId(req.params.id)) return res.status(400).json({ error: "invalid id" });
    const doc = await Article.findById(req.params.id).lean();
    if (!doc) return res.status(404).json({ error: "not found" });
    res.json(doc);
  } catch (err) {
    next(err);
  }
});

router.put("/:id", async (req, res, next) => {
  try {
    if (!isValidId(req.params.id)) return res.status(400).json({ error: "invalid id" });
    const doc = await Article.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!doc) return res.status(404).json({ error: "not found" });
    res.json(doc);
  } catch (err) {
    if (err.name === "ValidationError") err.status = 400;
    next(err);
  }
});

router.delete("/:id", async (req, res, next) => {
  try {
    if (!isValidId(req.params.id)) return res.status(400).json({ error: "invalid id" });
    const doc = await Article.findByIdAndDelete(req.params.id);
    if (!doc) return res.status(404).json({ error: "not found" });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

module.exports = router;
