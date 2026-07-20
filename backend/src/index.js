const express = require("express");
const morgan = require("morgan");
const promClient = require("prom-client");
const { connect } = require("./db");
const articlesRouter = require("./routes/articles");

const PORT = parseInt(process.env.PORT || "3000", 10);
const app = express();

app.use(express.json({ limit: "1mb" }));
app.use(morgan("combined"));

const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });
const httpDuration = new promClient.Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request duration",
  labelNames: ["method", "route", "code"],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
});
register.registerMetric(httpDuration);

app.use((req, res, next) => {
  const end = httpDuration.startTimer();
  res.on("finish", () => {
    end({ method: req.method, route: req.route?.path || req.path, code: res.statusCode });
  });
  next();
});

app.get("/healthz", (_req, res) => res.json({ status: "ok" }));
app.get("/readyz", (_req, res) => {
  const state = require("mongoose").connection.readyState;
  return state === 1 ? res.json({ status: "ready" }) : res.status(503).json({ status: "not-ready", mongoState: state });
});
app.get("/metrics", async (_req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});

app.use("/articles", articlesRouter);

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(err.status || 500).json({ error: err.message || "internal error" });
});

connect()
  .then(() => {
    app.listen(PORT, () => console.log(`articles-api listening on :${PORT}`));
  })
  .catch((err) => {
    console.error("failed to connect to mongo:", err);
    process.exit(1);
  });
