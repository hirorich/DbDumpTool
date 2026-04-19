const express = require("express");
const fs = require("fs");
const app = express();
const PORT = 8808;

// ==================================================
// JSONファイル読み取り
function loadJsonFile(filepath) {
    return JSON.parse(fs.readFileSync(filepath, "utf8"));
}

// ==================================================
// ログ出力
var logfile;
function openLogFile() {
    if (logfile === undefined) {
        var timestamp = (new Date().toLocaleString()).replace(/ |-|:/g, "");
        logfile = fs.openSync(__dirname + `/log/${timestamp}_log.txt`, "w");
    }
}
function writeLogFile(text) {
    if (text === undefined) return;

    if (typeof text === "object") text = JSON.stringify(text, null, "    ");

    if (logfile !== undefined) {
        fs.writeSync(logfile, text);
        fs.writeSync(logfile, "\n");
    }

    console.log(text);
}
function closeLogFile() {
    if (logfile !== undefined) {
        fs.closeSync(logfile);
        logfile = undefined;
    }
}

// ==================================================
// jsonをpostで受け取る設定
app.use(express.json());
app.use(express.urlencoded({extended: true}));

// 共通の前後処理
app.use("/*", (request, response, next) => {
    try {
        // 前処理
        openLogFile();
        writeLogFile("> request originalUrl");
        writeLogFile(request.originalUrl);
        writeLogFile("> request headers");
        writeLogFile(request.headers);

        // 個別処理
        next();

        // 後処理
        writeLogFile(`[${new Date().toLocaleString()}] "${request.method} ${request.originalUrl} HTTP/${request.httpVersion}" ${response.statusCode} -`);
    } catch(e) {
        console.log(e);
    } finally {
        closeLogFile();
    }
});

// JSON返却
app.get("/api", (request, response) => {
    // リクエストデータ出力
    writeLogFile("> request body");
    writeLogFile(request.body);

    // レスポンスデータ
    var data = loadJsonFile(__dirname + "/data/api.json");
    writeLogFile("> response data");
    writeLogFile(data);

    // 返却
    response.status(200).json(data);
});

// リダイレクト
app.get("/redirect", (request, response) => {
    var data = loadJsonFile(__dirname + "/data/redirect.json");
    response.redirect(301, `${data["redirectUrl"]}`);
});

// html
app.get("/page", (request, response) => {
    response.sendFile(__dirname + "/data/index.html");
});

// サーバ起動
app.listen(PORT, () => {
    console.log(`Running on http://127.0.0.1:${PORT} (Ctrl + C to quit)`);
});
