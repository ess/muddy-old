#require "lib/triggers.rb"
require 'ncurses'

class UserScripts

  @user_methods = "#{ENV['HOME']}/.muddy/user_methods.rb"
  require @user_methods if File.exist? @user_methods

  def initialize
    @connection = MUDDYCON
    @window = MUDDYWIN
    @triggers = Hash.new
    @user_methods = "#{ENV['HOME']}/.muddy/user_methods.rb"
    self.load_user_methods
  end

  def load_user_methods
    load @user_methods if File.exist? @user_methods
  end

  def reload
    self.load_user_methods
  end
    
  def execute_command(thescript)
    begin
      eval thescript
    rescue Exception => e
      @window.print "%(bold)#{e.class}:#{e.message}%(default)" if @window
    end
  end

  def match_triggers(something)
    @triggers.each do |regexp, command|
      begin
        if something.match(regexp)
          eval command
        end
      rescue RegexpError => e
        @window.print "%(bold white on default)There was a problem with the match."
      end
    end
  end

  def print(something)
    @window.print(something.to_s)
  end

  def echo(something)
    self.print(something)
  end

  def send(something)
    @connection.send(something)
  end

  def quit
    print "%(bold white on default)Look, I'd love to be able to do that, but I can't."
    print "%(bold white on default)Just CTRL-C, please.  I'm begging you."
  end

end
