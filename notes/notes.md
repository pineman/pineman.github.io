## Sidekiq
* desperate sidekiq info for job
https://github.com/sidekiq/sidekiq/wiki/Pro-API/4b723ee5eed2e7a6d0599e0be8ea7a61525cfb7f
```
jid='a9289474f9f530885403c1d5'
Sidekiq::JobSet.find_job(jid)

Sidekiq::Queue.new.delete_by_class(MyWorker)
Sidekiq::RetrySet.new.scan("NoMethodError") { |job| job.delete }
Sidekiq::ScheduledSet.new.scan(jid) { |job| job.delete }
Sidekiq::DeadSet.new.scan("FTPWorker") { |job| ... }

Sidekiq::ScheduledSet.new.find_job(jid)
Sidekiq::RetrySet.new.find_job(jid)
Sidekiq::DeadSet.new.find_job(jid)
Sidekiq::Queue.new(queue_name).find_job(jid)

Sidekiq::Queue.new("default").to_a.map { _1.klass }.tally.sort_by{_2}
Sidekiq::ScheduledSet.new.to_a.map(&:klass).tally.sort_by{_2}
Sidekiq::RetrySet.new.to_a.map(&:klass).tally.sort_by{_2}
Sidekiq::BatchSet.new.to_a

# List of jobs for batch
Sidekiq::Batch.new('batch_id').jids

* `Sidekiq::Queue.new('default').filter_map { _1.args if _1.klass == 'someclass' }`
```
* print all running jobs:
```
Sidekiq::Workers.new.filter_map do |process_id, thread_id, work|
  "#{work.job.jid} #{work.job.klass}: #{work.job.args}" if work.queue == "default"
end
Sidekiq::Workers.new.filter_map do |process_id, thread_id, work|
  "#{work.job.jid} #{work.job.klass}: #{work.job.args}" if work.job.klass == "someclass"
end
Sidekiq::Workers.new.filter_map do |process_id, thread_id, work|
  work.job.klass if process_id.match?("^ampledash-worker-[0-9]")
end.tally
Sidekiq::Workers.new.filter do |process_id, thread_id, work|
  process_id.match?("^ampledash-worker-[0-9]")
end
Sidekiq::Workers.new.each do |process_id, thread_id, work|
  p "still running" if work.job.jid == "9c3713d49241d6f80ba94c42"
  p work if work.job.klass=="someclass"
end; nil
```
if a queue is overloaded, what is currently running from that queue? also need to check what is currently running on the worker that consumes that queue, since it might be busy with other queues work
```
Sidekiq::Workers.new.filter { |process_id, thread_id, work| work.queue == "default" }.map { JSON.parse(_3.payload)["class"] }.tally
```
* cancel batch: `Sidekiq::Batch.new(bid).invalidate_all`
* missing jobs:
  * death by oom?
  * jobs inside `batch.jobs { }` may be lost if an error occurs: The jobs method is atomic. All jobs created in the block are actually pushed atomically to Redis at the end of the block. If an error is raised, none of the jobs will go to Redis.
* `perform_bulk` promise seems like a lie, you need to worry about your batch size after all: https://github.com/amplemarket/ampledash/pull/6791
* https://github.com/sidekiq/sidekiq/wiki/Middleware#client-middleware-registered-in-both-places
* job_id is preserved through retries
* queue latency means: the age in seconds of the oldest job currently in the queue
* disable transactional push: https://github.com/amplemarket/ampledash/pull/25648/files (due to lib/utilities/sidekiq_transactional_client.rb)
* > If an individual job is rescheduled by the limiter more than 20 times (approximately one day with the default linear backoff), the OverLimit will be re-raised as if it were a job failure and the job retried as usual.
Use `max_limiter_retries` key in `sidekiq_options` to configure this to be more than 20.

