require 'active_model/lint'
require 'minitest'

RSpec.shared_examples_for 'ActiveModel' do
  include ActiveModel::Lint::Tests
  include Minitest::Assertions

  alias_method :model, :subject

  attr_accessor :assertions

  before(:each) { self.assertions = 0 }

  ActiveModel::Lint::Tests.public_instance_methods.map(&:to_s).grep(/^test/).each do |m|
    it(m.sub 'test_', 'responds to ') { send m }
  end
end

RSpec.describe Parametric::ActiveModel do
  let(:user_form) {
    Class.new(described_class) do
      self.name = 'user'

      schema do
        field(:name).type(:string).present
        field(:friends).type(:array).schema do
          field(:name).type(:string).present
          field(:age).type(:integer)
        end
      end
    end
  }

  it_behaves_like 'ActiveModel'

  it "has a version number" do
    expect(Parametric::ActiveModel::VERSION).not_to be nil
  end

  describe '#errors' do
    it 'includes top level errors' do
      form = user_form.new(name: '')
      expect(form.valid?).to be false
      expect(form.errors[:name]).to eq ['is required and value must be present']
    end

    it 'includes errors for nested objects' do
      form = user_form.new(name: 'Ismael', friends: [{name: ''}])
      expect(form.valid?).to be false
      expect(form.friends.first.valid?).to be false
      expect(form.friends.first.errors[:name]).to eq ['is required and value must be present']
    end
  end

  context 'nested objects' do
    let(:form) {
      user_form.new(
        name: 'Ismael',
        friends: [
          {name: 'Joe', age: 34}
        ]
      )
    }

    subject { form.friends.first }
    it_behaves_like 'ActiveModel'
  end
end
