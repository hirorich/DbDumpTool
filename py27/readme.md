# Python 2.7 によるスタブRESTサーバ
## 事前準備
1. 【ホスト】VirtualBoxのポートフォワードを行う
    - プロトコル：TCP
    - ホストポート：9909
    - ゲストポート：8808

1. 【ホスト】 `api.json` に任意のデータを設定

1. 【ホスト】 `redirect.json` に任意のリダイレクト先を設定

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

## 起動
1. 【ゲスト】任意のパス(aaa)に移動
    ``` cmd
    cd aaa
    ```

1. 【ゲスト】ゲストポートでサーバ起動
    ```
    py -2.7 -m stub-server 8808
    ```
    - ポート番号に0を指定すると空いているポートを自動的に使用

    ```
    run-stub-server.sh
    ```
    - ポートが決まっている場合は shell からの起動も可能

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
