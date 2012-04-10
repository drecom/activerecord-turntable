# load models
require File.expand_path(File.join(File.dirname(File.dirname(__FILE__)),'./test_models'))

# Fabrication
Fabricator(:user_status) do
  hp { (0..10).to_a.sample }
  mp { (0..10).to_a.sample }
end

Fabricator(:user) do
  nickname { Faker::Name.name }
  user_status { Fabricator(:user_status) }
end

