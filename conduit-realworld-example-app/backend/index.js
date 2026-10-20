require("dotenv").config();
const env = process.env.NODE_ENV || "development";
const PORT = process.env.PORT || 3001;
const express = require("express");
const cors = require("cors");
const { sequelize } = require("./models");
const errorHandler = require("./middleware/errorHandler");
const originVerify = require("./middleware/originVerify");

const usersRoutes = require("./routes/users");
const userRoutes = require("./routes/user");
const articlesRoutes = require("./routes/articles");
const profilesRoutes = require("./routes/profiles");
const tagsRoutes = require("./routes/tags");

const corsOrigin = process.env.CORS_ORIGIN?.split(",").map((o) => o.trim());

const app = express();
app.use(cors(corsOrigin ? { origin: corsOrigin } : undefined));
app.use(express.json());

(async () => {
  try {
    // Schema changes in deployed environments go through migrations
    if (process.env.DB_SYNC === "true") {
      await sequelize.sync({ alter: true });
    } else {
      await sequelize.authenticate();
    }
    console.log(`Connection with ${env} database has been established.`);
  } catch (error) {
    console.error("Unable to connect to the database:", error);
  }
})();

app.get("/", (req, res) => res.json({ status: "API is running on /api" }));
app.get("/health", (req, res) => res.json({ status: "ok" }));

app.use("/api", originVerify);
app.use("/api/users", usersRoutes);
app.use("/api/user", userRoutes);
app.use("/api/articles", articlesRoutes);
app.use("/api/profiles", profilesRoutes);
app.use("/api/tags", tagsRoutes);
app.get("/*any", (req, res) =>
  res.status(404).json({ errors: { body: ["Not found"] } }),
);
app.use(errorHandler);

app.listen(PORT, () =>
  console.log(`Server running on http://localhost:${PORT}`),
);
