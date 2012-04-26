# -*- encoding: utf-8 -*-
require File.expand_path('../lib/paperclip-imgix/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jeremy Larkin"]
  gem.email         = ["jeremy@zebrafishlabs.com"]
  gem.description   = %q{Paperclip plugin that integrates with the Imgix CDN.}
  gem.summary       = %q{Paperclip plugin that integrates with the Imgix CDN.}
  gem.homepage      = "http://github.com/imgix/paperclip-imgix"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "paperclip-imgix"
  gem.require_paths = ["lib"]
  gem.version       = Paperclip::Imgix::VERSION

  gem.add_runtime_dependency("paperclip", "~> 3.0")
end
