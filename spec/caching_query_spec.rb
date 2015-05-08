
require 'spec_helper'

module ReuseQueryResults
  describe Storage do
    describe Storage::Memory do
      it 'cache result' do
        Foo.first
        expect(ReuseQueryResults.storage.tables['#foos'].keys.size).to eq 1
      end

      it 'add result first time' do
        allow(ReuseQueryResults.storage).to receive(:add).and_call_original
        expect(ReuseQueryResults.storage).to receive(:add).with('#foos', anything, anything).once.and_call_original
        Foo.first
      end

      it 'fetch from cache second time' do
        allow(ReuseQueryResults.storage).to receive(:add).and_call_original
        expect(ReuseQueryResults.storage).to receive(:add).with('#foos', anything, anything).once.and_call_original
        2.times { Foo.first.to_s }
      end

      it 'clear cache when insert' do
        Foo.first
        Foo.create!
        expect(ReuseQueryResults.storage.tables['#foos'].keys.size).to eq 0
      end

      it 'clear cache when delete' do
        Foo.create!
        Foo.first
        Foo.first.destroy
        expect(ReuseQueryResults.storage.tables['#foos'].keys.size).to eq 0
      end

      it 'clear cache when update' do
        Foo.create!(name: 'new')
        Foo.first
        Foo.first.update_attributes!(name: 'updated')
        expect(ReuseQueryResults.storage.tables['#foos'].keys.size).to eq 0
      end

      context 'with join' do
        it 'cache result' do
          Foo.joins(:bar).first
          key = ReuseQueryResults.tables_to_key(%w(foos bars))
          expect(ReuseQueryResults.storage.tables[key].keys.size).to eq 1
          expect(ReuseQueryResults.storage.tables['#foos'].keys.size).to eq 0
          expect(ReuseQueryResults.storage.tables['#bars'].keys.size).to eq 0
        end

        it 'clear cache when insert' do
          Foo.joins(:bar).first
          Foo.create!
          key = ReuseQueryResults.tables_to_key(%w(foos bars))
          expect(ReuseQueryResults.storage.tables[key].keys.size).to eq 0
        end
      end

      context 'with include' do
        it 'cache result' do
          Bar.create!(foo_id: Foo.create!)
          Foo.includes(:bar).first.bar
          expect(ReuseQueryResults.storage.tables['#foos'].keys.size).to eq 1
          expect(ReuseQueryResults.storage.tables['#bars'].keys.size).to eq 1
        end

        it 'clear cache when insert' do
          Foo.includes(:bar).first
          Foo.create!
          expect(ReuseQueryResults.storage.tables['#foos'].keys.size).to eq 0
        end
      end
    end
  end
end
