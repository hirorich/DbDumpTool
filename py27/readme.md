# Python 2.7 によるスタブRESTサーバ
## 手順
1. 任意のパス(aaa)にファイル配置
    ```
    aaa
      stub-server.py
      data
        api.json
        redirect.json
    ```

1. `api.json` `redirect.json` に任意のデータを設定

1. 任意のパス(aaa)に移動
    ``` cmd
    cd aaa
    ```

1. 任意のポート番号(8808)でサーバ起動
    ```
    py -2.7 -m stub-server 8808
    ```
    - ポート番号に0を指定すると空いているポートを自動的に使用

1. 起動を確認
    ``` cmd
    curl -X GET http://localhost:8808/api -G -d param=value -H "auth: abc"
    ```
    ``` cmd
    curl -X GET http://localhost:8808/redirect
    ```

1. `Ctrl + C` でサーバーを終了する

## 余談
- VirtualBox上で起動する場合はポートフォワードを行う
