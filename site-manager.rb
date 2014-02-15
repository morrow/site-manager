#!/usr/bin/env ruby

class Manager

  def get_name(name)
    name = name.to_s
    if not name.match /terrencemorrow\.com/
      name = "#{name}.terrencemorrow.com"
    end
    return name
  end 

  def add_site(name, port=nil)
    name = get_name(name)
    return false if get_port_number(name)
    ports = get_ports
    # get new port number from highest existing port number + 1
    port = ports.max_by{ |k,v| k.to_s.gsub("#", "").to_i }[0].to_i + 1 unless port
    # add port and name to ports hash
    ports[port] = name
    # write ports
    write(ports)
    # print port number
    puts "site #{name} added at port #{port}"
    # restart nginx
    puts `sudo /etc/init.d/nginx restart`
  end

  def remove_site(name)
    name = get_name(name)
    port = get_port_number(name)
    return false if not port
    ports = get_ports
    ports.delete(port)
    write(ports)
    %x[rm /etc/nginx/sites-available/#{name}]
    %x[rm /etc/nginx/sites-enabled/#{name}]
    puts "#{name} removed"
  end

  def disable_site(name)
    name = get_name(name)
    port = get_port_number(name)
    return false if not port
    ports = get_ports
    ports.delete(port)
    ports["##{port}"] = name
    write(ports)
    %x[rm /etc/nginx/sites-enabled/#{name}]
  end

  def enable_site(name)
    name = get_name(name)
    port = get_port_number(name)
    return false if not port
    ports = get_ports
    ports.delete("##{port}")
    ports[port] = name
  end

  def write(ports=nil)
    ports = get_ports unless ports
    ports_text = ""
    ports.sort_by{ |k,v| k.to_i }.each do |port, name|
      if name.match /\ \_/
        listen = "443 default_server ssl"
        ssl_include = "include /etc/nginx/ssl_params;" 
      else
        listen = "443 ssl"
        ssl_include = nil
      end
      text = """
# #{name}
server {
  listen #{listen};
  #{ssl_include}
  server_name #{name};
  location / {
    include /etc/nginx/proxy_params;
    proxy_pass http://0.0.0.0:#{port.to_s.gsub('#', '')};
  }
}"""
      File.open("/etc/nginx/sites-available/#{name}", "w+").write(text)
      if not port.to_s.match "#"
        File.symlink("/etc/nginx/sites-available/#{name}", "/etc/nginx/sites-enabled/#{name}") unless File.exists?("/etc/nginx/sites-enabled/#{name}")
      end      
      ports_text += "#{port} #{name}\n"
    end
    File.open("/etc/nginx/ports.txt", "w+").write(ports_text)
  end

  
  def get_ports
    ports = {}
    lines = File.open('/etc/nginx/ports.txt').readlines
    lines.each do |line|
      key = line.split(' ')[0]
      value = line.split(' ')[1..-1].join(' ') if line.split(' ').length > 0
      if key and value
        ports[key] = value
      end
    end
    return ports
  end  

  def get_port_number(name)
    name = get_name(name)
    ports = get_ports
    if ports
      port = ports.index(name.to_s)
      if not port
        port = ports.index("##{name.to_s}")
      end
    end
    port
  end
  
  def get_port_name(number)
    ports = get_ports
    ports[number.to_s] if ports
  end

end
