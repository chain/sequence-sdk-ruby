# frozen_string_literal: true

require_relative '../spec_helper'

describe Sequence::Client do
  describe '#new' do
    context 'with valid options' do
      it 'instantiates the client' do
        credential = ENV['SEQCRED']
        ledger_name = ENV.fetch('LEDGER_NAME', 'test')

        ledger = Sequence::Client.new(
          credential: credential,
          ledger_name: ledger_name,
        )

        expect(ledger.opts[:credential]).to eq(credential)
        expect(ledger.opts[:ledger_name]).to eq(ledger_name)
      end
    end

    context 'when missing :ledger_name' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: 'foo')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when nil :ledger_name' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: 'foo', ledger_name: nil)
        }.to raise_error(ArgumentError)
      end
    end

    context 'when blank :ledger_name' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: 'foo', ledger_name: '')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when missing :credential' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(ledger_name: 'foo')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when nil :credential' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: nil, ledger_name: 'foo')
        }.to raise_error(ArgumentError)
      end
    end

    context 'when blank :credential' do
      it 'raises argument error' do
        expect {
          Sequence::Client.new(credential: '', ledger_name: 'foo')
        }.to raise_error(ArgumentError)
      end
    end
  end
end
