$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "active_record/turntable/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord-turntable"
  spec.version = ActiveRecord::Turntable::VERSION
  spec.authors     = %w(gussan sue445)
  spec.homepage    = "https://github.com/drecom/activerecord-turntable"
  spec.summary = "ActiveRecord sharding extension"
  spec.description = "ActiveRecord sharding extension"
  spec.license = "MIT"

  spec.rubyforge_project = "activerecord-turntable"
  spec.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md",
  ]

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.2.2"

  spec.add_runtime_dependency "activerecord",  ">= 5.0", "< 6.0"
  spec.add_runtime_dependency "activesupport", ">= 5.0", "< 6.0"
  spec.add_runtime_dependency "bsearch",       "~> 1.5"
  spec.add_runtime_dependency "httpclient",    ">= 0"
  spec.add_runtime_dependency "sql_tree",      "= 0.2.0"

  # optional dependencies
  spec.add_development_dependency "activerecord-import"
  spec.add_development_dependency "barrage"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "fabrication"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "guard-rubocop"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "onkcop"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.1.0"
  spec.add_development_dependency "rspec-collection_matchers"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "webmock"

  if RUBY_PLATFORM =~ /darwin/
    spec.add_development_dependency "growl"
  end
end
