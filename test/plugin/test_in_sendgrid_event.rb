require 'helper'

class SendGridEventTest < Test::Unit::TestCase

  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    type sendgrid_event
    host 127.0.0.1
    port 9191
    tag sendgrid.event
  ]

  def create_driver(conf=CONFIG, tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::SendGridEventInput, tag).configure(conf)
  end

  def test_configuration
    d = create_driver
    assert_equal '127.0.0.1', d.instance.host
    assert_equal 9191, d.instance.port
    assert_equal 'sendgrid.event', d.instance.tag
  end

  def test_configuration_with_empty_tag
    assert_raise(Fluent::ConfigError) {
      create_driver %[
        type sendgrid_event
        host 127.0.0.1
        port 9191
        # tag sendgrid.event
      ]
    }
  end

  # This data is from https://sendgrid.com/docs/API_Reference/Webhooks/event.html
  def valid_event_json
    [
      {
        "sg_message_id" => "sendgrid_internal_message_id",
        "email" => "john.doe@sendgrid.com",
        "timestamp" => 1337197600,
        "smtp-id" => "<4FB4041F.6080505@sendgrid.com>",
        "event" => "processed"
      },
      {
        "sg_message_id" => "sendgrid_internal_message_id",
        "email" => "john.doe@sendgrid.com",
        "timestamp" => 1337966815,
        "category" => "newuser",
        "event" => "click",
        "url" => "https://sendgrid.com"
      },
      {
        "sg_message_id" => "sendgrid_internal_message_id",
        "email" => "john.doe@sendgrid.com",
        "timestamp" => 1337969592,
        "smtp-id" => "<20120525181309.C1A9B40405B3@Example-Mac.local>",
        "event" => "group_unsubscribe",
        "asm_group_id" => 42
      }
    ].to_json
  end

  def invalid_event_json
    valid_event_json.gsub!(":", ";")
  end

  def send_event(post_data)
    require 'net/http'
    http = Net::HTTP.new("localhost", 9191)
    req = Net::HTTP::Post.new('/')
    req.body = post_data
    req["Content-Type"] = "application/json"
    res = http.request(req)
    res
  end

  def send_event_with_https(post_data)
    require 'net/http'
    http = Net::HTTP.new("hiroakis.com", 9191)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    req = Net::HTTP::Post.new('/')
    req.body = post_data
    req["Content-Type"] = "application/json"
    res = http.request(req)
    res
  end

  def send_event_with_auth(post_data, username, password)
    require 'net/http'
    http = Net::HTTP.new("127.0.0.1", 9191)
    req = Net::HTTP::Post.new('/')
    req.basic_auth(username, password)
    req.body = post_data
    req["Content-Type"] = "application/json"
    res = http.request(req)
    res
  end

  def test_with_valid_event_json
    d = create_driver %[
      type sendgrid_event
      host 127.0.0.1
      port 9191
      tag sendgrid.event
    ]

    sleep 0.5
    d.run do
      res = send_event(valid_event_json)
      assert_equal("200", res.code)
    end

    assert_equal(3, d.emits.size)

    assert_equal("sendgrid.event",                  d.emits[0][0])
    assert_equal("sendgrid_internal_message_id",    d.emits[0][2]["sg_message_id"])
    assert_equal("john.doe@sendgrid.com",           d.emits[0][2]["email"])
    assert_equal(1337197600,                        d.emits[0][2]["timestamp"])
    assert_equal("<4FB4041F.6080505@sendgrid.com>", d.emits[0][2]["smtp-id"])
    assert_equal("processed",                       d.emits[0][2]["event"])

    assert_equal("sendgrid.event",               d.emits[1][0])
    assert_equal("sendgrid_internal_message_id", d.emits[1][2]["sg_message_id"])
    assert_equal("john.doe@sendgrid.com",        d.emits[1][2]["email"])
    assert_equal(1337966815,                     d.emits[1][2]["timestamp"])
    assert_equal("newuser",                      d.emits[1][2]["category"])
    assert_equal("click",                        d.emits[1][2]["event"])
    assert_equal("https://sendgrid.com",         d.emits[1][2]["url"])

    assert_equal("sendgrid.event",                                  d.emits[2][0])
    assert_equal("sendgrid_internal_message_id",                    d.emits[2][2]["sg_message_id"])
    assert_equal("john.doe@sendgrid.com",                           d.emits[2][2]["email"])
    assert_equal(1337969592,                                        d.emits[2][2]["timestamp"])
    assert_equal("<20120525181309.C1A9B40405B3@Example-Mac.local>", d.emits[2][2]["smtp-id"])
    assert_equal("group_unsubscribe",                               d.emits[2][2]["event"])
    assert_equal(42,                                                d.emits[2][2]["asm_group_id"])
  end

  def test_invalid_event_json
    d = create_driver %[
      type sendgrid_event
      host 127.0.0.1
      port 9191
      tag sendgrid.event
    ]

    d.run do
      res = send_event(invalid_event_json)
      assert_equal("400", res.code)
    end
    assert_equal(0, d.emits.size)
  end

  # def test_https_with_valid_event_json
  #   d = create_driver %[
  #     type sendgrid_event
  #     host 127.0.0.1
  #     port 9191
  #     ssl true
  #     certificate /Users/hiroakis/work/hiroakis.com.pem
  #     private_key /Users/hiroakis/work/hiroakis.com.key
  #     tag sendgrid.event
  #   ]

  #   sleep 0.5
  #   d.run do
  #     res = send_event_with_https(valid_event_json)
  #     assert_equal("200", res.code)
  #   end

  #   assert_equal(3, d.emits.size)

  #   assert_equal("sendgrid.event",                  d.emits[0][0])
  #   assert_equal("sendgrid_internal_message_id",    d.emits[0][2]["sg_message_id"])
  #   assert_equal("john.doe@sendgrid.com",           d.emits[0][2]["email"])
  #   assert_equal(1337197600,                        d.emits[0][2]["timestamp"])
  #   assert_equal("<4FB4041F.6080505@sendgrid.com>", d.emits[0][2]["smtp-id"])
  #   assert_equal("processed",                       d.emits[0][2]["event"])

  #   assert_equal("sendgrid.event",               d.emits[1][0])
  #   assert_equal("sendgrid_internal_message_id", d.emits[1][2]["sg_message_id"])
  #   assert_equal("john.doe@sendgrid.com",        d.emits[1][2]["email"])
  #   assert_equal(1337966815,                     d.emits[1][2]["timestamp"])
  #   assert_equal("newuser",                      d.emits[1][2]["category"])
  #   assert_equal("click",                        d.emits[1][2]["event"])
  #   assert_equal("https://sendgrid.com",         d.emits[1][2]["url"])

  #   assert_equal("sendgrid.event",                                  d.emits[2][0])
  #   assert_equal("sendgrid_internal_message_id",                    d.emits[2][2]["sg_message_id"])
  #   assert_equal("john.doe@sendgrid.com",                           d.emits[2][2]["email"])
  #   assert_equal(1337969592,                                        d.emits[2][2]["timestamp"])
  #   assert_equal("<20120525181309.C1A9B40405B3@Example-Mac.local>", d.emits[2][2]["smtp-id"])
  #   assert_equal("group_unsubscribe",                               d.emits[2][2]["event"])
  #   assert_equal(42,                                                d.emits[2][2]["asm_group_id"])
  # end

  def test_basic_auth
    d = create_driver %[
      type sendgrid_event
      host 127.0.0.1
      port 9191
      tag sendgrid.event
      username auth_user
      password auth_pass
    ]

    sleep 0.5
    d.run do
      res = send_event_with_auth(valid_event_json, "auth_user", "auth_pass")
      assert_equal("200", res.code)
    end

    assert_equal(3, d.emits.size)

    assert_equal("sendgrid.event",                  d.emits[0][0])
    assert_equal("sendgrid_internal_message_id",    d.emits[0][2]["sg_message_id"])
    assert_equal("john.doe@sendgrid.com",           d.emits[0][2]["email"])
    assert_equal(1337197600,                        d.emits[0][2]["timestamp"])
    assert_equal("<4FB4041F.6080505@sendgrid.com>", d.emits[0][2]["smtp-id"])
    assert_equal("processed",                       d.emits[0][2]["event"])

    assert_equal("sendgrid.event",               d.emits[1][0])
    assert_equal("sendgrid_internal_message_id", d.emits[1][2]["sg_message_id"])
    assert_equal("john.doe@sendgrid.com",        d.emits[1][2]["email"])
    assert_equal(1337966815,                     d.emits[1][2]["timestamp"])
    assert_equal("newuser",                      d.emits[1][2]["category"])
    assert_equal("click",                        d.emits[1][2]["event"])
    assert_equal("https://sendgrid.com",         d.emits[1][2]["url"])

    assert_equal("sendgrid.event",                                  d.emits[2][0])
    assert_equal("sendgrid_internal_message_id",                    d.emits[2][2]["sg_message_id"])
    assert_equal("john.doe@sendgrid.com",                           d.emits[2][2]["email"])
    assert_equal(1337969592,                                        d.emits[2][2]["timestamp"])
    assert_equal("<20120525181309.C1A9B40405B3@Example-Mac.local>", d.emits[2][2]["smtp-id"])
    assert_equal("group_unsubscribe",                               d.emits[2][2]["event"])
    assert_equal(42,                                                d.emits[2][2]["asm_group_id"])
  end

  def test_basic_auth_with_invalid_user
    d = create_driver %[
      type sendgrid_event
      host 127.0.0.1
      port 9191
      tag sendgrid.event
      username auth_user
      password auth_pass
    ]

    sleep 0.5
    d.run do
      res = send_event_with_auth(valid_event_json, "xxxxxx", "xxxxx")
      assert_equal("401", res.code)
    end
    assert_equal(0, d.emits.size)
  end
end
