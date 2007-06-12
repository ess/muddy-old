require 'socket'

class Connection

  def initialize(thevt,thewindow, host, port)
    @fgcolor = "default"
    @bgcolor = "default"
    @vt = thevt
    @window = thewindow
    @host = host
    @port = port
    @socket = TCPSocket.open(host, port) if host && port
    @window.status = "Connected to #{host}:#{port}"
    @temp = @showBuffer = ""
    @listener = Thread.new do
      begin
        listen
      rescue Exception => e
        @window.print "#{e.class}:#{e.message}"
      end
    end if @socket
  end

  def setuserscript(userscript)
    @userscript = userscript
  end

  def close
    if Thread.current != @listener && @listener && @listener.alive?
      @listener.kill
    end
    if @socket && !@socket.closed?
      @socket.close if @socket
    end
  end

  def listen
    c = true
    while c
      while select([@socket],nil,nil,1) && c = getc
        handle(c)
      end
      display_buffer
    end
  end


  def display_buffer
    unless @showBuffer.empty?
      #logfile = File.open("logfile.txt", "a")
      @showBuffer.gsub(/\[0m/, "")
      @window.print(*@showBuffer )
      #logfile.print(*@showBuffer)
      #logfile.close
    end
    @showBuffer = ""
  end
 
  def manage_buffer(c)
    if c == 10 or c == 0 or c == 13
      temp = @showBuffer.gsub(/\%\(([a-z]|[A-Z]| )+\)/,'').gsub(/ +/,' ')
      @userscript.match_triggers(temp)
      display_buffer
      #@showBuffer = insert_style(@fgcolor, @bgcolor)
    end
  end

  def getc
    @socket.getc
  end

  def handle(c)
    #
    # The telnet support (just so we dont explode or something)
    #
    # We are just plain ignoring it atm.
    #
    ansiString = ""
    if c == 255 # telnet interpret as command (IAC)
      c = getc # get the request (DO|DONT)
      c = getc # get the latest part whatever that is
    elsif c == 27 # escape char! this is probably some ANSI color or shite
      c = getc
      if c.chr == "[" # this is an ansi-something that is more than one char long
        ansiString = ""
        while !"cnRhl()HABCfsurhgKJipm".include?((c = getc).chr)
          ansiString << c.chr
        end
        if ansiString == "0m"
          @window.print "I caught that son of a bitch!"
        end
        if c.chr == "m" && Ncurses.has_colors? # ah, text property! i understand this!
          properties = ansiString.split(";")
          attributes = 0
          bgcolor = false
          fgcolor = false
          reset = properties.index("0")
          if reset
            properties.delete("0")
          end
          properties.each do |property|
            case property.to_i
            when 1
              attributes = attributes | Ncurses.const_get("A_BOLD")
            when 2
              attributes = attributes | Ncurses.const_get("A_DIM")
            when 4
              attributes = attributes | Ncurses.const_get("A_UNDERLINE")
            when 5
              attributes = attributes | Ncurses.const_get("A_BLINK") unless conf.disable_blink
            when 7
              attributes = attributes | Ncurses.const_get("A_REVERSE")
            when 8
              attributes = attributes | Ncurses.const_get("A_INVIS")
            when 30
              fgcolor = "black" # Ncurses.const_get("COLOR_BLACK")
            when 31
              fgcolor = "red" # Ncurses.const_get("COLOR_RED")
            when 32
              fgcolor = "green" #Ncurses.const_get("COLOR_GREEN")
            when 33
              fgcolor = "yellow" #Ncurses.const_get("COLOR_YELLOW")
            when 34
              fgcolor = "blue" #Ncurses.const_get("COLOR_BLUE")
            when 35
              fgcolor = "magenta" #Ncurses.const_get("COLOR_MAGENTA")
            when 36
              fgcolor = "cyan" #Ncurses.const_get("COLOR_CYAN")
            when 37
              fgcolor = "white" #Ncurses.const_get("COLOR_WHITE")
            when 40
              bgcolor = "black" #Ncurses.const_get("COLOR_BLACK")
            when 41
              bgcolor = "red" #Ncurses.const_get("COLOR_RED")
            when 42
              bgcolor = "green" #Ncurses.const_get("COLOR_GREEN")
            when 43
              bgcolor = "yellow" #Ncurses.const_get("COLOR_YELLOW")
            when 44
              bgcolor = "blue" #Ncurses.const_get("COLOR_BLUE")
            when 45
              bgcolor = "magenta" #Ncurses.const_get("COLOR_MAGENTA")
            when 46
              bgcolor = "cyan" #Ncurses.const_get("COLOR_CYAN")
            when 47
              bgcolor = "white" #Ncurses.const_get("COLOR_WHITE")
            end
          end
          if reset
            #@fgcolor = @bgcolor = 'default'
            insert_style('default')
  #          @showBuffer << "%(default)"
          else
            @vt.palette.setcolor("#{fgcolor} on #{bgcolor ? bgcolor : 'default'}", "#{fgcolor} on #{bgcolor ? bgcolor : 'default'}" )
            @fgcolor = fgcolor
            @bgcolor = bgcolor ? bgcolor : 'default'
            insert_style(@fgcolor, @bgcolor)
   #         @showBuffer << "%(#{fgcolor} on #{bgcolor ? bgcolor : 'default'})"
          end
        end
      end
      else #if ! conf.broken_keycodes.include?(c)
      #
      # This is not telnet command OR ansi, lets treat it as nice MUD text!
      #
      # Debug about it, add it to match buffer, add it to show buffer and show if we want to show.
      # Then check it for triggers.
      #
      #@matchBuffer = @matchBuffer + c.chr
      #append_show_buffer(c.chr)
      #manage_buffers(c)
      
      #unless @fgcolor == 'default' or c.chr =~ /(\n| )/
      #  value = "%(#{@fgcolor} on #{@bgcolor ? @bgcolor : 'default'})" + c.chr
      #else
        value = c.chr
      #end
      @showBuffer << value unless [10, 0, 13].include? c
      manage_buffer(c)
    end
  end

  def insert_style(fgcolor, bgcolor = 'default')
    if fgcolor == bgcolor and bgcolor == 'default'
      @showBuffer << "%(default)"
    else
      @showBuffer << "%(#{@fgcolor} on #{@bgcolor})"
    end
  end

  def send(s)
    @socket.puts(s) if @socket
  end
end
