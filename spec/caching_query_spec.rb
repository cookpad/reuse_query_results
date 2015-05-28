
require 'spec_helper'

module ReuseQueryResults
  describe Storage do
    before do
      ReuseQueryResults.storage = ReuseQueryResults::Storage.new
    end

    def test_database_name
      Bar.connection.instance_variable_get(:'@config')[:database]
    end

    def alter_database_name
      AlterBar.connection.instance_variable_get(:'@config')[:database]
    end

    describe 'multi databases' do
      it 'fetch from cache from each databases' do
        allow(ReuseQueryResults.storage).to receive(:add).and_call_original
        expect(ReuseQueryResults.storage).to receive(:add).with(test_database_name, %w(bars), anything, anything).once.and_call_original
        expect(ReuseQueryResults.storage).to receive(:add).with(alter_database_name, %w(bars), anything, anything).once.and_call_original
        2.times { Bar.first.to_s }
        2.times { AlterBar.first.to_s }
      end

      it "does not clear by other database's same name table" do
        Bar.first
        AlterBar.create!
        expect(ReuseQueryResults.storage.databases[test_database_name][%w(bars)].keys.size).to eq 1
      end
    end

    it 'cache result' do
      Foo.first
      expect(ReuseQueryResults.storage.databases[test_database_name][%w(foos)].keys.size).to eq 1
    end

    it 'add result first time' do
      allow(ReuseQueryResults.storage).to receive(:add).and_call_original
      expect(ReuseQueryResults.storage).to receive(:add).with(test_database_name, %w(foos), anything, anything).once.and_call_original
      Foo.first
    end

    it 'fetch from cache second time' do
      allow(ReuseQueryResults.storage).to receive(:add).and_call_original
      expect(ReuseQueryResults.storage).to receive(:add).with(test_database_name, %w(foos), anything, anything).once.and_call_original
      2.times { Foo.first.to_s }
    end

    it 'clear cache when insert' do
      Foo.first
      Foo.create!
      expect(ReuseQueryResults.storage.databases[test_database_name][%w(foos)].keys.size).to eq 0
    end

    it 'clear cache when delete' do
      Foo.create!
      Foo.first
      Foo.first.destroy
      expect(ReuseQueryResults.storage.databases[test_database_name][%w(foos)].keys.size).to eq 0
    end

    it 'clear cache when update' do
      Foo.create!(name: 'new')
      Foo.first
      Foo.first.update_attributes!(name: 'updated')
      expect(ReuseQueryResults.storage.databases[test_database_name][%w(foos)].keys.size).to eq 0
    end

    context 'with join' do
      it 'cache result' do
        Foo.joins(:bar).first
        expect(ReuseQueryResults.storage.databases[test_database_name][%w(bars foos)].keys.size).to eq 1
        expect(ReuseQueryResults.storage.databases[test_database_name][%w(foos)].keys.size).to eq 0
        expect(ReuseQueryResults.storage.databases[test_database_name][%w(bars)].keys.size).to eq 0
      end

      it 'clear cache when insert' do
        Foo.joins(:bar).first
        Foo.create!
        expect(ReuseQueryResults.storage.databases[test_database_name][%w(bars foos)].keys.size).to eq 0
      end
    end

    context 'with join' do
      it 'cache result' do
        Bar.create!(foo_id: Foo.create!.id)
        Foo.joins(:bar).first
        expect(ReuseQueryResults.storage.databases[test_database_name][%w(bars foos)].keys.size).to eq 1
      end

      it 'clear cache when insert' do
        Foo.joins(:bar).first
        Foo.create!
        expect(ReuseQueryResults.storage.databases[test_database_name][%w(bars foos)].keys.size).to eq 0
      end
    end

    describe 'sync mode' do
      let(:sync_client_mock) do
        double(:sync_client).tap do |client|
          client.stub(:clear)
        end
      end

      before do
        ReuseQueryResults.storage = ReuseQueryResults::Storage.new(sync_client: sync_client_mock)
        allow(sync_client_mock).to receive(:write)
        allow(sync_client_mock).to receive(:read)
        allow(ReuseQueryResults.storage).to receive(:add).and_call_original
      end

      it 'sync mode' do
        expect(ReuseQueryResults.storage).to be_sync_mode
      end

      it 'update timestamp' do
        expect(sync_client_mock).to receive(:write).with("#{test_database_name}+foos", kind_of(Numeric))
        Foo.create!
      end

      it 'does not reuse query when table updated' do
        expect(ReuseQueryResults.storage).to receive(:add).with(test_database_name, %w(foos), anything, anything).twice.and_call_original
        sync_client_mock.stub(:read).with("#{test_database_name}+foos") { (Time.now + 1.day).to_i }
        2.times { Foo.first }
      end

      it 'reuse query when table no updated' do
        expect(ReuseQueryResults.storage).to receive(:add).with(test_database_name, %w(foos), anything, anything).once.and_call_original
        sync_client_mock.stub(:read).with("#{test_database_name}+foos") { (Time.now - 1.day).to_i }
        2.times { Foo.first }
      end

      describe 'joinned table' do
        it 'does not reuse query when table updated' do
          expect(ReuseQueryResults.storage).to receive(:add).with(test_database_name, %w(bars foos), anything, anything).twice.and_call_original
          sync_client_mock.stub(:read).with("#{test_database_name}+bars") { (Time.now + 1.day).to_i }
          2.times { Foo.joins(:bar).first }
        end

        it 'reuse query when table no updated' do
          expect(ReuseQueryResults.storage).to receive(:add).with(test_database_name, %w(bars foos), anything, anything).once.and_call_original
          sync_client_mock.stub(:read).with("#{test_database_name}+bars") { (Time.now - 1.day).to_i }
          2.times { Foo.joins(:bar).first }
        end
      end
    end

  end
end
