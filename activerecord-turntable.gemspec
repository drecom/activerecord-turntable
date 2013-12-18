$:.push File.expand_path("../lib", __FILE__)
require "active_record/turntable/version"

Gem::Specification.new do |s|
  s.name = "activerecord-turntable"
  s.version = ActiveRecord::Turntable::VERSION
  s.authors     = ["gussan"]
  s.homepage    = "https://github.com/drecom/activerecord-turntable"
  s.summary = %q{ActiveRecord Sharding plugin}
  s.description = %q{ActiveRecord Sharding plugin}

  s.rubyforge_project = "activerecord-turntable"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc",
    "CHANGELOG.md"
  ]

  s.files         = `git ls-files | grep -v "^spec"`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.licenses = ["MIT"]
  s.rubygems_version = "1.8.16"

  # runtime dependencies
  s.add_runtime_dependency(%q<activerecord>, [">= 4.0.0"])
  s.add_runtime_dependency(%q<activesupport>, [">=4.0.0"])
  s.add_runtime_dependency(%q<sql_tree>, ["= 0.2.0"])
  s.add_runtime_dependency(%q<bsearch>, ["~> 1.5"])
  s.add_runtime_dependency(%q<httpclient>, [">= 0"])

  # development dependencies
  s.add_development_dependency(%q<rake>, ["~> 10.0.3"])
  s.add_development_dependency(%q<rspec>, [">= 0"])
  s.add_development_dependency(%q<rr>, [">= 0"])
  s.add_development_dependency(%q<mysql2>, [">= 0"])
  s.add_development_dependency(%q<fabrication>, [">= 0"])
  s.add_development_dependency(%q<faker>, [">= 0"])
  s.add_development_dependency(%q<activerecord-import>, [">= 0"])
  s.add_development_dependency(%q<pry>, [">= 0"])
  s.add_development_dependency(%q<guard-rspec>, [">= 0"])
  s.add_development_dependency(%q<coveralls>, [">= 0"])

  if RUBY_PLATFORM =~ /darwin/
    s.add_development_dependency(%q<growl>, [">= 0"])
  end
end
