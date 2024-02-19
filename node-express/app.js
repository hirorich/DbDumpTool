const express = require("express");
const app = express();
const PORT = 8808;

// 共通の前後処理
app.use("/*", (request, response, next) => {
    // 前処理
    console.log("> request originalUrl");
    console.log(request.originalUrl);
    console.log("> request headers");
    console.log(request.headers);

    // 個別処理
    next();

    // 後処理
    console.log(`[${new Date().toLocaleString()}] "${request.method} ${request.originalUrl} HTTP/${request.httpVersion}" ${response.statusCode} -`);
});

// JSON返却
app.get("/api", (request, response) => {
    var data = require(__dirname + "/data/api.json");
    response.json(data);
});

// リダイレクト
app.get("/redirect", (request, response) => {
    var data = require(__dirname + "/data/redirect.json");
    response.redirect(301, data["redirectUrl"]);
});

// html
app.get("/page", (request, response) => {
    response.sendFile(__dirname + "/data/index.html");
});

// サーバ起動
app.listen(PORT, () => {
    console.log(`Running on http://127.0.0.1:${PORT} (Ctrl + C to quit)`);
});
