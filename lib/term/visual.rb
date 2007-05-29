require 'ncurses'
require 'observer'

module Term # :nodoc:

	class Visual
		attr_reader :palette, :current_window, :common_input, :global_prefix
		
		# Creates a new Term::Visual object.
		def initialize
			Ncurses.initscr
			at_exit { Ncurses.endwin if Ncurses.respond_to?(:endwin) }

			Ncurses.cbreak
			Ncurses.noecho
			Ncurses.nonl
			Ncurses.start_color
			Ncurses.use_default_colors
			Ncurses.stdscr.intrflush(false)
			Ncurses.stdscr.keypad(true)
			Ncurses.stdscr.nodelay(true)

			@windows = Array.new
			@line = String.new

			@palette = Term::Visual::Palette.new

			@palette.setcolors(
				'default'	=> "default on default",
				'title'		=> "white on blue",
				'status'	=> "white on blue",
				'edit'		=> "default on default"
			)

			@common_input = Term::Visual::CommonInput.new(self)
			@global_prefix = ""
		end

		# Sets the global prefix. +prefix+ may be a String object or a block
		# (or anything that responds to +call+). If +prefix+ is a block (or
		# responds to +call+), then it will be called every time a line is
		# printed to the window. Strings will simply be added to the front of
		# the prefix as they are.
		def global_prefix=(prefix)
			if prefix.kind_of?(String) || prefix.respond_to?(:call)
				@global_prefix = prefix
			else
				raise "global prefix must be a String or respond to .call"
			end
		end
		
		# Create a new window.
		#
		# [+name+] identifier of the window
		# [+hash+] passed straight to Term::Visual::Window#new
		def create_window(hash=Hash.new)
			if !hash.kind_of?(Hash)
				raise "Window options must be given in a Hash."
			end
			hash["input"] = nil
			hash["global_prefix"] = @global_prefix
			window = Term::Visual::Window.new(self, hash)
			if !window
				raise "Failed to create window."
			end
			@windows.push(window)
			@current_window = window
			window.doupdate
			return window
		end

		def delete_window(window)
			if @current_window == window
				newwin = @windows.index(window) - 1
				if newwin < 0 then newwin = 0 end
				self.switch_window(@windows[newwin])
			end
			@windows.delete window
			@current_window.doupdate
			@current_window
		end

		def switch_window(window)
			if window == @current_window
				return false
			end
			@current_window = window
			window.doupdate
			true
		end

		# Returns a line from the user. This function is non-blocking, and will
		# return nil unless the user has entered a line and pressed enter.
		def getline
			@current_window.getline
		end

		def bind(key, block)
			@common_input.bind(key, block)
		end
	end
end

require 'lib/term/visual/input'
require 'lib/term/visual/palette'
require 'lib/term/visual/window'
