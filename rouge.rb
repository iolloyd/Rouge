# The program acts as a ruby interface to a redis server on the 
# TCP/IP layer. The socket connection is always given commands in 
# multi format which allows for easier programming and helps enforce
# the return format of any requests.
#
# Author::    Lloyd Moore (mailto:lloyd@workharderplayharder.com)
# Copyright:: Work Harder Play Harder (c) 2010 
# License::   Like James Bond, to kill

class Rouge
	require 'socket'

	# Makes sure there is no socket connection
    def initialize
        @sock = nil
    end

	# Sets up the connection to the redis server
    def connect(host='127.0.0.1', port=6379)
        @sock = TCPSocket.new(host, port) 
        @sock.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1
    end      

	# Formats a message in a format that redis will recognize
    def build_msg(msg_string)
        toks = msg_string.split(" ")
        msg  = toks.collect {|a| "$#{a.size}\r\n#{a}\r\n"}
        cmd  = "*#{toks.size}\r\n#{msg}"
    end

	# Sends a message to redis and returns the reply
    def cmd(msg)
        connect unless @sock.class == 'TCPSocket'
        @sock.write(build_msg(msg))
        type = @sock.read(1)
        len  = @sock.gets
        reply_factory(type, len)
    end

	# Used by the cmd method to retrieve response 
	# from redis server request
    def get_reply
        type = @sock.read(1)
        msg  = @sock.gets
        reply_factory(type, msg)
    end

	# Makes sure the correct type of reply is given 
    # to the client
    def reply_factory(type, msg)
        types = {
            '+' => 'dry_reply',
            '-' => 'dry_reply',
            ':' => 'dry_reply',
            '*' => 'mucho_reply',
            '$' => 'multi_reply'
        }
        self.send(types[type], msg)
    end

	# Used by the reply factory to return a
	# multi format reply
    def multi_reply(data)
        len = data.to_i
        return if len == -1
        reply = @sock.read(len)
        @sock.read(2) # get rid of EOL
        reply
    end

	# Used by the reply factory to return a
	# many-multi format reply
    def mucho_reply(data)
        reply = []
        len = data.to_i
        len.times { reply << get_reply }
        reply
    end

	# Used by the reply factory to return a 
	# simple format reply
    def dry_reply(data)
        data.strip
    end

    # Stores a reference to the data in the given group
    # to allow searches and sorting later on.
    # A group is similar to a table in mysql
    def set_with_reverse_lookup(group, data)
        next_id = cmd "incr global:next:#{group}"
        data.each do |k, v|
            cmd "sadd #{group} #{next_id}"
            cmd "set #{group}:#{next_id}:#{k} #{v}"
        end
    end

	# Uses the group like a table in Sql and stores the 
	# data in seperate atoms, relating the items saved
	# by storing their indices in a set
    def store_record(group, data)
        set_with_reverse_lookup(group, data)
    end
    
	# Given a list and a size, returns another list, 
	# breaking it up into equal chunk of n size
	def chunks(lst, chunk_size, acc=[])
		return acc if not lst
		if lst and lst.size <= chunk_size:
			acc.push(lst)
			acc
		else
			acc.push(lst[0, chunk_size])
			chunks(lst[chunk_size, lst.length-1], chunk_size, acc)
		end
	end

    # Given the set name, which acts like a table in sql, uses the sort
    # key to return an ordered version. If fields is specified, instead
    # of returning indices, the related values will be returned which is
    # generally more useful
    def sort(set_name, sort_key, start, stop, fields=[])
        things_to_get = fields.inject("") {|s, x| "#{s} get #{set_name}:*:#{x}"}
        out = cmd "sort #{set_name} by #{set_name}:*:#{sort_key} limit #{start} #{stop} #{things_to_get}"
        if fields.length > 1:
            chunks(out, fields.length)
        else
            out 
        end
    end
end
