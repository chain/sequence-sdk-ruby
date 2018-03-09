# frozen_string_literal: true

module Utilities
  def chain
    RSpec.configuration.sequence_client
  end

  def create_alias(name)
    "#{name}-#{SecureRandom.uuid}"
  end

  def create_id(name)
    "#{name}-#{SecureRandom.uuid}"
  end

  def create_key
    chain.keys.create(alias: create_id('key'))
  end

  def create_asset(name)
    chain.assets.create(
      alias: create_alias(name),
      keys: [create_key],
      quorum: 1,
    )
  end

  def create_flavor(name, opts = {})
    chain.flavors.create(
      opts.merge(
        id: create_id(name),
        keys: [create_key],
        quorum: 1,
      ),
    )
  end

  def create_account(name, opts = {})
    chain.accounts.create(
      opts.merge(
        alias: create_id(name),
        keys: [create_key],
        quorum: 1,
      ),
    )
  end

  def create_refdata(name)
    { name => SecureRandom.uuid }
  end

  def issue_flavor(amount, flavor, account, opts = {})
    chain.transactions.transact do |b|
      b.issue(
        opts.merge(
          amount: amount,
          flavor_id: flavor.id,
          destination_account_id: account.id,
        ),
      )
    end
  end

  def issue(amount, asset, account, reference_data = {})
    chain.transactions.transact do |b|
      b.issue(
        amount: amount,
        asset_alias: asset.alias,
        destination_account_id: account.id,
        reference_data: reference_data,
      )
    end
  end

  def transfer(amount, asset, source, destination, reference_data = {})
    chain.transactions.transact do |b|
      b.transfer(
        amount: amount,
        asset_alias: asset.alias,
        destination_account_id: destination.id,
        reference_data: reference_data,
        source_account_alias: source.alias,
      )
    end
  end
end
