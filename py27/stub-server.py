import json, sys
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer

class RESTRequestHandler(BaseHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        BaseHTTPRequestHandler.__init__(self, *args, **kwargs)
    
    def do_GET(self):
        try:
            'リクエスト情報'
            print("<request headers>")
            print(self.headers)
            print("</request headers>")

            if self.path is None or self.path == "/":
                raise RuntimeError("path指定なし")

            elif self.path.startswith("/api"):
                'スタブデータ読み込み'
                with open("./data/api.json", mode="r") as f:
                    data = json.load(f)
                body = json.dumps(data).encode("utf-8")

                'ステータスコード設定'
                self.send_response(200)

                'ヘッダー設定'
                self.send_header("Content-type", "application/json")
                self.end_headers()

                'ボディ設定'
                self.wfile.write(body)

            elif self.path.startswith("/redirect"):
                'スタブデータ読み込み'
                with open("./data/redirect.json", mode="r") as f:
                    data = json.load(f)
                redirectUrl = data["redirectUrl"]

                'ステータスコード設定'
                self.send_response(301)

                'ヘッダー設定'
                self.send_header("Location", redirectUrl)
                self.end_headers()

            elif self.path.startswith("/page"):
                'スタブデータ読み込み'
                with open("./data/index.html", mode="rb") as f:
                    'Python2 では ascii がデフォルトであるため、バイナリモードで開いて utf-8 にデコード'
                    data = f.read().decode(encoding="utf-8")
                body = data.encode("utf-8")

                'ステータスコード設定'
                self.send_response(200)

                'ヘッダー設定'
                self.send_header("Content-type", "text/html")
                self.end_headers()

                'ボディ設定'
                self.wfile.write(body)

            else:
                raise RuntimeError("path誤り")
        except Exception as e:
            print(e)

            'ステータスコード設定'
            self.send_response(404)

            'ヘッダー設定'
            self.send_header("Content-type", "application/json")
            self.end_headers()

            'ボディ設定'
            body = json.dumps({}).encode("utf-8")
            self.wfile.write(body)

def run_server(port):
    'サーバー設定'
    http_server = HTTPServer(("", port), RESTRequestHandler)
    print("Running on http://localhost:{} (Ctrl + C to quit)".format(http_server.server_port))

    try:
        'サーバー起動'
        http_server.serve_forever()
    except KeyboardInterrupt:
        'Ctrl + C 押下'
        pass

    'サーバー終了'
    print("Quit server.")
    http_server.server_close()

def main(argv):
    '引数からポート番号取得'
    port = int(argv[0])
    run_server(port)

if __name__ == "__main__":
    main(sys.argv[1:])
