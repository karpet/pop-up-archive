object false

cur_url = request.protocol + request.host
if request.port != 80 and request.protocol == 'http://'
  cur_url += ':' + request.port.to_s
end 
if request.port != 443 and request.protocol == 'https://'
  cur_url += ':' + request.port.to_s
end

node(:version) { '1.0' }
node(:url) { "#{cur_url}/api/" }
