require 'socket'
class Rouge
    def initialize
        @sock = nil
    end

    def connect(host='127.0.0.1', port=6379)
        @sock = TCPSocket.new(host, port) 
        @sock.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1
    end      

    def build_msg(msg_string)
        toks = msg_string.split(" ")
        msg  = toks.collect {|a| "$#{a.size}\r\n#{a}\r\n"}
        cmd  = "*#{toks.size}\r\n#{msg}"
    end

    def cmd(msg)
        connect unless @sock.class == 'TCPSocket'
        @sock.write(build_msg(msg))
        type = @sock.read(1)
        len  = @sock.gets
        reply_factory(type, len)
    end

    def get_reply
        type = @sock.read(1)
        msg  = @sock.gets
        reply_factory(type, msg)
    end

    def reply_factory(type, msg)
        types = {
            '+' => 'dry_reply',
            '-' => 'dry_reply',
            '*' => 'mucho_reply',
            '$' => 'multi_reply'
        }
        self.send(types[type], msg)
    end

    def multi_reply(data)
        len = data.to_i
        return if len == -1
        reply = @sock.read(len)
        @sock.read(2) # get rid of EOL
        reply
    end

    def mucho_reply(data)
        reply = []
        len = data.to_i
        len.times { reply << get_reply }
        reply
    end

    def dry_reply(data)
        data.strip
    end
end


r = Rouge.new
p r.cmd("hgetall myself")
