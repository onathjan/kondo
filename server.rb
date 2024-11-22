require 'webrick'

root = File.expand_path 'site'

server = WEBrick::HTTPServer.new(Port: 8000, DocumentRoot: root)

# Handler for serving styles.css
server.mount('/assets/styles.css', WEBrick::HTTPServlet::FileHandler, File.join(root, 'assets', 'styles.css'))

# Custom handler to serve all files as text/html
server.mount_proc '/' do |req, res|
  path = req.path == '/' ? 'index.html' : req.path[1..-1]  # Convert clean URLs to filenames
  file_path = File.join(root, path)

  if File.file?(file_path) && File.readable?(file_path)
    res['Content-Type'] = 'text/html'
    res.body = File.read(file_path)
  else
    res.status = 404
    res.body = 'File not found'
  end
end

trap 'INT' do server.shutdown end

puts "WEBrick server is running at http://localhost:8000/"
server.start
