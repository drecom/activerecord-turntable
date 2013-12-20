$:.push File.expand_path("../lib", __FILE__)
require "active_record/turntable/version"

Gem::Specification.new do |s|
  s.name = "activerecord-turntable"
  s.version = ActiveRecord::Turntable::VERSION
  s.authors     = ["gussan", "sue445"]
  s.homepage    = "https://github.com/drecom/activerecord-turntable"
  s.summary = %q{ActiveRecord sharding extension}
  s.description = %q{ActiveRecord sharding extension}
  s.license = "MIT"

  s.rubyforge_project = "activerecord-turntable"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc",
    "CHANGELOG.md"
  ]

  s.files         = `git ls-files`.split($/)
  s.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]


  s.add_dependency "activerecord",  ">= 4.0.0"
  s.add_dependency "activesupport", ">= 4.0.0"
  s.add_dependency "sql_tree",      "= 0.2.0"
  s.add_dependency "bsearch",       "~> 1.5"
  s.add_dependency "httpclient",    ">= 0"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.14"
  s.add_development_dependency "rr"
  s.add_development_dependency "mysql2"
  s.add_development_dependency "fabrication"
  s.add_development_dependency "faker"
  s.add_development_dependency "activerecord-import"
  s.add_development_dependency "pry"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "coveralls"

  if RUBY_PLATFORM =~ /darwin/
    s.add_development_dependency "growl"
  end
end
