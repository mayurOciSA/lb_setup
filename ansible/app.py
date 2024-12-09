from flask import Flask, request, jsonify
import socket

app = Flask(__name__)

# Function to echo the entire request content
def echo_request():
    return jsonify({
        'method': request.method,
        'headers': dict(request.headers),
        'args': request.args,
        'form': request.form,
        'json': request.json if request.is_json else None,  # Ensure JSON data is handled correctly
        'data': request.data.decode('utf-8') if request.data else None,  # Handle raw data properly
        'bk_hs_name': socket.gethostname(),  # Backend server hostname
        'bk_hs_ip': socket.gethostbyname(socket.gethostname())  # Backend server IP address
    })

# Root endpoint to check if the server is running
@app.route('/')
def index():
    return "Hello, this is a test demo application for OCI Layer 4 and Layer 7 Load Balancer!"

# API endpoint to echo the entire request content (for testing Rule Sets)
@app.route('/echo', methods=['GET', 'POST', 'PUT', 'DELETE'])
def echo():
    return echo_request()

# API endpoints for different HTTP methods
@app.route('/get', methods=['GET'])
def get_method():
    return echo_request()

@app.route('/post', methods=['POST'])
def post_method():
    return echo_request()

@app.route('/put', methods=['PUT'])
def put_method():
    return echo_request()

@app.route('/delete', methods=['DELETE'])
def delete_method():
    return echo_request()

# API endpoint to demonstrate path-based routing (Path Route Sets)
@app.route('/api/v1/resource', methods=['GET'])
def api_v1_resource():
    return echo_request()

@app.route('/api/v2/resource', methods=['GET'])
def api_v2_resource():
    return echo_request()

# API endpoint to demonstrate redirection (Rule Sets)
@app.route('/old-path', methods=['GET'])
def old_path():
    response = jsonify({
        'message': 'This path is deprecated. You should be redirected.',
        'request': request.url
    })
    response.status_code = 302
    response.headers['Location'] = '/new-path'
    return response

@app.route('/new-path', methods=['GET'])
def new_path():
    return jsonify({
        'message': 'You have been redirected to the new path!',
        'request': request.url
    })

# API endpoint to show load balancing and session persistence (Policies)
@app.route('/balance', methods=['GET'])
def balance():
    return echo_request()

# API endpoint to demonstrate access control (Rule Sets)
@app.route('/restricted', methods=['GET'])
def restricted():
    allowed_ip = '192.168.1.1'
    client_ip = request.remote_addr
    if client_ip != allowed_ip:
        return jsonify({
            'message': 'Access denied. Your IP address is not allowed.',
            'client_ip': client_ip,
            'request': request.url
        }), 403
    return echo_request()

# API endpoint to demonstrate SSL termination (Layer 4)
@app.route('/ssl', methods=['GET'])
def ssl():
    return echo_request()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)  # Ensure the intended port is correct

# systemctl status python-web-app.service 
# journalctl -u python-web-app.service
