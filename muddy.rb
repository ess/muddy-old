#!/usr/bin/env ruby

require 'lib/connection'
require 'lib/user_scripts'
require 'lib/term/visual'

arg = ARGV
if arg.length < 2
  puts "Try again, sport."
  puts
  puts "muddy.rb host port"
  puts
  exit
else
  @host = ARGV[0]
  @port = ARGV[1]
end

vt = Term::Visual.new

vt.palette.setcolors(
'title'	=> 'red on green',
'foo'		=> 'bold cyan on default',
'bar'		=> 'bold red on blue',
'baz'		=> 'bold green on blue'
)
    
window = vt.create_window('title' => "window", 'bufsize' => 200)
   
window.title = "Muddy"
window.status = "Playing in the MUD"

connection = Connection.new(vt, window,@host,@port)
userscripts = UserScripts.new(connection, window)
connection.setuserscript(userscripts)
x=0
loop do
  if line = vt.getline
    if line.length > 1 and line[0].chr == '/'
      userscripts.execute_command(line[1..line.length])
    else
      window.print line
      connection.send(line)
    end
  end
  sleep 0.0001
end

