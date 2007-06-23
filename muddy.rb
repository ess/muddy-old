#!/usr/bin/env ruby
SCRIPT_DIR = File.expand_path(File.dirname(__FILE__))
DOT_MUDDY = "#{ENV['HOME']}/.muddy"
$: << SCRIPT_DIR

Dir.mkdir DOT_MUDDY unless File.exist? DOT_MUDDY

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
                           :filename => "#{DOT_MUDDY}/logs/log-#{Time.now.to_i}",
                           :trunc => true,
                           :level => Log4r::DEBUG)
  Log.add('log')

  Log.debug "Muddy started at #{Time.now.to_s}."
end

MUDDYVT = Term::Visual.new

MUDDYVT.palette.setcolors(
'title'	=> 'red on green',
'input'	=> 'bold cyan on default',
'system' => 'bold green on default'
)
    
MUDDYWIN = MUDDYVT.create_window('title' => "window", 'bufsize' => 200)
   
MUDDYWIN.title = "Muddy"
MUDDYWIN.status = "Playing in the MUD"

MUDDYCON = Connection.new(@host,@port)
MUDDYSCRIPTS = UserScripts.new

x=0
loop do
  if line = MUDDYVT.getline
    if line.length > 1 and line[0].chr == '/'
      MUDDYSCRIPTS.execute_command(line[1..line.length])
    else
      MUDDYWIN.print "%(input)#{line}%(default)"
      MUDDYCON.send(line)
    end
  end
  sleep 0.0001
end

