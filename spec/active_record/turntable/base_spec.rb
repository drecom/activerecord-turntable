require "spec_helper"

describe ActiveRecord::Turntable::Base do
  context "When installed to ActiveRecord::Base" do
    it "ActiveRecord::Base respond_to 'turntable'" do
      expect(ActiveRecord::Base).to respond_to(:turntable)
    end
  end

  context "When enable turntable on STI models" do
    subject { klass.new }

    context "With a STI parent class" do
      let(:klass) { EventsUsersHistory }

      its(:connection) { expect { subject }.not_to raise_error }
    end

    context "With a STI subclass" do
      let(:klass) { SpecialEventsUsersHistory }

      its(:connection) { expect { subject }.not_to raise_error }
    end
  end
end
