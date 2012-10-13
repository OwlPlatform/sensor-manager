#Require rubygems for old (pre 1.9 versions of Ruby and Debian-based systems)
require 'rubygems'
require 'client_world_connection.rb'
require 'solver_world_model.rb'
require 'wm_data.rb'
require 'buffer_manip.rb'

def getOwlTime()
  t = Time.now
  return t.tv_sec * 1000 + t.usec/10**3
end

if (ARGV.length < 3)
  puts "This program has four possible options: add, remove, modify, scan."
  puts "You must specify your origin name as the first argument, the phy ID as the second, and the option as the third."
  exit
end

origin = ARGV[0]
phy = ARGV[1].to_i

case ARGV[2]
when "add"
  #Extra arguments list the sensor ID, URI, and attribute type
  if (ARGV.length != 8)
    puts "The 'add' command requires a world model IP and port, sensor ID, attribute type, and object ID"
    exit
  end
  wmip = ARGV[3]
  port = ARGV[4]
  sense_id = ARGV[5].to_i
  type = ARGV[6]
  id = ARGV[7]

  #Connect to the world model as a client
  wm = SolverWorldModel.new(wmip, port, origin)

  #Make an attribute for gps location with an example value and the current time
  attribs = WMAttribute.new(type, [phy].pack('C') + packuint128(sense_id), getOwlTime())
  #Making a solution with a single attribute
  new_data = WMData.new(id, [attribs])
  wm.pushData([new_data], true)
  puts "Update sent."
when "remove"
  #Extra arguments list the sensor ID, URI, and attribute type
  if (ARGV.length != 6)
    puts "The 'remove' command requires a world model IP and port and an object ID to delete"
    exit
  end
  origin = ARGV[0]
  wmip = ARGV[3]
  port = ARGV[4]
  id = ARGV[5]

  #Connect to the world model as a client
  wm = SolverWorldModel.new(wmip, port, origin)
  wm.deleteURI(id)
when "modify"
  puts "Modifying is not yet implemented."
when "scan"
  puts "Scanning is not yet implemented."
else
  puts "#{ARGV[2].chomp} is not a recognized command."
end

