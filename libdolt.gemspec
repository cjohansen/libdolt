# -*- encoding: utf-8 -*-
dir = File.expand_path(File.dirname(__FILE__))
require File.join(dir, "lib/libdolt/version")

Gem::Specification.new do |s|
  s.name        = "libdolt"
  s.version     = Dolt::VERSION
  s.authors     = ["Christian Johansen"]
  s.email       = ["christian@gitorious.org"]
  s.homepage    = "http://gitorious.org/gitorious/libdolt"
  s.summary     = %q{Dolt API for serving git trees and syntax highlighted blobs}
  s.description = %q{Dolt API for serving git trees and syntax highlighted blobs}

  s.rubyforge_project = "libdolt"

  s.add_dependency "rugged", "0.18.0.gh.de28323"
  s.add_dependency "tzinfo", "~> 0.3"
  s.add_dependency "makeup", "~>0.4"
  s.add_dependency "htmlentities", "~> 4.3"
  s.add_dependency "json", "~> 1.7"
  s.add_dependency "mime-types", "~> 1.19"

  s.add_development_dependency "minitest", "~> 2.0"
  s.add_development_dependency "rake", "~> 0.9"
  s.add_development_dependency "redcarpet", "~> 2.2"
  s.add_development_dependency "tiltout", "~>1.4"
  s.add_development_dependency "mocha"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
