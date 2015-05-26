
require 'spec_helper'

module ReuseQueryResults
  describe Storage do
    describe Storage::Memory do
      def test_database_name
        Bar.connection.instance_variable_get(:'@config')[:database]
      end

      def alter_database_name
        AlterBar.connection.instance_variable_get(:'@config')[:database]
      end

      describe 'multi databases' do
        it 'fetch from cache from each databases' do
          allow(ReuseQueryResults.storage).to receive(:add).and_call_original
          expect(ReuseQueryResults.storage).to receive(:add).with(test_database_name, '#bars', anything, anything).once.and_call_original
          expect(ReuseQueryResults.storage).to receive(:add).with(alter_database_name, '#bars', anything, anything).once.and_call_original
          2.times { Bar.first.to_s }
          2.times { AlterBar.first.to_s }
        end

        it "does not clear by other database's same name table" do
          Bar.first
          AlterBar.create!
          expect(ReuseQueryResults.storage.databases[test_database_name]['#bars'].keys.size).to eq 1
        end
      end

      it 'cache result' do
        Foo.first
        expect(ReuseQueryResults.storage.databases[test_database_name]['#foos'].keys.size).to eq 1
      end

      it 'add result first time' do
        allow(ReuseQueryResults.storage).to receive(:add).and_call_original
        expect(ReuseQueryResults.storage).to receive(:add).with(test_database_name, '#foos', anything, anything).once.and_call_original
        Foo.first
      end

      it 'fetch from cache second time' do
        allow(ReuseQueryResults.storage).to receive(:add).and_call_original
        expect(ReuseQueryResults.storage).to receive(:add).with(test_database_name, '#foos', anything, anything).once.and_call_original
        2.times { Foo.first.to_s }
      end

      it 'clear cache when insert' do
        Foo.first
        Foo.create!
        expect(ReuseQueryResults.storage.databases[test_database_name]['#foos'].keys.size).to eq 0
      end

      it 'clear cache when delete' do
        Foo.create!
        Foo.first
        Foo.first.destroy
        expect(ReuseQueryResults.storage.databases[test_database_name]['#foos'].keys.size).to eq 0
      end

      it 'clear cache when update' do
        Foo.create!(name: 'new')
        Foo.first
        Foo.first.update_attributes!(name: 'updated')
        expect(ReuseQueryResults.storage.databases[test_database_name]['#foos'].keys.size).to eq 0
      end

      context 'with join' do
        it 'cache result' do
          Foo.joins(:bar).first
          key = ReuseQueryResults.tables_to_key(%w(foos bars))
          expect(ReuseQueryResults.storage.databases[test_database_name][key].keys.size).to eq 1
          expect(ReuseQueryResults.storage.databases[test_database_name]['#foos'].keys.size).to eq 0
          expect(ReuseQueryResults.storage.databases[test_database_name]['#bars'].keys.size).to eq 0
        end

        it 'clear cache when insert' do
          Foo.joins(:bar).first
          Foo.create!
          key = ReuseQueryResults.tables_to_key(%w(foos bars))
          expect(ReuseQueryResults.storage.databases[test_database_name][key].keys.size).to eq 0
        end
      end

      context 'with include' do
        it 'cache result' do
          Bar.create!(foo_id: Foo.create!)
          Foo.includes(:bar).first.bar
          expect(ReuseQueryResults.storage.databases[test_database_name]['#foos'].keys.size).to eq 1
          expect(ReuseQueryResults.storage.databases[test_database_name]['#bars'].keys.size).to eq 1
        end

        it 'clear cache when insert' do
          Foo.includes(:bar).first
          Foo.create!
          expect(ReuseQueryResults.storage.databases[test_database_name]['#foos'].keys.size).to eq 0
        end
      end
    end
  end
end
