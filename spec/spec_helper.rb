ENV['RAILS_ENV'] ||= 'test'

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))
$LOAD_PATH.unshift(__dir__)


require 'rails'
require 'reuse_query_results'
require 'reuse_query_results/active_record_monkey_patch'
require 'fake_app'

RSpec.configure do |config|
  config.before :all do
    CreateAllTables.up unless ActiveRecord::Base.connection.table_exists? 'foos'
  end

  config.after :each do
    ReuseQueryResults.storage.clear_all
    [Foo, Bar].each {|m| m.delete_all }
  end
end
