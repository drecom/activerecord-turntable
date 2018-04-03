## activerecord-turntable 4.0.0 (unreleased) ##

### Major Changes

* Supported rails versions are
  * 5.0.0 to 5.0.5
  * 5.1.0 to 5.1.5
* Configuration
  * Added DSL configuration file: config/turntable.rb
* Added a new algorithm: `hash_slot`
  * distributes like redis cluster.
* Added a new sequencer: `katsubushi`
  * Support [katsubushi](https://github.com/kayac/go-katsubushi) as a sequencer backend.
* Support slave(read replica) connection. (Experimental feature)

### Incompatible changes

* `RangeAlgorithm` is integrated to `RangeBsearchAlgorithm`.
* Changed `ConnectionProxy#with_master` behavior to `Fix connection to primary master database`.
  * Old `ConnectionProxy#with_master` behavior(default model connection) is renamed to `ConnectionProxy#with_default_shard`

### Internal Change

* Changed `AR::Base.turntable_configuration` to use `ActiveRecord::Turntable::Configuration` class instead of Hash.

## activerecord-turntable 3.1.0 ##

### Major Changes

* Support activerecord v5.1.x

### Bugfix

* Fix schema dumper to dump sequence table options correctly (activerecord >= 5.0.1)

## activerecord-turntable 3.0.1 ##

### Minor Changes

* Restore LogSubscriber log format to the same as 2.x

### Bugfixes

* Fix ActiveRecord 5.0.x compatibilities
  * Fixes SchemaDumper fails dumping sequence tables on v5.0.0
  * Follow AbstractAdapter#log implementation changes on v5.0.3
  * Fix QueryCache to work with v5.0.1 or later

## activerecord-turntable 3.0.0 ##

### Bugfixes

* Fixes schema dumper patches that dumps tables options incorrectly.
* Re-enable the `AR::LogSubscriber::IGNORE_PAYLOAD_NAMES` (thx @misoobu)
* Make cluster transaction helpers to preserve transaction options(e.g. :requires_new)
* Fixes shard names are not written to logs correctly (thx @i2bskn)
* Fixes ConnectionNotEstablished Error with STI subclasses #48

### Improvements

* Update activerecord-import patches for performance improvements (thx @misoobu)


## activerecord-turntable 3.0.0.alpha3 ##

### Bugfix

* Disable statement cache when adding shard conditions automatically

## activerecord-turntable 3.0.0.alpha2 ##

### Improvement

* Fix to propagate shard conditions to `AssociationRelation` too

## activerecord-turntable 3.0.0.alpha1 ##

### Major Changes

* Rails5 compatibility
  * Minimum ruby requirement version is `2.2.2`
  * Rails 4.x support has been dropped.

## activerecord-turntable 2.5.0 ##

### Improvement

* Fix to propagate shard conditions to `AssociationRelation` too

## activerecord-turntable 2.4.0 ##

### Incompatible Change

* Drop support for ruby 1.9.3

### Bugfix

* Update activerecord 4.2 patches
  * Fixes optimistic locking with a serialized column causes JSON::Error.

## activerecord-turntable 2.3.3 ##

### Bugfix

* Fallback `sequence_name` to parent modules, because ar-import expects original `sequence_name` result(= nil)

## activerecord-turntable 2.3.2 ##

### Improvement

* ActiveRecord::Import follow ActiveRecord 5 (thx mitaku)

## activerecord-turntable 2.3.1 ##

### Improvement

* ConnectionProxy uses a method_missing, so it should adapt respond_to? (thx, misoobu)

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
