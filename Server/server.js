const express = require("express");
const rateLimit = require("express-rate-limit");
const app = express();
const mongoose = require("mongoose");
const watchlist = require("./models/watchlist");
const portfolio = require("./models/portfolio");
const wallet = require("./models/wallet");
const { ObjectId } = require("mongodb");
const PORT = 8080;
const path = require("path");

const uri = process.env.MONGODB_URI;
const finnhubAPIKey = process.env.FINNHUB_API_KEY;
const polygonAPIKey = process.env.POLYGON_API_KEY;
accObjId = process.env.ACCOUNT_OBJECT_ID;
if (!uri || !finnhubAPIKey || !polygonAPIKey || !accObjId) {
  console.error(
    "Missing MONGODB_URI, FINNHUB_API_KEY, POLYGON_API_KEY, or ACCOUNT_OBJECT_ID",
  );
  process.exit(1);
}

mongoose.connect(uri);

const db = mongoose.connection;
db.on("error", (err) => {
  console.error("Database connection failed");
});

app.listen(PORT, () => console.log("Server running on port", PORT));


//To allow CORS
var corsMiddleware = function (req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header(
    "Access-Control-Allow-Methods",
    "OPTIONS, GET, PUT, PATCH, POST, DELETE"
  );
  res.header(
    "Access-Control-Allow-Headers",
    "Content-Type, X-Requested-With, Authorization"
  );

  next();
};

