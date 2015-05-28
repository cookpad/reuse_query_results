module ReuseQueryResults
  class Storage
    attr_reader :databases
    def initialize(sync_client: nil)
      @sync_client = sync_client
      clear_all
    end

    def add(database, tables, sql, result)
      @databases[database][tables][sql] = { data: result, timestamp: Time.now.to_i }
    end

    def clear_all
      @databases = Hash.new do |h, k| 
        h[k] = Hash.new { |h2, k2| h2[k2] = {} }
      end
      return unless sync_mode?
      @sync_client.clear
    end

    def clear(database, table)
      @databases[database].keys.select { |tables|
        tables.include?(table)
      }.each { |tables| 
        @databases[database][tables] = {}
      }
      return unless sync_mode?
      update_modified_timestamp(database, table)
    end

    def fetch_or_execute(database, tables, sql, &block)
      cached_result = fetch(database, tables, sql)
      if cached_result
        Rails.logger.debug("REUSE CACHE: #{sql}")
        return cached_result
      end
      block.call.tap { |result| add(database, tables, sql, result) }
    end

    def clear_and_execute(database, table, &block)
      clear(database, table)
      block.call
    end

    def fetch(database, tables, sql)
      result = @databases[database][tables][sql]
      return nil unless result
      return result[:data] unless sync_mode?
      return updated?(database, tables, result[:timestamp]) ? nil : result[:data]
    end

    def sync_mode?
      !!@sync_client
    end

    def update_modified_timestamp(database, table)
      @sync_client.write("#{database}+#{table}", Time.now.to_i)
    end

    def updated?(database, tables, cached_timestamp)
      tables.any? do |table|
        next unless updated_timestamp = @sync_client.read("#{database}+#{table}")
        next if updated_timestamp < cached_timestamp
        next true
      end
    end
  end
end
