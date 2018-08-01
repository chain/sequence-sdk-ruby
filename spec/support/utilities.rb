# frozen_string_literal: true

module Utilities
  def chain
    RSpec.configuration.sequence_client
  end

  def create_id(name)
    "#{name}-#{SecureRandom.uuid}"
  end

  def create_key
    chain.keys.create(id: create_id('key'))
  end

  def create_flavor(name, opts = {})
    chain.flavors.create(
      opts.merge(
        id: create_id(name),
        key_ids: [create_key.id],
        quorum: 1
      )
    )
  end

  def create_account(name, opts = {})
    chain.accounts.create(
      opts.merge(
        id: create_id(name),
        key_ids: [create_key.id],
        quorum: 1
      )
    )
  end

  def create_tx_feed(type, flavors)
    filter = flavors.map { |a| "flavor_id='#{a.id}'" }.join(' OR ')
    chain.feeds.create(
      id: create_id(type),
      type: 'transaction',
      filter: "actions(type='#{type}' AND (#{filter}))"
    )
  end

  def create_action_feed(type, flavors)
    filter = flavors.map { |a| "flavor_id='#{a.id}'" }.join(' OR ')
    chain.feeds.create(
      id: create_id(type),
      type: 'action',
      filter: "type='#{type}' AND (#{filter})"
    )
  end

  def create_tags(name)
    { name => SecureRandom.uuid }
  end

  def issue(amount, flavor, account, opts = {})
    chain.transactions.transact do |b|
      b.issue(
        opts.merge(
          amount: amount,
          flavor_id: flavor.id,
          destination_account_id: account.id
        )
      )
    end
  end

  def transfer(amount, flavor, source, destination, opts = {})
    chain.transactions.transact do |b|
      b.transfer(
        opts.merge(
          amount: amount,
          flavor_id: flavor.id,
          destination_account_id: destination.id,
          source_account_id: source.id
        )
      )
    end
  end
end
