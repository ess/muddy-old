require 'ncurses'

class UserScripts

  def initialize
    @connection = MUDDYCON
    @window = MUDDYWIN
    @triggers = Hash.new
    @user_methods = "#{ENV['HOME']}/.muddy/user_methods.rb"
    unless File.exist?(@user_methods)
      print "Creating skeleton user_methods.rb ..."
      skeleton = File.read("#{SCRIPT_DIR}/example/user_methods.rb")
      if(File.open(@user_methods, "w") { |um| um.write(skeleton) })
        print "Skeleton user_methods.rb created."
      end
    end
    self.load_user_methods
  end

  def load_user_methods
    print "Loading User Methods ..."
    if(load @user_methods if File.exist?(@user_methods))
      print "User Methods loaded."
    end
  end

  def reload
    self.load_user_methods
  end

  def help
    print "reload"
    print "     Reloads the user methods defined in your user_methods.rb"
    print " "
    print "print"
    print "     Prints a message, value, what have you to your output window"
    print " "
    print "echo"
    print "     Alias for print"
    print " "
    print "send"
    print "     Send something to the MUD server"
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
    @window.print("%(system)#{something.to_s}%(default)")
  end

  def echo(something)
    self.print(something)
  end

  def send(something)
    @connection.send(something)
  end

  def quit
    print "Look, I'd love to be able to do that, but I can't."
    print "Just CTRL-C, please.  I'm begging you."
  end

end
