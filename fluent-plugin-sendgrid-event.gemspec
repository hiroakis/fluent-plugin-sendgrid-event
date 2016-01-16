# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-sendgrid-event"
  spec.version       = "0.0.5"
  spec.authors       = ["Hiroaki Sano"]
  spec.email         = ["hiroaki.sano.9stories@gmail.com"]

  spec.summary       = %q{Fluent input plugin to receive sendgrid event.}
  spec.homepage      = "https://github.com/hiroakis/fluent-plugin-sendgrid-event"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit"

  spec.add_runtime_dependency "fluentd"
end
