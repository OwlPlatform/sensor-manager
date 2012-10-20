#Require rubygems for old (pre 1.9 versions of Ruby and Debian-based systems)
require 'rubygems'
require 'client_world_connection.rb'
require 'solver_aggregator.rb'
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
    puts "The 'add' command requires a world model IP and solver port, sensor ID, attribute type, and object ID"
    exit
  end
  wmip = ARGV[3]
  port = ARGV[4]
  sense_id = ARGV[5].to_i
  type = ARGV[6]
  id = ARGV[7]

  if ("sensor" != type.split(".")[0])
    puts "The attribute type for a sensor must always start with \"sensor\""
    puts "For instance \"sensor\", \"sensor.switch\", or \"sensor.power\""
    exit
  end

  #Connect to the world model as a client
  wm = SolverWorldModel.new(wmip, port, origin)

  #Make an attribute for gps location with an example value and the current time
  attribs = WMAttribute.new(type, [phy].pack('C') + packuint128(sense_id), getOwlTime())
  #Making a solution with a single attribute
  new_data = WMData.new(id, [attribs])
  wm.pushData([new_data], true)
  puts "Update sent."
when "remove"
  #Delete an ID and all of its attributes (should add something to also just delete attributes)
  #Extra arguments list the sensor ID, URI, and attribute type
  if (ARGV.length != 6)
    puts "The 'remove' command requires a world model IP and solver port and an object ID to delete"
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
  #Modify an attribute if it exists.
  #This does the same thing as an insert, but it makes sure that the attribute exists first
  puts "Modifying is not yet implemented."
when "scan"
  #Scan for sensors that are not known in the world model
  if (ARGV.length != 7)
    puts "The 'scan' command requires an aggregator IP and port and a world model IP and client port"
    exit
  end
  origin = ARGV[0]
  agg_ip = ARGV[3]
  agg_port = ARGV[4]
  wmip = ARGV[5]
  port = ARGV[6]

  #Listen for a couple of seconds, just like your wifi card does when it scans!
  new_ids = {}

  begin
    now = getOwlTime()
    sq = SolverAggregator.new(agg_ip, agg_port)
    puts "Scanning..."

    #Request packets from the specified phy, don't specify a transmitter ID or
    #mask, and request packets every second
    sq.sendSubscription([AggrRule.new(phy, [], 1000)])
    while (sq.handleMessage and (getOwlTime() - now < 3000)) do
      if (sq.available_packets.length != 0) then
        for packet in sq.available_packets do
          puts packet
          new_ids[packet.device_id] = false
        end
      end
      sq.available_packets.clear
    end
    #Finished with the aggregator
    sq.close()
  end
  #Connect to the world model as a client
  cwm = ClientWorldConnection.new(wmip, port)

  #Search for all sensor names and mark them off in the new_ids list
  result = cwm.snapshotRequest('.*', ['sensor.*']).get()
  result.each_pair {|uri, attributes|
    attributes.each {|attr|
      id = unpackuint128(attr.data[1,attr.data.length-1])
      if (new_ids.has_key? id)
        new_ids[id] = true
      end
    }
  }
  puts "Unknown device IDs:"
  #Now request all of the sensor attributes from the world model and see if
  #anything in the new_ids list is new
  new_ids.each{|id, known|
    puts id if (not known)
  }
  puts "Known device IDs:"
  new_ids.each{|id, known|
    puts id if (known)
  }
else
  puts "#{ARGV[2].chomp} is not a recognized command."
end