app.use(corsMiddleware);
app.use(express.json());
app.use(
  rateLimit({
    windowMs: 60 * 1000,
    max: 60,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);

function isSymbol(value) {
  return typeof value === "string" && /^[A-Za-z0-9.]{1,12}$/.test(value);
}

function isEpoch(value) {
  return typeof value === "string" && /^[0-9]{10,13}$/.test(value);
}


app.get("/api/ping", async (req, res) => {
  res.json({ Res: "Pong" });
});

app.get("/api/profile/:ticker", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  const url = new URL("https://finnhub.io/api/v1/stock/profile2");
  url.searchParams.set("symbol", ticker);
  url.searchParams.set("token", finnhubAPIKey);
  if (url.hostname !== "finnhub.io") {
    return res.status(400).json({ response: "", err: "Invalid request" });
  }
  try {
    let profile = await fetch(url);
    let profileJson = await profile.json();
    res.json(profileJson);
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/historical/:ticker", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  var fromDate = Math.floor(Date.now() - 24 * 30 * 24 * 60 * 60 * 1000);
  var now = Math.floor(Date.now());
  const url = new URL(
    "https://api.polygon.io/v2/aggs/ticker/" +
      ticker +
      "/range/1/day/" +
      fromDate +
      "/" +
      now,
  );
  url.searchParams.set("adjusted", "true");
  url.searchParams.set("sort", "asc");
  url.searchParams.set("apiKey", polygonAPIKey);
  if (url.hostname !== "api.polygon.io") {
    return res.status(400).json({ response: "", err: "Invalid request" });
  }
  try {
    let historical = await fetch(url);
    let historicalJson = await historical.json();
    res.json(historicalJson);
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/historical/:ticker/:fromDate/:toDate", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  let fromDate = req.params.fromDate;
  let toDate = req.params.toDate;
  if (!isEpoch(fromDate) || !isEpoch(toDate)) {
    return res.status(400).json({ response: "", err: "Invalid date" });
  }
  const url = new URL(
    "https://api.polygon.io/v2/aggs/ticker/" +
      ticker +
      "/range/1/hour/" +
      fromDate +
      "/" +
      toDate,
  );
  url.searchParams.set("adjusted", "true");
  url.searchParams.set("sort", "asc");
  url.searchParams.set("apiKey", polygonAPIKey);
  if (url.hostname !== "api.polygon.io") {
    return res.status(400).json({ response: "", err: "Invalid request" });
  }
  try {
    let historical = await fetch(url);
    let historicalJson = await historical.json();
    res.json(historicalJson);
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/quote/:ticker", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  const url = new URL("https://finnhub.io/api/v1/quote");
  url.searchParams.set("symbol", ticker);
  url.searchParams.set("token", finnhubAPIKey);
  if (url.hostname !== "finnhub.io") {
    return res.status(400).json({ response: "", err: "Invalid request" });
  }
  try {
    let quote = await fetch(url);
    let quoteJson = await quote.json();
    res.json(quoteJson);
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/search/:ticker", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  console.log(ticker);
  const url = new URL("https://finnhub.io/api/v1/search");
  url.searchParams.set("q", ticker);
  url.searchParams.set("token", finnhubAPIKey);
  if (url.hostname !== "finnhub.io") {
    return res.status(400).json({ response: "", err: "Invalid request" });
  }

  try {
    let search = await fetch(url);
    let searchJson = await search.json();
    let filteredResults = searchJson.result.filter(
      (item) => item.type === "Common Stock"
    );

    let filterdot = filteredResults.filter((item) => {
      if (!item.symbol.includes(".")) {
        return true;
      }
    });
    let mappedResults = filterdot.map((item) => ({
      symbol: item.symbol,
      description: item.description,
    }));
    console.log(mappedResults);
    res.json(mappedResults);
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/news/:ticker", async (req, res) => {
  const currentDate = new Date(Date.now());
  const sevenDaysAgo = new Date(
    currentDate.getTime() - 7 * 24 * 60 * 60 * 1000
  );

  const formatDate = (date) => {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  };

  const formattedTo = formatDate(currentDate);
  const formattedFrom = formatDate(sevenDaysAgo);

  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  const url = new URL("https://finnhub.io/api/v1/company-news");
  url.searchParams.set("symbol", ticker);
  url.searchParams.set("from", formattedFrom);
  url.searchParams.set("to", formattedTo);
  url.searchParams.set("token", finnhubAPIKey);
  if (url.hostname !== "finnhub.io") {
    return res.status(400).json({ response: "", err: "Invalid request" });
  }
  try {
    let news = await fetch(url);
    let newsJson = await news.json();
    let filteredNews = newsJson.filter(
      (article) =>
        article.image && article.datetime && article.headline && article.url
    );

    let newArr = [];
    for (let i = 0; i < filteredNews.length && newArr.length < 20; i++) {
      newArr.push(filteredNews[i]);
    }
    res.json(newArr);
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/recommendations/:ticker", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  const url = new URL("https://finnhub.io/api/v1/stock/recommendation");
  url.searchParams.set("symbol", ticker);
  url.searchParams.set("token", finnhubAPIKey);
  if (url.hostname !== "finnhub.io") {
    return res.status(400).json({ response: "", err: "Invalid request" });
  }
  try {
    let rec = await fetch(url);
    let recJson = await rec.json();
    res.json(recJson);
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/sentiments/:ticker", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  const url = new URL("https://finnhub.io/api/v1/stock/insider-sentiment");
  url.searchParams.set("symbol", ticker);
  url.searchParams.set("from", "2022-01-01");
  url.searchParams.set("token", finnhubAPIKey);
  if (url.hostname !== "finnhub.io") {
    return res.status(400).json({ response: "", err: "Invalid request" });
  }
  try {
    let sentiments = await fetch(url);
    let sentimentsJson = await sentiments.json();

    let positiveMsprSum = 0;
    let negativeMsprSum = 0;
    let totalMsprSum = 0;
    let positiveChangeSum = 0;
    let negativeChangeSum = 0;
    let totalChangeSum = 0;

    sentimentsJson.data.forEach((sentiment) => {
      totalMsprSum += sentiment.mspr;
      totalChangeSum += sentiment.change;
      if (sentiment.mspr > 0) {
        positiveMsprSum += sentiment.mspr;
      } else if (sentiment.mspr < 0) {
        negativeMsprSum += sentiment.mspr;
      }
      if (sentiment.change > 0) {
        positiveChangeSum += sentiment.change;
      } else if (sentiment.change < 0) {
        negativeChangeSum += sentiment.change;
      }
    });
    console.log({
      symbol: ticker,
      positiveMsprSum: positiveMsprSum,
      negativeMsprSum: negativeMsprSum,
      totalMsprSum: totalMsprSum,
      positiveChangeSum: positiveChangeSum,
      negativeChangeSum: negativeChangeSum,
      totalChangeSum: totalChangeSum,
    });
    res.json({
      symbol: ticker,
      positiveMsprSum: positiveMsprSum,
      negativeMsprSum: negativeMsprSum,
      totalMsprSum: totalMsprSum,
      positiveChangeSum: positiveChangeSum,
      negativeChangeSum: negativeChangeSum,
      totalChangeSum: totalChangeSum,
    });
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/peers/:ticker", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  const url = new URL("https://finnhub.io/api/v1/stock/peers");
  url.searchParams.set("symbol", ticker);
  url.searchParams.set("token", finnhubAPIKey);
  if (url.hostname !== "finnhub.io") {
    return res.status(400).json({ response: "", err: "Invalid request" });
  }
  try {
    let peers = await fetch(url);
    let peersJson = await peers.json();
    res.json(peersJson);
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/earnings/:ticker", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  const url = new URL("https://finnhub.io/api/v1/stock/earnings");
  url.searchParams.set("symbol", ticker);
  url.searchParams.set("token", finnhubAPIKey);
  if (url.hostname !== "finnhub.io") {
    return res.status(400).json({ response: "", err: "Invalid request" });
  }
  try {
    let earnings = await fetch(url);
    let earningsJson = await earnings.json();
    res.json(earningsJson);
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.post("/api/watchlist/", async (req, res) => {
  let { ticker, name } = req.body;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  let watchlistItem = new watchlist({ Ticker: ticker, Name: name });
  try {
    await watchlistItem.save();
    res.json({ response: "Success", err: "" });
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.delete("/api/watchlist/:ticker", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  try {
    await watchlist.deleteOne({ Ticker: ticker });
    res.json({ response: "Success", err: "" });
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/watchlist/:ticker", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }

  try {
    let watchlistItem = await watchlist.findOne({ Ticker: ticker });
    if (watchlistItem) {
      res.json({ response: true, err: "" });
    } else {
      res.json({ response: false, err: "" });
    }
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/watchlist", async (req, res) => {
  try {
    let watchlistItems = await watchlist.find();
    res.json(watchlistItems);
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/portfolio", async (req, res) => {
  try {
    let portfolioItems = await portfolio.find();
    res.json(portfolioItems);
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.post("/api/portfolio/buy", async (req, res) => {
  let { Ticker, Name, Qty, AvgPrice } = req.body;
  if (!isSymbol(Ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  let currWallet = await wallet.findOne({ _id: accObjId });
  let currentAmount = currWallet.Amount;
  let newAmount = currentAmount - AvgPrice * Qty;
  if (currWallet.Amount < AvgPrice * Qty) {
    res.status(500).json({ response: "", err: "Insufficient Funds" });
  } else {
    let existingPortfolioItem = await portfolio.findOne({ Ticker });
    if (existingPortfolioItem) {
      try {
        await portfolio.updateOne(
          { Ticker },
          {
            $set: {
              Qty: existingPortfolioItem.Qty + Qty,
              AvgPrice:
                (existingPortfolioItem.AvgPrice * existingPortfolioItem.Qty +
                  AvgPrice * Qty) /
                (existingPortfolioItem.Qty + Qty),
            },
          }
        );
        await wallet.updateOne(
          { _id: accObjId },
          {
            $set: { Amount: newAmount },
          }
        );
        res.json({ response: "Success", err: "" });
      } catch (e) {
        res.status(500).json({ response: "", err: "Request failed" });
      }
    } else {
      let portfolioItem = new portfolio({ Ticker, Name, Qty, AvgPrice });
      try {
        await portfolioItem.save();
        await wallet.updateOne(
          { _id: accObjId },
          {
            $set: { Amount: newAmount },
          }
        );
        res.json({ response: "Success", err: "" });
      } catch (e) {
        res.status(500).json({ response: "", err: "Request failed" });
      }
    }
  }
});

app.post("/api/portfolio/sell", async (req, res) => {
  let { Ticker, Qty, currPrice } = req.body;
  if (!isSymbol(Ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  let existingPortfolioItem = await portfolio.findOne({ Ticker });
  if (existingPortfolioItem) {
    if (existingPortfolioItem.Qty - Qty < 0) {
      res.status(500).json({ response: "", err: "Insufficient Quantity" });
    } else {
      if (existingPortfolioItem.Qty - Qty === 0) {
        try {
          await portfolio.deleteOne({ Ticker });
          res.json({ response: "Success", err: "" });
        } catch (e) {
          res.status(500).json({ response: "", err: "Request failed" });
        }
        await wallet.updateOne(
          { _id: accObjId },
          {
            $inc: { Amount: currPrice * Qty },
          }
        );
      } else {
        try {
          await portfolio.updateOne(
            { Ticker },
            {
              $set: {
                Qty: existingPortfolioItem.Qty - Qty,
              },
            }
          );
          await wallet.updateOne(
            { _id: accObjId },
            {
              $inc: { Amount: currPrice * Qty },
            }
          );

          res.json({ response: "Success", err: "" });
        } catch (e) {
          res.status(500).json({ response: "", err: "Request failed" });
        }
      }
    }
  } else {
    res.status(500).json({ response: "", err: "Item not found" });
  }
});

app.get("/api/wallet", async (req, res) => {
  try {
    let amount = await wallet.find();
    res.json({ response: amount[0], err: "" });
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.get("/api/portfolio/:ticker", async (req, res) => {
  let ticker = req.params.ticker;
  if (!isSymbol(ticker)) {
    return res.status(400).json({ response: "", err: "Invalid symbol" });
  }
  try {
    let amount = await portfolio.findOne({
      Ticker: ticker,
    });
    if (amount) {
      // let newRes = { ...amount, exist: true };
      // res.json({ response: newRes, err: "" });
      res.json(amount._doc);
    } else {
      let newRes = { exist: false };
      res.json({ response: newRes, err: "" });
    }
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

app.put("/api/wallet/deposit", async (req, res) => {
  let { amount } = req.body;
  try {
    let existingWallet = await wallet.findOne();
    if (existingWallet) {
      await wallet.updateOne({}, { $set: { Amount: amount } });
    } else {
      let newAmount = new wallet({ Amount: amount });
      await newAmount.save();
    }
    res.json({ response: "Success", err: "" });
  } catch (e) {
    res.status(500).json({ response: "", err: "Request failed" });
  }
});

// Catch-all handler for undefined routes
app.use((req, res) => {
  res.status(404).json({ error: "Route not found" });
});
