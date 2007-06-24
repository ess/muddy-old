require 'socket'

class Connection

  def initialize(host, port)
    @textattr = ""
    @fgcolor = "default"
    @bgcolor = "default"
    @vt = MUDDYVT
    @window = MUDDYWIN
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
      @showBuffer.gsub(/\[0m/, "")
      @window.print(*@showBuffer )
    end
    @showBuffer = ""
  end
 
  def manage_buffer(c)
    if c == 10 or c == 0 or c == 13
      temp = @showBuffer.gsub(/\%\(([a-z]|[A-Z]| )+\)/,'').gsub(/ +/,' ')
      MUDDYSCRIPTS.match_triggers(temp)
      display_buffer
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
              @textattr = "bold" #attributes = attributes | Ncurses.const_get("A_BOLD")
            when 2
              @textattr = "dim" #attributes = attributes | Ncurses.const_get("A_DIM")
            when 4
              @textattr = "underline" #attributes = attributes | Ncurses.const_get("A_UNDERLINE")
            when 5
              @textattr = "blink" #attributes = attributes | Ncurses.const_get("A_BLINK") unless conf.disable_blink
            when 7
              @textattr = "reverse" #attributes = attributes | Ncurses.const_get("A_REVERSE")
            when 8
              @textattr = "invisible" #attributes = attributes | Ncurses.const_get("A_INVIS")
            when 30
              @fgcolor = "black" # Ncurses.const_get("COLOR_BLACK")
            when 31
              @fgcolor = "red" # Ncurses.const_get("COLOR_RED")
            when 32
              @fgcolor = "green" #Ncurses.const_get("COLOR_GREEN")
            when 33
              @fgcolor = "yellow" #Ncurses.const_get("COLOR_YELLOW")
            when 34
              @fgcolor = "blue" #Ncurses.const_get("COLOR_BLUE")
            when 35
              @fgcolor = "magenta" #Ncurses.const_get("COLOR_MAGENTA")
            when 36
              @fgcolor = "cyan" #Ncurses.const_get("COLOR_CYAN")
            when 37
              @fgcolor = "white" #Ncurses.const_get("COLOR_WHITE")
            when 40
              @bgcolor = "black" #Ncurses.const_get("COLOR_BLACK")
            when 41
              @bgcolor = "red" #Ncurses.const_get("COLOR_RED")
            when 42
              @bgcolor = "green" #Ncurses.const_get("COLOR_GREEN")
            when 43
              @bgcolor = "yellow" #Ncurses.const_get("COLOR_YELLOW")
            when 44
              @bgcolor = "blue" #Ncurses.const_get("COLOR_BLUE")
            when 45
              @bgcolor = "magenta" #Ncurses.const_get("COLOR_MAGENTA")
            when 46
              @bgcolor = "cyan" #Ncurses.const_get("COLOR_CYAN")
            when 47
              @bgcolor = "white" #Ncurses.const_get("COLOR_WHITE")
            end
          end
          if reset
            @fgcolor = @bgcolor = 'default'
            @textattr = ""
            insert_style()
  #          @showBuffer << "%(default)"
          else
            insert_style
   #         @showBuffer << "%(#{fgcolor} on #{bgcolor ? bgcolor : 'default'})"
          end
        end
      end
      else #if ! conf.broken_keycodes.include?(c)
        value = c.chr
      @showBuffer << value #unless [10, 0, 13].include? c
      manage_buffer(c)
    end
  end

  def insert_style()
      @vt.palette.setcolor("#{@textattr} #{@fgcolor} on #{@bgcolor}", "#{@textattr} #{@fgcolor} on #{@bgcolor}" )

      @showBuffer << "%(#{@textattr} #{@fgcolor} on #{@bgcolor})"
  end

  def send(s)
    @socket.puts(s) if @socket
  end
end
