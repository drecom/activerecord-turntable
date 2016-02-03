## activerecord-turntable 2.3.0 ##

### Features

* Support index hint

## activerecord-turntable 2.2.2 ##

### Bugfix

* Fix imcomplete bugfix for #30

## activerecord-turntable 2.2.1 ##

### Bugfix

* Fixes #30 undefined local variable with `db:structure:(dump|load)`

## activerecord-turntable 2.2.0 ##

### Features

* Add `modulo` algorithm (thx tatsuma)

### Improvements

* Add err detail to Building Fader exception log (thx tatsuma)

### Bugfixes

* Fix building cluster with mysql sequencer (fixes #25) (thx tatsuma)

### Documentation

* Fix seqeucner example (thx akicho8, tatsuma)

## activerecord-turntable 2.1.1 ##

### Bugfixes

* Fix `ActiveRecord::Fixtures` doesn't working
* Fix `ActiveRecord::Base.clear_active_connections!` to release connections established by turntable at development env

## activerecord-turntable 2.1.0 ##

Support activerecord 4.2.0

### Bugfixes

* Fix cluster helper methods(i.e xxxx_cluster_transaction helper) on lazy load environments(development, test)
* Move migration tasks as Migrator extension to fix rake actions(added by other gems) ordering problem

## activerecord-turntable 2.0.6 ##

### Bugfixes

* Fixes migration dsl:`clusters` is not working (thx macks)
* Fixes migration dsl:`shards` is not working

## activerecord-turntable 2.0.5 ##

### Bugfixes

* Fix not to destroy other database extension's connection proxy object

## activerecord-turntable 2.0.4 ##

Add dependency: ruby >= 1.9.3 from this release

### Bugfixes

* Fix incorrect insert sql with binary literal

## activerecord-turntable 2.0.3 ##

### Bugfixes

* Fix parse error on sql with binary string literal: ```x'...'```

## activerecord-turntable 2.0.2 ##

### Bugfixes

* Fix method definition bug on 2.0.1

## activerecord-turntable 2.0.1 ##

### Bugfixes

* support `update_columns`

## activerecord-turntable 2.0.0 ##

First release for ActiveRecord 4.x

### Incompatible Changes

#### Support ActiveRecord 4.x, drop support AR 3.x

If you are using AR 3.x, use turntable 1.x.

#### Default, Migration will be executed to all shards

Migration had been executed to only master database on turntable 1.x.

On turntable 2.x, migration is executed to all shards as default behavior.

#### Multiple Sequencer

Multiple sequencers supported.

Please pass sequencer's name Symbol to `sequencer` DSL:

```ruby
sequencer :user_seq
```

### Features

#### Barrage sequencer

Supported [barrage](http://github.com/drecom/barrage) gem as sequencer

#### Better association support

When using association(or association preloading), Turntable would add shard key condition to relation object if associated models has the same shard key name.

If two related models has different named keys(but same meaning), you can pass option `foreign_shard_key` to association option.

Example:

```ruby
class UserReceivedItemHistory < ActiveRecord::Base
  has_many :user, foreign_shard_key: :receiver_user_id
end
```

#### Exception on performance notice

On development environment, you can receive exception about queries that may cause a performance problem.

Add follow option to `turntable.yml`:

* raise\_on\_not\_specified\_shard\_query(default: false)
* raise\_on\_not\_specified\_shard\_update(default: false)

#### Add cluster transaction

To create transaction to all shards on the cluster:

```ruby
User.user_cluster_transaction do
  # transaction opened on all shards in 'user_cluster'
end
```

### Bugfixes

* Fix thread-safety bug


## activerecord-turntable 1.1.2 ##

*   Increase sequence table performance (by hanabokuro)

## activerecord-turntable 1.1.1 ##

*   Enable query caching

## activerecord-turntable 1.1.0 ##

*   AR::Base.clear_active_connections! should be proxied to all shards

*   Reduce unnecessary query when reloading


## activerecord-turntable 1.0.1 ##

*   Added missing setting for sequences at README and turntable.yml template.


## activerecord-turntable 1.0.0 ##

*   First Release!
