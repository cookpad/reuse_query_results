require 'active_record/connection_handling'
require 'active_record/railtie'
require 'active_record/migration'

module ReuseQueryResultsTestApp
  Application = Class.new(Rails::Application) do
    config.root = __dir__
    config.eager_load = false
    config.active_support.deprecation = :log
  end.initialize!
end


# models
class Foo < ActiveRecord::Base
  has_one :bar
end

class Bar < ActiveRecord::Base
  belongs_to :foo
end

class Baz < ActiveRecord::Base; end

# migrations
class CreateAllTables < ActiveRecord::Migration
  def self.up
    create_table(:foos) {|t| t.string :name }
    create_table(:bars) {|t| t.string :name; t.integer :foo_id }
    ActiveRecord::Base.establish_connection :test
  end
end
