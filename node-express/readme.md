# Node.js + expres によるスタブRESTサーバ
## 初期化
1. 環境構築
    ``` cmd
    npm i
    ```

1. Node.js で空きポートを調べる
    ``` javascript
    /** ポート番号を自動割り当てし、速攻終了する */
    (() => {
        let server = http.createServer();
        let port = 0;
        server.on('listening', () => {
            port = server.address().port;
            server.close();
        });
        server.on('close', () => console.log(port));
        server.on('error', (err) => console.log(err));
        server.listen(port);
    })();
    ```

1. `app.js` の `PORT` を任意の空きポートに変更

## 起動
1. 以下コマンドでサーバ起動
    ``` cmd
    node app.js
    ```

## 動作検証
1. `api.json` の内容が返却されることを確認
    ``` cmd
    curl -X GET http://localhost:8808/api -G -d param=value -H "auth: abc"
    ```

1. ボタン押下後に `redirect.json` で指定したURLにリダイレクトすること
    ```
    http://localhost:8808/page
    ```

## 終了
1. 【ゲスト】 `Ctrl + C` でサーバーを終了する
