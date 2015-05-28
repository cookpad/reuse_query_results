# ReuseQueryResults
Improve development environment speed.
Reuse query results and clear cache when insert update and delete record.
No more db requests.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reuse_query_results', git: 'https://github.com/cookpad/reuse_query_results'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reuse_query_results

## Usage
run command on development environment .
```
REUSE_QUERY_RESULTS=1 rails server
```

Can share update status between separated applications.
```ruby
# initializers/reuse_query_results.rb
memcache = ActiveSupport::Cache.lookup_store(:dalli_store, address)
ReuseQueryResults.storage = ReuseQueryResults::Storage.new(sync_client: memcache)

```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/reuse_query_results/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
