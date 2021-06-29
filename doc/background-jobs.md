# Background jobs

We use use Sidekiq (backed by Redis) to handle sending emails. See 
[ADR9](/doc/architecture/decisions/0009-use-sidekiq-and-redis-to-send-emails.md).
This might be expanded to handle other asynchronous jobs in the future.

The 'worker' instance which runs Sidekiq and processes 'jobs' taken from the
Redis queue is defined in a [Terraform definition](/terraform/worker.tf).

## Debugging via console

### Connect to worker

Connect to the worker instance using the name of the environment and the
"-worker" suffix and then run a Rails console:

```sh
$ cf ssh beis-roda-{prod|staging|pentest}-worker
$ bin/rails c
```

NB: Once in the Rails console we need to 'require' the api library to access
the classes we need:

```ruby
> require "sidekiq/api"
=> true
```


### See overview of jobs

`Sidekiq::Stats.new` gives us an overview. Here we see that 408 jobs are
waiting to be re-tried:

```ruby
> Sidekiq::Stats.new
=> #<Sidekiq::Stats:0x000055ce07bdabc0
 @stats=
  {:processed=>7818,
   :failed=>7344,
   :scheduled_size=>0,
   :retry_size=>408,
   :dead_size=>0,
   :processes_size=>1,
   :default_queue_latency=>0,
   :workers_size=>0,
   :enqueued=>0}>
```

### Process jobs marked to be retried

```ruby
rs = Sidekiq::RetrySet.new
=> #<Sidekiq::RetrySet:0x000055ce07a60150 @_size=408, @name="retry">

> rs.each { |job| job.retry }
=> nil
```

## References

There is more useful info on the Sidekiq API at these two links. e.g. see the
`Sidekiq::Queue` class and the `Sidekiq::Stats.new.queues` method:

- [GDS notes on Sidekiq monitoring](https://docs.publishing.service.gov.uk/manual/sidekiq.html#sidekiq-from-the-console)
- [Sidekiq author's notes on API](https://github.com/mperham/sidekiq/wiki/API)
