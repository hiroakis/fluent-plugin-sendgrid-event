# fluent-plugin-sendgrid-event

Fluentd input plugin to receive sendgrid event.

SendGrid is a delivering email platform.  Please visit below link for the specification of event webhook.
https://sendgrid.com/docs/API_Reference/Webhooks/event.html

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-sendgrid-event'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-sendgrid-event

## Usage

The following is an example of configuration.

```
<source>
  type sendgrid_event
  host 127.0.0.1
  port 9191
  tag sendgrid
</source>
```

## Contributing

1. Fork it ( http://github.com/hiroakis/fluent-plugin-sendgrid-event/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

## License

MIT
