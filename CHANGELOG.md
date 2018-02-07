# Sequence Ruby SDK changelog

## 1.1.0 (20180206)

For full details on the 1.1 release,
[visit the Sequence changelog](https://dashboard.seq.com/docs/changelog#release-v1-1).

* Added support for setting a user-provided id on key and account objects.
* The `alias` field on key and account objects has been deprecated.
* The `ledger` field when creating an API client has been deprecated; the new
  field is named `ledger_name`.
* Added full support for listing and summing actions.

## 1.0.4 (20180119)

* Ruby >= 2.2 is required. We recommend upgrading to Ruby >= 2.3.
* New interface `ledger.actions.list` and `ledger.actions.sum` available.
  See https://dashboard.seq.com/docs/actions for more information.
* Invalid parameters raise `ArgumentError`s when creating or querying objects.
* Improved retry logic for network errors.
* `Sequence::Client` instances now use persistent TLS connections.
* Set lower HTTP timeouts. This can be configured. See below.
* Private interfaces more comprehensively annotated as YARD `@private`.
* Rubocop linting applied to source code.

```ruby
Sequence::Client.new(
  ledger: 'development',
  credential: '...'
  open_timeout: 1,
  read_timeout: 1,
  ssl_timeout: 1,
)
```

## 1.0.3 (20171020)

* Added support for new access control permissions. When creating a client, you
  now provide `ledger` and `credential` options to connect to a
  specific ledger.

  Authentication with the previous style of access tokens has been removed.

  See https://dashboard.seq.com/docs/5-minute-guide#instantiate-sdk-client for
  more information.

## 1.0.2 (20170922)

* Updated YARD doc strings

## 1.0.1 (20170921)

* Removed the `ttl` and `base_transaction` attributes from `Sequence::Transaction::Builder`.
