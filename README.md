# Parametric::Activemodel (WiP)

Turn [Parametric schemas](https://github.com/ismasan/parametric) into ActiveModel-compliant form objects, including validations.

## Usage

Define your forms.

```ruby
require 'parametric/active_model'

class User < Parametric::ActiveModel
  schema do
    field(:name).type(:string).present
    field(:friends).type(:array).schema do
      field(:name).type(:string).present
      field(:age).type(:integer)
    end
  end

  def save!
    # do something here
  end
end
```

Now use it in Rails controllers:

```ruby
def new
  @user = User.new
end

def create
  @user = User.new(params[:user])
  @user.save!
end
```

Views work normally:

```erb
<%= form_for @user do |f| %>
  <%= f.text_field :name %>
  <!-- nested objects -->
  <%= f.fields_for :friends do |friend| %>
    <%= friend.text_field :name %>
    <%= friend.text_field :age %>
  <% end %>
<% end %>
```

## Nested forms

You can also use nested form objects:

```ruby
class Friend < Parametric::ActiveModel
  schema do
    field(:name).type(:string).present
    field(:age).type(:integer)
  end
end

# now embed it in the parent form

class User < Parametric::ActiveModel
  schema do
    field(:name).type(:string).present
    field(:friends).type(:array).schema Friend # <== here!
  end

  # etc..
end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'parametric-active_model'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install parametric-active_model

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/parametric-active_model.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
