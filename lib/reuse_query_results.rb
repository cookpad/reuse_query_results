require "reuse_query_results/version"
require "reuse_query_results/storage"

module ReuseQueryResults
  class << self
    def storage
      @storage ||= Storage::Memory.new
    end


    def cache(connection, sql, &block)
      database = connection.instance_variable_get(:'@config')[:database]
      case sql.strip
      when (/\AINSERT INTO (?:\.*[`"]?([^.\s`"]+)[`"]?)*/i)
        return storage.clear_and_execute(database, $1, &block)
      when (/\ADELETE FROM (?:\.*[`"]?([^.\s`"]+)[`"]?)*/i)
        return storage.clear_and_execute(database, $1, &block)
      when (/\AUPDATE (?:\.*[`"]?([^.\s`"]+)[`"]?)*/i)
        return storage.clear_and_execute(database, $1, &block)
      when (/\ASELECT\s+.*FROM\s+"?([^\.\s'"]+)"?/im)
        return storage.fetch_or_execute(database, sql_to_key(sql), sql, &block)
      end
      block.call
    end

    def sql_to_key(sql)
      tables = sql.scan(/(?:FROM|JOIN)\s+[`"]?([^\.\s'`"]+)(?:[`"]?)/).flatten
      tables_to_key(tables)
    end

    def tables_to_key(tables)
      tables.sort.map {|table| "##{table}" }.join(' ')
    end
  end
end

begin
  require 'rails'
  require_relative 'reuse_query_results/railtie'
rescue LoadError
  require_relative "reuse_query_results/active_record_monkey_patch"
end
