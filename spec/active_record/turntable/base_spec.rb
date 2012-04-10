require 'spec_helper'

describe ActiveRecord::Turntable::Base do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../config/turntable.yml"))
  end

  context "When installed to ActiveRecord::Base" do
    it "ActiveRecord::Base respond_to 'turntable'" do
      ActiveRecord::Base.should respond_to(:turntable)
    end
  end
end
