#!/usr/bin/env ruby

load "/etc/nginx/site-manager.rb"
m = Manager.new
case ARGV[0]
when "add"
  m.add_site ARGV[1]
when "rm"
  m.remove_site ARGV[1]
when "disable"
  m.disable_site ARGV[1]
when "get"
  m.get_port_number ARGV[1]
end
  
