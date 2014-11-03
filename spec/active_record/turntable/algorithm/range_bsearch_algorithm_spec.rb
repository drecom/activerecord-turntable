require 'spec_helper'

describe ActiveRecord::Turntable::Algorithm::RangeBsearchAlgorithm do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  context "When initialized" do
    before do
      @alg = ActiveRecord::Turntable::Algorithm::RangeBsearchAlgorithm.new(ActiveRecord::Base.turntable_config[:clusters][:user_cluster])
    end

    context "#calculate with 1" do
      subject { @alg.calculate(1) }
      it { is_expected.to eq(ActiveRecord::Base.turntable_config[:clusters][:user_cluster][:shards][0][:connection]) }
    end

    context "#calculate with 19999" do
      subject { @alg.calculate(19999) }
      it { is_expected.to eq(ActiveRecord::Base.turntable_config[:clusters][:user_cluster][:shards][0][:connection]) }
    end

    context "#calculate with 20000" do
      subject { @alg.calculate(20000) }
      it { is_expected.to eq(ActiveRecord::Base.turntable_config[:clusters][:user_cluster][:shards][1][:connection]) }
    end

    context "#calculate with 10000000" do
      it "raises ActiveRecord::Turntable::CannotSpecifyShardError" do
        expect { @alg.calculate(10000000) }.to raise_error(ActiveRecord::Turntable::CannotSpecifyShardError)
      end
    end
  end

end
