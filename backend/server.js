require("dotenv").config();
const express = require("express");
const pool = require("./db"); // Imports and runs connection test

const app = express();
const PORT = process.env.PORT || 5000;

app.use(express.json());

// Test route
app.get("/", (req, res) => {
  res.json({ message: "SwasthyaSathi Backend is running!" });
});

// Example database route
app.get("/db-test", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");
    res.json({ time: result.rows[0].now });
  } catch (err) {
    console.error(err);
    res.status(500).send("Database error");
  }
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});