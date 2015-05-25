require 'spec_helper'

describe ActiveRecord::Turntable::Algorithm::ModuloAlgorithm do
  before(:all) do
    reload_turntable!(File.join(File.dirname(__FILE__), "../../../config/turntable.yml"))
  end

  context "When initialized" do
    before do
      @alg = ActiveRecord::Turntable::Algorithm::ModuloAlgorithm.new(ActiveRecord::Base.turntable_config[:clusters][:mod_cluster])
    end

    context "#calculate with 1" do
      subject { @alg.calculate(1) }
      it { is_expected.to eq(ActiveRecord::Base.turntable_config[:clusters][:user_cluster][:shards][1][:connection]) }
    end

    context "#calculate with 3" do
      subject { @alg.calculate(3) }
      it { is_expected.to eq(ActiveRecord::Base.turntable_config[:clusters][:user_cluster][:shards][3][:connection]) }
    end

    context "#calculate with 5" do
      subject { @alg.calculate(5) }
      it { is_expected.to eq(ActiveRecord::Base.turntable_config[:clusters][:user_cluster][:shards][0][:connection]) }
    end

    context "#calculate with a value that is not a number" do
      it "raises ActiveRecord::Turntable::CannotSpecifyShardError" do
        expect { @alg.calculate('a') }.to raise_error(ActiveRecord::Turntable::CannotSpecifyShardError)
      end
    end
  end

end
