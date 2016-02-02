# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'credstash/init/version'

Gem::Specification.new do |spec|
  spec.name          = "credstash-init"
  spec.version       = Credstash::VERSION
  spec.authors       = ["Bryan Conrad"]
  spec.email         = ["bkconrad@gmail.com"]

  spec.summary       = %q{Set up individual credstash keys and DBs for isolated environments}
  spec.homepage      = "https://github.com/bkconrad/credstash-init"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-resources", "~> 2"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
end
