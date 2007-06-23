#!/usr/bin/env ruby
SCRIPT_DIR = File.expand_path(File.dirname(__FILE__))
$: << SCRIPT_DIR

require 'lib/connection'
require 'lib/user_scripts'
require 'lib/term/visual'

arg = ARGV
DEBUG = nil
if arg.length < 2
  puts "Try again, sport."
  puts
  puts "muddy.rb (-debug) host port"
  puts
  exit
else
  if arg.length == 3
    require 'log4r'
    DEBUG = arg.shift
  end
  @host = ARGV[0]
  @port = ARGV[1]
end

unless DEBUG.nil?
  Log = Log4r::Logger.new("mylogger")
  Log4r::FileOutputter.new('log', 
                           :filename => "#{SCRIPT_DIR}/logs/log-#{Time.now.to_i}",
                           :trunc => true,
                           :level => Log4r::DEBUG)
  Log.add('log')

  Log.debug "Muddy started at #{Time.now.to_s}."
end

vt = Term::Visual.new

vt.palette.setcolors(
'title'	=> 'red on green',
'input'	=> 'bold cyan on default'
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
      window.print "%(input)#{line}%(default)"
      connection.send(line)
    end
  end
  sleep 0.0001
end