## Ruby/rails
* `bin/rails db:setup == bin/rails db:create db:schema:load db:seed`
* `bin/rails db:create db:migrate db:seed`
* `bin/rails db:migrate:redo:primary VERSION=20230329094520`
* `bin/rails db:rollback:primary STEP=5`
* test if a particular url helper exists:
```
app # idk why we need this in dev, but it needs to load first
Rails.application.routes.url_helpers.dashboard_lead_list('some-id')
```
(in case you're skeptic of `rails routes`?)
* local debugging: write `debugger` at any code location
  - multi-line code eval: drop into irb with `irb`
* prod console debugging:
  - install `debug` gem from prod console:
```
gem_name = "debug"
`export DEBIAN_FRONTEND="noninteractive"; apt update -y && apt install -y build-essential && gem install #{gem_name}`
gem_folder_path = `gem which #{gem_name}`.strip.toutf8.gsub("#{gem_name}.rb", "")
$: << gem_folder_path
```
 - restart the console
 - use `binding.irb` instead of `debugger` (`debug command is only available when IRB is started with binding.irb`)
 - enter the debugger with `debug`
* `model.errors` or `model.assoc.errors` shows validation errors on non-bang .create, .update etc.
* debug log level in prod console: `Rails.logger.level = Logger::DEBUG` log_level
* SQL queries log in tests: check enable_sql_queries_log_in_tests.patch
* `ActiveRecord::Base.connected_to(role: :reading) { ... }`
* `ActiveRecord::Base.connection.execute("SELECT * FROM table")`
* Find all instances of a creation, search for at least:
* `Model.new + save`, `Model.build + save`, `Model.find_or_initialize + save`, `Model.create`, `Model.find_or_create`, `Model.insert`, `Model.upsert`, and from bulk import gem: `Model.import`, `Model.bulk_import`
* ActiveRecord queries like `Model.where()` are lazy loaded. So to avoid TOCTOU/concurrency issues, sprinkle `.load` at the end where appropriate
* Remember to handle Regexp::Timeout when using regexes!
* really big monkey patch code: upload to github gist (raw url) `eval(HTTP.get(url).body.to_s)`
* Remember Hash#exclude and Hash#slice
* `EDITOR=rubymine gem open <gem_name>`
* Memory leaks dump heap https://stevenharman.net/so-we-have-a-memory-leak
* rescue without explicit exception class will only catch exceptions that are descendants of StandardError. Use `rescue Exception => e`
* params: `p = params.permit(names: [])`. dont reuse the params var: `params = params.permit`. `params.permit!` allows all params and mutates the params var.
* https://edgeguides.rubyonrails.org/configuring.html#config-active-record-permanent-connection-checkout
* `IRB.conf[:USE_PAGER] = false`
* bulk insert and get model instances back
```
results = Model.insert_all(hashes_or_models, record_timestamps: true, returning: Arel.sql("*"))
models = results.map { |result| Model.instantiate(result) }
```
* default dict with arrays: `h = Hash.new { |h, k| h[k] = []}`
* `!model.timestamp&.after?(1.day.ago)` is not the same as `model.timestamp&.before?(1.day.ago)` if `model.timestamp == nil`!!
* parse json:
```
j = <<-'JSON'
{"my_json": 1}
JSON
JSON.parse(j)
```
* in `debugger`, can set breakpoints interactively:
```
* `b[reak] <file>:<line>` or `<file> <line>`
  * Set breakpoint on `<file>:<line>`.
* `b[reak] <class>#<name>`
   * Set breakpoint on the method `<class>#<name>`.
* `b[reak] <expr>.<name>`
   * Set breakpoint on the method `<expr>.<name>`.
```
this is useful to bypass proxy objects and stuff
* each_with_index vs each.with_index (use .with_index): https://stackoverflow.com/questions/20258086/difference-between-each-with-index-and-each-with-index-in-ruby
* latency chart: https://gist.github.com/nateberkopec/03cdbe26578fe1d1add2db7f4867ec38
* `bin/rails db:test:prepare` when the test db is borked
* one liners: `| ruby -ne 'puts $_.split(?()[0]'`
* see `~/work/personal/test_controller.rb` on how to run an action without copy pasting, test controller (using `ActionDispatch::TestRequest` and `ActionDispatch::Response.new`)
* `with_lock` reloads the model object!!!!!
* reloads inside callbacks make `changes` (before_* callbacks) and `previous_changes` (after_* callbacks) disappear!! which will cause the next defined callbacks to not run if they're using changes or previous_changes for conditional!
* do not define two callbacks with the same method name. use a -> { lambda }. https://code.jjb.cc/you-can-t-declare-after_-_commit-or-after_commit-callbacks-for-the-same-method-more-than-once
* keyset pagination: instead of using the offset of limit... offset, we basically give the offset in the WHERE, so psql can jump straight to it using a BTree index.
* gem for postgresql cursors: https://github.com/afair/postgresql_cursor
* `retry` seems like a good idea but it's an infinite loop waiting to happen. always bound it with retries
* preload associations for already loaded models: `ActiveRecord::Associations::Preloader.new(records:, associations: [:assoc_1, assoc_2: [:nested_assoc]).call`


## RSpec
* run one test only: `rspec ./spec/controllers/groups_controller_spec.rb:42`
* `-P '**/*some_class_spec*'`
* `-E 'when something'`
* tests: 
 - let, before: reinitialize before each example
 - let_it_be, before_all: one-time for each context (many examples)
 - let vs let!: lazy vs eager 
* `expect(Class).to receive(:call).exactly(3).times.and_return({result: "invalid"})`
* sometimes tests take a while to start because they're running migrations!!!
* can define 'it' blocks dynamically for test cases

## Postgres
* REMEMBER \e for vim editor mode
* remember \copy (client-side COPY)
* `\d+ table_name` shows foreign keys pointing to table_name (referenced_by)
* count number of rows fast estimate:
SELECT reltuples AS estimate FROM pg_class where relname = 'mytable';
* long running queries. note "state='active'"!!
```sql
SELECT *, (now() - query_start) AS running_time
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '1 minutes' AND state='active' ORDER BY running_time DESC;
```
* psql: select DATE(<timestamp like created_at>) as day order by day
* postgres: create replication slot - saves LSN at time x. do a base backup to get to time x. enable replication to sync starting from time x.
* select sample of table `SELECT m.id,m.nylas_message_id,e.nylas_id,e.is_bounce FROM message_sent_records m TABLESAMPLE SYSTEM ((100000 * 100) / 37000000.0) inner join email_messages e on m.nylas_message_id = e.nylas_id where e.is_bounce is true;`
* EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, SETTINGS, FORMAT JSON)
* Materialize node: https://stackoverflow.com/a/3029903 - found this on a plan that didn't have an index on the join key (users left join on sent_emails.user_key)
* REINDEX INDEX CONCURRENTLY takes some logs. it blocks deletion of foreign keys pointing to the table being indexed, or a create table with a FK pointing to the table being indexed.
* alter table in tables running autovacuum mega super locks
* https://philbooth.me/blog/nine-ways-to-shoot-yourself-in-the-foot-with-postgresql - written in the negative, so you should do the reverse
always add indexes to foreign keys:
Postgres doesn't automatically create indexes for foreign keys. This may come as a surprise if you're more familiar with MySQL, so pay attention to the implications as it can hurt you in a few ways. The most obvious fallout from it is the performance of joins that use a foreign key. But those are easily spotted using EXPLAIN, so are unlikely to catch you out. Less obvious perhaps is the performance of ON DELETE and ON UPDATE behaviours. If your schema relies on cascading deletes, you might find some big performance gains by adding indexes on foreign keys.
* Rule of thumb: any lock acquired in a transaction is held until the very end of this transaction. It is released only when the transaction finishes, with either COMMIT or ROLLBACK.
* psql from a shell script: `psql -qtAX`
* anti-join: stuff in A not in B
* semi-join: only need one row "joined" 
* `UPDATE table SET column = false` will update ALL rows, even those that are false already - so the query will take a long time and generate a lot of WAL.
* `DISTINCT ON`: pull a different column from a group by agg:
```
SELECT DISTINCT ON (url) url, request_duration
FROM logs
ORDER BY url, timestamp DESC
```
* Index Scans are NOT Index Only Scans!!!!!!!!!!!
* GIN: Generalized INverted index. Designed for handling cases where multiple values are stored in a single column (arrays, jsonb, full-text search).
* GiST: Generalized Search Tree. Crazy stuff like quad trees and geo data.
* deadlocks: often because different clients update the same rows in different orders. doing .sort on e.g. the ids of rows to update should help
* in an UPDATE targeting many rows such as:
UPDATE "collected_signatures" SET "updated_at" = ... WHERE "collected_signatures"."signature_owner_email" = 'vip@ueni.com';
if two of these quries run in parallel, each will take locks one by one on each of the affected rows - and hold them until transaction commit. since there's no explicit order by, the ordering of the locks wont be deterministic, and so the queries can deadlock.
* see '/Users/pineman/Documents/personal/Row Level Locks in RC.mhtml' for a disucssion on why row level locks even exist
* pg_repack, or: pgcompacttable?
from https://news.ycombinator.com/item?id=41838592:
pg_repack can generate a lot of WAL, which can generate so much traffic that standby servers can fall behind too much and never recover.
We've been using https://github.com/dataegret/pgcompacttable to clean up bloat without impacting stability/performance as much as pg_repack does.
this may be through the --delay-ratio option, from the readme:
tables are processed with adaptive delays to prevent heavy IO and replication lag spikes (see --delay-ratio option)
* `drop index` inside transaction holds AccessExclusiveLock globally during the txn (so the general rule that locks are held to the end of the txn is true)
* https://x.com/samokhvalov/status/1974735523009687663
* https://x.com/samokhvalov/status/1975081800969105462: at planning time for a query, Postgres locks all tables participating in the query and all their indexes, and as we remember, these locks will be released only at COMMIT or ROLLBACK.
* nice summary on the downsides of too many indexes: write amplification, the loss of HOT updates (for previously unindexed columns), and increased competition for space in shared_buffers.
* updates on non-indexed columns can be HOT if theres enough space on the page. fillfactor helps here. otherwise, updates create new tuple versions. check fillfactor with `SELECT * FROM pg_stat_user_tables WHERE relname='gmail_accounts';`
* Bloat on UPDATES

| Operation       | How it's Affected by Dead Tuples (Bloat)            | Visibility Check Process                     |
| --------------- | --------------------------------------------------- | -------------------------------------------- |
| Table Scan      | High Impact. Must read every tuple (live            | Checks xmin/xmax of every tuple              |
|                 | and dead) from disk and perform a visibility        | against the transaction snapshot.            |
|                 | check on all of them, discarding the dead ones.     |                                              |
|                 |                                                     |                                              |
| Index Scan      | Low Impact. The index points directly to the new,   | Jumps directly to the live tuple's location  |
|                 | live tuple, bypassing all old, dead versions of     | (ctid) and performs a visibility check only  |
|                 | that row.                                           | on that single tuple.                        |
|                 |                                                     |                                              |
| Index-Only Scan | Low Impact. Doesn't visit the heap at all if the    | Checks the Visibility Map first. If the      |
|                 | page is marked "all-visible" in the Visibility Map. | page is "all-visible," no heap fetch or      |
|                 |                                                     | per-tuple check is needed. Otherwise, it     |
|                 |                                                     | must visit the heap.                         |


* max_standby_streaming_delay: It doesn't matter if we see the replica lag chart go to +30m. What matters is if the chart never goes to 0 in 30 consecutive minutes. It might not be a single slow query but many consecutive  slow ones that never allow the replica to catch up on the WAL.
* autovacuum tweaks: `WITH (autovacuum_analyze_scale_factor='0.01', autovacuum_analyze_threshold='1000', autovacuum_vacuum_scale_factor='0.01', autovacuum_vacuum_threshold='1000');`, autovacuum_vacuum_cost_delay, maintenance_work_mem
* multiXact space exhaustion (not just ids!) https://metronome.com/blog/root-cause-analysis-postgresql-multixact-member-exhaustion-incidents-may-2025 - is this untrackable on cloud sql, excepting logs?

## Analytics, CDC
https://github.com/sequinstream/sequin
debezium ok but you need kafka
what's the best solution to move data from your oltp postgresql into... everywhere else? an olap db, ETL, snowflake?

## Elastic
Fetch a document (get_doc)
```
def person_doc(id)
  Searchkick.client.get(index: Person.searchkick_index.name, id:)["_source"]
end
doc = person_doc(person_id)
def company_doc(id)
  Searchkick.client.get(index: Company.searchkick_index.name, id:)["_source"]
end
or Person.searchkick_index.retrieve(Person.new(id: person_id))
```
Update a document directly
```
Person.search('*', where: { company_domain: "youtube.com"}).pluck(:id).each { |id|
  doc = person_doc(id)
  doc["excluded_domains_accounts"] = []
  Searchkick.client.update(
    index: Person.searchkick_index.name,
    id: person_id,
    body: { doc: doc }
  )
}
```
By default, simply adding the call 'searchkick' to a model will do an unclever indexing of all fields (but not has_many or belongs_to attributes).
In practice, you'll need to customize what gets indexed. This is done by defining a method on your model called search_data

properties in a document (in an index) can have many fields.

kibana dev tools console. explain
 * doc id is required argument: `GET people_development/_explain/018e8b42-4339-788c-bb6a-81b2553e7202`
 * can also pass `explain: true` or `debug: true` to searchkick methods like `Person.search(..., debug: true)` - tho it seems `explain: true` also fails generally and probably needs just one doc?

* match query on a text field is not like a wildcard. e.g. match "mymatch" does not match "anothermymatchtest", as the analyzer, tokenizer, stemming, etc. runs. 
  
profile: include `"profile": true` in query
more results: include `"size": 1000` in query

* Searchkick.client.cat.indices.split("\n")

* refresh interval: https://www.elastic.co/guide/en/elasticsearch/reference/current/near-real-time.html

* Person.searchkick_index.total_docs

* Person.first.reindex(mode: :inline)

* get all 
```
GET _cat/indices?v
```

* When adding a new field to elastic, the mappings must be updated:
```
PUT /people_staging/_mapping
{
    "properties": {
        "seniorities_classifier": {
          "type": "keyword"
        }
    }
}
```

## React / frontend
* react-query is good
* usehook-ts is good: common goodies like useDebouncedCallback and useResizeObserver
* `screen.debug()` for jest-dom tests
* `useState` inside some other hook attaches state to the parent container that called the hook
* Remeber functional components are just functions. On re-renders, everything defined inside the component is re-defined again, including functions. `useCallback` persists functions across re-renders - useful for e.g. debouncing using debounce from lodash which saves state inside it
* typescript: `typeof`, `ReturnType`, `Pick<>`, `<TData extends object>({keys}: AnotherType<TData>) => {`, see https://github.com/amplemarket/ampledash/pull/8341
* jest tests fail on unmocked requests: `apiDashboardMock.onAny().reply(() => { throw new Error('unhandled request')});`

## Chrome extension
 - chrome.runtime.onMessage.addListener https://developer.chrome.com/docs/extensions/develop/concepts/messaging#responses

## Honeycomb
* honeycomb real actual count without compensating for sampling: insert /usage/ before /result/ in a query url
https://docs.honeycomb.io/manage-data-volume/usage-center/#usage-mode
https://ui.honeycomb.io/amplemarket/environments/production/datasets/worker/usage/result/JCJAthkPp6q
https://ui.honeycomb.io/amplemarket/environments/production/datasets/worker/result/JCJAthkPp6q
* where db.statement contains name_frequencies
* group by root.messaging.sidekiq.job_class
* DNS queries, async tasks are not captured in honeycomb traces (so they may cause big gaps)

## k8s
### k9s
https://k9scli.io/topics/commands/
 * view resource (pods, configmaps, ...) in namespace: `:<resource> <namespace>` e.g. `:pods core`

## Karafka
* partitions are assigned to worker threads
* producing to topics silently fails if the topic has less than min.insync.replicas (topic or cluster wide config)
* kafka.tools.GetOffsetsTool has been renamed: bin/kafka-get-offsets.sh --broker-list 10.74.3.196:9092 --topic collected_contacts_reindex --time -2  https://github.com/apache/kafka/pull/13321#issuecomment-2058597443
```
kafkacat -b 10.74.3.196:9092 -t collected_contacts_reindex -p 6 -o beginning -C -e
kafkacat -b 10.74.3.196:9092 -t collected_contacts_reindex -p 6 -o end -C -e
./kafka-get-offsets.sh  --broker-list 10.74.3.196:9092 --topic collected_contacts_reindex --time -1
./kafka-get-offsets.sh  --broker-list 10.74.3.196:9092 --topic collected_contacts_reindex --time -2
```
* manually import a message:
```
require "avro_turf/messaging"
AVRO = AvroTurf::Messaging.new(
  registry_url: ENV.fetch("KAFKA_SCHEMA_REGISTRY")
)
data = [AVRO.decode(Base64.decode64('string from kafka-ui'))]
```
* Maximum poll interval (300000ms) exceeded by 255ms error: https://github.com/karafka/karafka/wiki/Pro-Long-Running-Jobs

## Misc
* search sentry by lots of tags: `user.email:a@a.com`, `jid:sadhfoqshr`, ... - useful if you want a stack trace of an error you found in logs
* base: T1, new: T2. speedup %: T1/T2-1. if negative, its a slowdown.
* DNS: MX record resolution will follow CNAME, as will A records, automatically.
* slack: shift+esc to mark all as read
* `pip install csvkit; mise reshim; csvcut -c 2 file.csv`
* Typhoeus::Config.verbose = true
* pretty print html: `puts Nokogiri::XML(html_string, &:noblanks).to_xml(indent: 2)`
* remember the `timeout` shell command

## Agents
### Claude
 - `\` followed by enter for newline
 - Ctrl-g to edit in $EDITOR
