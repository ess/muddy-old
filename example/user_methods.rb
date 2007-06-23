# These examples are really only useful for ScryMUD, which lives at 
# scrymud.net:4444
#
# If you want to use this as an example, just drop it into ~/.muddy

# Yay for state variables!
@weapon = ''
@trippable = true

# Use this to equip your main weapon so that it can be retrieved in the
# cast of a disarm.
def wield(weapon)
  @weapon = weapon
  send "wear #{weapon}"
  print "weapon == #{@weapon}"
end

# Use this to reclaim and re-equip your main weapon in the case that you
# are disarmed
def recover_weapon
  @disarmed = false
  send "get #{@weapon}"
  send "wear #{@weapon}"
end

# Murder is a well-planned method of killing.  It begins with a backstab.
# Then, if the victim can be tripped, it alternates between trips, body
# slams, and weapon recovery
def murder(victim)
  @victim = victim
  @trippable = true
  enable_battle_triggers
  send "backstab #{@victim}"
  attack
end

# These are some good examples of how triggers work.  The hash key can
# be any type that String.match can handle (typically, String and 
# Regexp).  The value must be a string.  Several of these triggers do
# nothing but call other methods, and that's really the preferred way
# to do things, so far as I'm concerned.
def enable_battle_triggers
  @triggers['floats above your attempt to trip'] = 'untrippable'
  @triggers[/(your head with|You fail to lift)/] = 'attack'
  @triggers['disarms you'] = "@disarmed = true"
  @triggers[/(is dead|Visible exits:)/] = 'disable_battle_triggers'
end

def attack
  send "trip" if @trippable
  send "bod"
  recover_weapon
end

def untrippable
  @trippable = false
end

# The important part of this method is the bit where @triggers is set to
# a new Hash.  You can delete individual triggers, if you'd like, but
# this is how I do it.
def disable_battle_triggers
  @victim = ''
  @trippable = true
  @triggers = Hash.new
  print "The battle has ended."
end

# Yeah, I'm lazy.  
def recall(target = "self")
  send "cast recall #{target}"
end

# So, this one is a little less lazy.
def cast_defensive_spells(target = "self")
  spells = [
    "fly", 
    "'prismatic globe'", 
    "'shadows blessing'", 
    "'divine protection'", 
    "'stone skin'", 
    "'magic shield'", 
    "invisibility"
  ]
  
  spells.each do |spell|
    send "cast #{spell} #{target}"
  end
end

# Starts up a thread to send a newline to the server every minute in the
# event that you can't pay attention to it, but don't want to drop off.
def keepalive
  echo "Initializing the keepalive ..."
  @mythread = Thread.new do
    loop do
      sleep 60
      send ""
    end
  end
end

# Kills the keepalive thread.
def kill_keepalive
  @mythread.kill
  echo "keepalive killed"
end

# Use the path method to execute a "speedwalk" from one place to another.
# For example, you'll see below a method called "garland_to_bandra."  If
# you are in the Temple of Garland, and you issue the following command,
# you will end up at the eastern border of Bandra:  /path "garland_to_bandra"
def path(thepath)
  send(eval(thepath))
end   

# This one is to help the clueless newbies know where to go.  You use it the
# same way as path, except that it sends the path to the server in a say
# command so that anybody in the same room as you can read the way to get
# to the specified location from the specified origin.
def saypath(thepath)
  send "say #{thepath}:  #{eval(thepath).gsub(/;/, ' ')}"
end

# Most everything after this point is a path that can be used in ScryMUD.
# The exception to this is the "opposite" method, which simply returns the
# polar opposite of the given direction.
def garland_to_bandra
  thepath = Array.new
  thepath.push "d"
  8.times { thepath.push "w" }
  thepath.push "sw"
  2.times { thepath.push "w" }
  thepath.push "nw"
  thepath.push "w"
  2.times { thepath.push "sw" }
  6.times {thepath.push "w" }
  thepath.push "nw"
  3.times { thepath.push "w" }
  2.times { thepath.push "sw" }
  4.times { thepath.push "s" }
  3.times { thepath.push "sw" }
  4.times { thepath.push "w" }
  thepath.join(';')
end

def garland_to_jakarta
  thepath = ['d','e','e','e','e','e','e','s','s','s','s','s','se','se','se','se','e','e','se','s','e','e','s','se','se','se','se','e','se','e','se','e','e','e','e','e','se','se','e','se','e','ne','e','s','e','ne','e','se','se','e','e','se','e','ne','e','e','se','e','e','e','e','e']

  thepath.join(';')
end

def jakarta_to_garland
  path = garland_to_jakarta.split(';')

  sendstring = ""
  path.reverse.each do |direction|
    sendstring += opposite(direction) + ';'
  end

  sendstring
end
    
def opposite(direction)
  opposites = {"e" => "w", "w" => "e", "n" => "s", "s" => "n", "ne" => "sw", "sw" => "ne", "nw" => "se", "se" => "nw", "d" => "u", "u" => "d"}
  return opposites[direction]
end

def recall(target = "self")
  send "cast recall #{target}"
end

