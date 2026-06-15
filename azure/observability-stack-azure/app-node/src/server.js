import express from "express";

const app = express();
app.use(express.json());

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.get("/api/hello", (req, res) => {
  res.json({ message: "Hello from observability-app", timestamp: new Date() });
});

app.post("/api/echo", (req, res) => {
  res.json({ echoed: req.body, timestamp: new Date() });
});

app.get("/api/error", (req, res) => {
  res.status(500).json({ error: "simulated error" });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Listening on :${PORT}`));
