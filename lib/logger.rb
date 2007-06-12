class Logger

  def initialize(thelogfile = "muddy.log")
    @file = File.open(thelogfile, "w")
  end

  def log_message(messagetype, message)
    @file.puts("#{messagetype}: #{message}")
  end

  def log_error(errortype, error)
    log_message(errortype, error)
  end
end
