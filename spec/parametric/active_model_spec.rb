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
        field(:account).schema do
          field(:name).type(:string)
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

  context 'nested anonymous objects' do
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

  context 'nested objects with named schemas' do
    FriendForm = Class.new(described_class) do
      self.name = 'friend'
      schema do
        field(:name).type(:string).present
        field(:age).type(:integer)
      end
    end

    let(:user_form) {
      Class.new(described_class) do
        self.name = 'user'

        schema do
          field(:name).type(:string).present
          field(:friends).type(:array).schema FriendForm
        end
      end
    }

    let(:form) {
      user_form.new(
        name: 'Ismael',
        friends: [
          {name: 'Joe', age: 34}
        ],
        account: {name: 'abc'}
      )
    }

    subject(:friend) { form.friends.first }
    it_behaves_like 'ActiveModel'

    it 'wraps nested object in given class' do
      expect(friend).to be_a FriendForm
    end
  end

  context 'with instances of ActionController::Parameters' do
    it 'permits all and symbolizes keys' do
      params = double('Params', permit!: {'name' => 'foo'})
      form = user_form.new(params)
      expect(form.name).to eq 'foo'
    end
  end

  context 'with *_attributes keys sent by Rails forms' do
    it 'maps Rails arrays to the correct keys' do
      form = user_form.new(
        name: 'Foo',
        friends_attributes: {
          '0' => {name: 'Joe', age: 34},
          '1' => {name: 'Joan', age: 43}
        }
      )

      expect(form.name).to eq 'Foo'
      expect(form.friends.first.name).to eq 'Joe'
      expect(form.friends.first.age).to eq 34
    end

    it 'maps Rails objects to the correct keys' do
      form = user_form.new(
        name: 'Foo',
        account_attributes: {
          name: 'ACME'
        }
      )

      expect(form.name).to eq 'Foo'
      expect(form.account.name).to eq 'ACME'
    end
  end
end
