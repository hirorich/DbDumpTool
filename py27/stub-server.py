import json, sys
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer

class RESTRequestHandler(BaseHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        BaseHTTPRequestHandler.__init__(self, *args, **kwargs)
    
    def do_GET(self):
        try:
            'Request information'
            print("<request path>")
            print(self.path)
            print("")
            print("<request headers>")
            print(self.headers)

            'Load stub data'
            with open('./data/stub.json') as f:
                response = json.load(f)

            'Response data'
            responseBody = json.dumps(response)
            responseData = responseBody.encode('utf-8')

            'success status code'
            self.send_response(200)
        except Exception as e:
            print(e)

            'Response data'
            response = {}
            responseBody = json.dumps(response)
            responseData = responseBody.encode('utf-8')

            'error status code'
            self.send_response(500)
        finally:

            'return json'
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(responseData)

def run_server(port):
    'Starts the REST server'
    http_server = HTTPServer(('', port), RESTRequestHandler)
    print("running server: http://localhost:{}".format(http_server.server_port))
    print("Ctrl + C: close server")

    try:
        http_server.serve_forever()
    except KeyboardInterrupt:
        pass

    print("closing server.")
    http_server.server_close()
    print("server is closed.")


def main(argv):
    run_server(int(argv[0]))

if __name__ == '__main__':
    main(sys.argv[1:])
