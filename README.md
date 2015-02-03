# ActiveRecord::Turntable

[![Gem Version](https://badge.fury.io/rb/activerecord-turntable.svg)](http://badge.fury.io/rb/activerecord-turntable)
[![Build Status](https://travis-ci.org/drecom/activerecord-turntable.svg?branch=master)](https://travis-ci.org/drecom/activerecord-turntable)
[![Dependency Status](https://gemnasium.com/drecom/activerecord-turntable.svg)](https://gemnasium.com/drecom/activerecord-turntable)
[![Coverage Status](https://coveralls.io/repos/drecom/activerecord-turntable/badge.png?branch=master)](https://coveralls.io/r/drecom/activerecord-turntable?branch=master)

ActiveRecord::Turntable is a database sharding extension for ActiveRecord.

## Dependencies

activerecord(>=4.0.0)

if you are using activerecord 3.x, please use activerecord-turntable version 1.x.

## Supported Database

Currently supports mysql only.

## Installation

Add to Gemfile:

```ruby
gem 'activerecord-turntable', '~> 2.1.1'
```

Run a bundle install:

```ruby
bundle install
```

Run install generator:

```bash
bundle exec rails g active_record:turntable:install
```

generator creates `#{Rails.root}/config/turntable.yml`

## Terminologies

### Shard

Shard is a database which is horizontal partitioned.

### Cluster

Cluster of shards. i.e) set of userdb1, userdb2, userdb3
Shards in the same cluster should have the same schema structure.

### Master

Default ActiveRecord::Base's connection.

### Sequencer

Turntable's sequence system for clustered database.

This keeps primary key ids to be unique each shards.

## Example

### Example Databases Structure

One main database(default ActiveRecord::Base connection) and
three user databases sharded by user_id.

```
                  +-------+
                  |  App  |
                  +-------+
                      |
       +---------+---------+---------+---------+
       |         |         |         |         |
  `--------` `-------` `-------` `-------` `-------`
  | Master | |UserDB1| |UserDB2| |UserDB3| | SeqDB |
  `--------` `-------` `-------` `-------` `-------`

```

### Example Configuration

Edit turntable.yml and database.yml. See below example config.

* example turntable.yml

```yaml
    development:
      clusters:
        user_cluster: # <-- cluster name
          algorithm: range_bsearch # <-- `range` or `range_bsearch`
          seq:
            user_seq: # <-- sequencer name
              seq_type: mysql # <-- sequencer type
              connection: user_seq_1 # <-- sequencer database connection setting
          shards:
            - connection: user_shard_1 # <-- shard name
              less_than: 100           # <-- shard range(like mysql partitioning)
            - connection: user_shard_2
              less_than: 200
            - connection: user_shard_3
              less_than: 2000000000

```

* database.yml

```yaml
    connection_spec: &spec
      adapter: mysql2
      encoding: utf8
      reconnect: false
      pool: 5
      username: root
      password: root
      socket: /tmp/mysql.sock

    development:
      <<: *spec
      database: sample_app_development
      seq: # <-- sequence database definition
        user_seq_1:
          <<: *spec
          database: sample_app_user_seq_development
      shards: # <-- shards definition
        user_shard_1:
          <<: *spec
          database: sample_app_user1_development
        user_shard_2:
          <<: *spec
          database: sample_app_user2_development
        user_shard_3:
          <<: *spec
          database: sample_app_user3_development
```

### Example Migration 

Generate a model:

```bash
bundle exec rails g model user name:string
```

And Edit migration file:

```ruby
class CreateUsers < ActiveRecord::Migration
  # Specify cluster executes migration if you need.
  # Default, migration would be executed to all databases.
  # clusters :user_cluster

  def change
    create_table :users do |t|
      t.string :name
      t.timestamps
    end
    create_sequence_for(:users) # <-- create sequence table
  end
end
```

Then please execute rake tasks:

```bash
bundle exec rake db:create
bundle exec rake db:migrate
```

Those rake tasks would be executed to shards too.

### Example Model

Add turntable [shard_key_name] to the model class:

```ruby
class User < ActiveRecord::Base
  turntable :user_cluster, :id
  sequencer
  has_one :status
end

class Status < ActiveRecord::Base
  turntable :user_cluster, :user_id
  sequencer
  belongs_to :user
end
```

## Usage

### Creating

```
    > User.create(name: "hoge")
      (0.0ms) [Shard: user_seq_1] BEGIN
      (0.3ms) [Shard: user_seq_1] UPDATE `users_id_seq` SET id=LAST_INSERT_ID(id+1)
      (0.8ms) [Shard: user_seq_1] COMMIT
      (0.1ms) [Shard: user_seq_1] SELECT LAST_INSERT_ID()
      (0.1ms) [Shard: user_shard_1] BEGIN
    [ActiveRecord::Turntable] Sending method: insert, sql: #<Arel::InsertManager:0x007f8503685b48>, shards: ["user_shard_1"]
      SQL (0.8ms) [Shard: user_shard_1] INSERT INTO `users` (`created_at`, `id`, `name`, `updated_at`) VALUES ('2012-04-10 03:59:42', 2, 'hoge', '2012-04-10 03:59:42')
      (0.4ms) [Shard: user_shard_1] COMMIT
    => #<User id: 2, name: "hoge", created_at: "2012-04-10 03:59:42", updated_at: "2012-04-10 03:59:42">
```

### Retrieving

```
    > user = User.find(2)
    [ActiveRecord::Turntable] Sending method: select_all, sql: #<Arel::SelectManager:0x007f850466e668>, shards: ["user_shard_1"]
      User Load (0.3ms) [Shard: user_shard_1] SELECT `users`.* FROM `users` WHERE `users`.`id` = 2 LIMIT 1
    => #<User id: 2, name: "hoge", created_at: "2012-04-10 03:59:42", updated_at: "2012-04-10 03:59:42">
```

### Updating

```
    > user.update_attributes(name: "hogefoo")
      (0.1ms) [Shard: user_shard_1] BEGIN
    [ActiveRecord::Turntable] Sending method: update, sql: UPDATE `users` SET `name` = 'hogefoo', `updated_at` = '2012-04-10 04:07:52' WHERE `users`.`id` = 2, shards: ["user_shard_1"]
      (0.3ms) [Shard: user_shard_1] UPDATE `users` SET `name` = 'hogefoo', `updated_at` = '2012-04-10 04:07:52' WHERE `users`.`id` = 2
      (0.8ms) [Shard: user_shard_1] COMMIT
    => true
```

### Delete

```
    > user.destroy
      (0.2ms) [Shard: user_shard_1] BEGIN
    [ActiveRecord::Turntable] Sending method: delete, sql: #<Arel::DeleteManager:0x007f8503677ea8>, shards: ["user_shard_1"]
      SQL (0.3ms) [Shard: user_shard_1] DELETE FROM `users` WHERE `users`.`id` = 2
      (1.7ms) [Shard: user_shard_1] COMMIT
    => #<User id: 2, name: "hogefoo", created_at: "2012-04-10 03:59:42", updated_at: "2012-04-10 04:07:52">
```

### Counting

```
    > User.count
    [ActiveRecord::Turntable] Sending method: select_value, sql: #<Arel::SelectManager:0x007f9e82ccebb0>, shards: ["user_shard_1", "user_shard_2", "user_shard_3"]
       (0.8ms) [Shard: user_shard_1] SELECT COUNT(*) FROM `users`
       (0.3ms) [Shard: user_shard_2] SELECT COUNT(*) FROM `users`
       (0.2ms) [Shard: user_shard_3] SELECT COUNT(*) FROM `users`
    => 1
```

## Sequencer

Sequencer provides generating global IDs.

Turntable has follow 2 sequencers currently:

* :mysql - Use database table to generate ids.
* :barrage - Use [barrage](https://github.com/drecom/barrage) gem to generate ids

### Mysql example

First, add configuration to turntable.yml and database.yml

* database.yml

```yaml
    development:
      ...
      seq: # <-- sequence database definition
        user_seq_1:
          <<: *spec
          database: sample_app_user_seq_development
```

* turntable.yml

```yaml
    development:
      clusters:
        user_cluster: # <-- cluster name
          ....
          seq:
            user_seq: # <-- sequencer name
              seq_type: mysql # <-- sequencer type
              connection: user_seq_1 # <-- sequencer database connection 
```

Add below to the migration:

```ruby
create_sequence_for(:users) # <-- this line creates sequence table named `users_id_seq`
```

Next, add sequencer definition to the model:

```ruby
  class User < ActiveRecord::Base
    turntable :id
    sequencer :user_seq # <-- this line enables sequencer module
    has_one :status
  end
```

### Barrage example

First, add barrage gem to your Gemfile:

```ruby
gem 'barrage'
```

Then, add configuration to turntable.yml:

* turntable.yml

```yaml
    development:
      clusters:
        user_cluster: # <-- cluster name
          ....
          seq:
            barrage_seq: # <-- sequencer name
              seq_type: barrage # <-- sequencer type
              options: # <-- options passed to barrage
                generators:
                  - name: msec
                    length: 39 # MAX 17.4 years from start_at
                    start_at: 1396278000000 # 2014/04/01 00:00:00 JST
                  - name: redis_worker_id
                    length: 16
                    ttl: 300
                    redis:
                      host: '127.0.0.1'
                  - name: sequence
                    length: 9
```

Next, add sequencer definition to the model:

```ruby
  class User < ActiveRecord::Base
    turntable :id
    sequencer :barrage_seq # <-- this line enables sequencer module
    has_one :status
  end
```

## Transactions
Turntable has some transaction support methods.

### shards_transaction

Pass AR::Base instances, `shards_transaction` method suitable shards

```ruby
user = User.find(2)
user3 = User.create(name: "hoge3")

User.shards_transaction([user, user3]) do
  user.name  = "hogehoge"
  user3.name = "hogehoge3"
  user.save!
  user3.save!
end
```

### cluster_transaction

transaction helper to execute transaction to all shards in the cluster:

```ruby
User.user_cluster_transaction do 
  # Transaction is opened all shards in "user_cluster" 
end
```

### Migration

If you specify cluster or shard, migration will be executed to the cluster(or shard) and master database.

Default, migrations will be executed to all databases.

to specify cluster:

```ruby
    class CreateUsers < ActiveRecord::Migration
      clusters :user_cluster
      ....
    end
```

to specify shard:

```ruby
    class CreateUsers < ActiveRecord::Migration
      shards :user_shard_01
      ....
    end
```

## Limitations

* Queries includes "ORDER BY", "GROUP BY" and "LIMIT" clauses cannot be distributed.
* "has many through" and "habtm" relationships may causes wrong results. ex) `User-Friend-User` relation


## TIPS

### Send query to a specific shard.

Use `with_shard` method:

```ruby
    AR::Base.connection.with_shard(shard1) do
      # something queries to shard1
    end
```

To access shard objects, use below:

* AR::Base.connection.shards # \\{shard_name => shard_obj,....}
* AR::Base#turntable_shard # Returns current object's shard
* AR::Base.connection.select_shard(shard_key_value) #=> shard

### Send query to all shards

Use with_all method:

```ruby
  User.connection.with_all do
    User.order("created_at DESC").limit(3).all
  end
```

### Connection Management

Rails's ConnectionManagement middleware keeps ActiveRecord's connection during the process is alive, but Turntable keeps more connections.
This may cause flooding max connections on your database. So, we made a middleware that disconnects on each request.

if you use turntable's ConnectionManagement middleware, add below line to your initializer.

```ruby
app.middleware.swap ActiveRecord::ConnectionAdapters::ConnectionManagement, ActiveRecord::Turntable::Rack::ConnectionManagement
```

### Performance Exception

To notice queries causing performance problem, Turntable has follow options.

* raise\_on\_not\_specified\_shard\_query - raises on queries execute on all shards
* raise\_on\_not\_specified\_shard\_update - raises on updates executed on all shards 


Add to turntable.yml:

```yaml
development:
   ....
   raise_on_not_specified_shard_query: true
   raise_on_not_specified_shard_update: true
```

## Thanks

ConnectionProxy, Distributed Migration implementation is inspired by Octopus and DataFabric.

## License

activerecord-turntable is released under the MIT license:

Copyright (c) 2012 Drecom Co.,Ltd.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
