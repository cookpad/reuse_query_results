module ReuseQueryResults
  class Railtie < ::Rails::Railtie
    initializer 'resque_query_results', after: 'active_record.initialize_database' do
      ActiveSupport.on_load :active_record do
        Rails.logger.info("load reuse_query_results")
        require_relative "active_record_monkey_patch" if ENV["REUSE_QUERY_RESULTS"] && Rails.env.development?
      end
    end
  end
end
