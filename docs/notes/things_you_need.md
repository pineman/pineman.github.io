inspired by https://goncalo.mendescabrita.com/notes/things-you-should-definitely-do-in-a-greenfield-application/

 - dns caching on your cluster's nodes; maybe in your app
 - compression on your load balancer
 - handle ssrf (see https://github.com/arkadiyt/ssrf_filter)
 - postgres-lock-logger
 - alerts on sidekiq poison pill
 - pganalyze is sweet
 - querytags in all queries
 - low statement_timeout, idle_in_transaction_session_timeout, lock_timeout, transaction_timeout, idle_session_timeout
 - you'll need a connection pooler eventually
 - maybe autovacuum killer?
 - something to reindex old indexes
 - maybe sometimes a good ole pg_squeeze
 - solid_cache as a scratchpad on your DB is very useful
 - queues and workers based on job latency SLA. HPA on that same metric.
 - you'll eventually need transactional push with bulk support (sorry sidekiq)
 - sentry is cool but if you're not self hosting it needs to be heavily limited
 - logs/traces/metrics are all useful, so is having redis, kafka, debezium, dagster, different analytics DB, ...
