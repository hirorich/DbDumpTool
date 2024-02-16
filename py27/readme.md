# Python 2.7 によるスタブRESTサーバ
## 手順
1. 任意のパス(aaa)にファイル配置
    ```
    aaa
      stub-server.py
      data
        stub.json
    ```
1. `stub.json` に任意のデータを設定
1. 任意のパス(aaa)に移動
    ``` cmd
    cd aaa
    ```
1. 任意のポート番号(8808)でサーバ起動
    ```
    py -2.7 -m stub-server 8808
    ```
1. 起動を確認
    ``` cmd
    curl -X GET http://localhost:8808/aaa/ccc -G -d param=value -H "auth: abc"
    ```

## 余談
- ポート番号に0を指定すると空いているポートを自動的に使用
- VirtualBox上で起動する場合はポートフォワードを行う
