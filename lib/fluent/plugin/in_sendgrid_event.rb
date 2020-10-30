require 'webrick/https'
require 'fluent/input'

module Fluent
  class SendGridEventInput < Input
    Plugin.register_input('sendgrid_event', self)

    config_param :tag, :string, :default => nil
    config_param :host, :string, :default => "0.0.0.0"
    config_param :port, :integer, :default => 9191
    config_param :ssl, :bool, :default => false
    config_param :certificate, :string, :default => nil
    config_param :private_key, :string, :default => nil
    config_param :username, :string, :default => nil
    config_param :password, :string, :default => nil, :secret => true
    config_param :request_uri, :string, :default => "/"

    unless method_defined?(:log)
      define_method("log") { $log }
    end

    def initialize
      super
    end

    def configure(conf)
      log.trace "in_sendgrid_event: configure"
      super

      if @tag.nil?
        raise Fluent::ConfigError, "sendgrid_event: 'tag' parameter is required"
      end
    end

    def start
      log.trace "in_sendgrid_event: start"
      super

      @thread = Thread.new(&method(:run))
    end

    def shutdown
      log.trace "in_sendgrid_event: shutdown"
      super

      @server.shutdown
      Thread.kill(@thread)
    end

    def run
      log.trace "in_sendgrid_event: run"
      listen = {
        :BindAddress => @host,
        :Port => @port
      }
      if @ssl
        if File.exists?(@certificate) && File.exists?(@private_key)
          listen[:SSLEnable] = @ssl
          listen[:SSLCertificate] = OpenSSL::X509::Certificate.new(open(@certificate).read)
          listen[:SSLPrivateKey] = OpenSSL::PKey::RSA.new(open(@private_key).read)
        else
          log.error "in_sendgrid_event: couldn't find certificate: '#{@certificate}' or ssl key: '#{@private_key}'"
        end
      end
      if @username && @password
        listen[:RequestCallback] = lambda do |req, res|
          WEBrick::HTTPAuth.basic_auth(req, res, "fluent-plugin-sendgrid-event") do |username, password|
            username == @username && password == @password
          end
        end
      end

      @server = WEBrick::HTTPServer.new(listen)
      @server.mount_proc(@request_uri) do |req, res|
        begin
          if req.request_method == "POST" && req.body
            events = JSON.parse(req.body)
            events.each do |event|
              emit_event(event)
            end
            log.trace "in_sendgrid_event: success"
            res.status = 200
          else
            log.error "in_sendgrid_event: invalid request"
            res.status = 400
          end
        rescue JSON::ParserError => e
          log.error "in_sendgrid_event: #{e}"
          res.status = 400
        rescue WEBrick::HTTPStatus::LengthRequired => e
          log.error "in_sendgrid_event: #{e}"
          res.status = 411
        rescue Exception => e
          log.warn "in_sendgrid_event: Retry: Reason: #{e}"
          log.warn "#{e.backtrace.join('\n')}"
          res.status = 503
        end
      end
      @server.start
    end # The end of run method

    def emit_event(event)
      log.trace "in_sendgrid_event: emit_event"
      Engine.emit("#{tag}", Engine.now, event)
    end
  end
end
