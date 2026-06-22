# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'reuse_query_results/version'

Gem::Specification.new do |spec|
  spec.name          = "reuse_query_results"
  spec.version       = ReuseQueryResults::VERSION
  spec.authors       = ["morita shingo"]
  spec.email         = ["eudoxa.jp@gmail.com"]
  spec.summary       = "Reuse sql query results on development"
  spec.description       = "Reuse sql query results on development"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.2.33"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'sqlite3'
end
