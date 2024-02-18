# Python 2.7 によるスタブRESTサーバ
## 空きポート番号調査
1. 【ホスト】Node.js で空きポートを調べる
    ``` javascript
    const http = require("http"); //不要かも

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

1. 【ゲスト】任意のパス(aaa)にファイル配置
    ```
    aaa
        run-stub-server.sh
        stub-server.py
        data
            api.json
            index.html
            redirect.json
    ```

1. 【ゲスト】配置先(aaa)に移動
    ``` cmd
    cd aaa
    ```

1. 【ゲスト】ゲストポートでサーバ起動
    ``` cmd
    py -2.7 -m stub-server 0
    ```

1. 【ゲスト】 `Ctrl + C` でサーバーを終了する

## 事前準備
1. 【ホスト】VirtualBoxのポートフォワード設定を行う
    - 以下が空きポートと仮定
      - プロトコル：TCP
      - ホストポート：9909
      - ゲストポート：8808

1. 【ゲスト】ゲストポートでサーバ起動するよう `run-stub-server.sh` を修正
    ``` cmd
    python -m stub-server 8808
    ```

1. 【ゲスト】 `api.json` に任意のデータを設定

1. 【ゲスト】 `redirect.json` に任意のリダイレクト先を設定

## 起動
1. 【ゲスト】配置先(aaa)に移動
    ``` cmd
    cd aaa
    ```

1. 【ゲスト】ゲストポートでサーバ起動
    ```
    run-stub-server.sh
    ```

## 動作検証
1. 【ホスト】 `api.json` の内容が返却されることを確認
    ``` cmd
    curl -X GET http://localhost:9909/api -G -d param=value -H "auth: abc"
    ```

1. 【ホスト】ボタン押下後に `redirect.json` で指定したURLにリダイレクトすること
    ```
    http://localhost:9909/page
    ```

## 終了
1. 【ゲスト】 `Ctrl + C` でサーバーを終了する
