# Background jobs

We use Sidekiq (backed by Redis) to handle sending emails. See
[ADR9](/doc/architecture/decisions/0009-use-sidekiq-and-redis-to-send-emails.md).
This might be expanded to handle other asynchronous jobs in the future.

The container which runs Sidekiq and processes 'jobs' taken from the
Redis queue is defined in AWS task definitions as a "sideCar" container.

## Debugging via console

### Connect to the instance

Connect to the AWS EC2 instance with Session Manager.

Get a list of running containers:
```sh
$ sudo docker ps
```

Start a Rails console in a running container using the ID of the container:

```sh
$ sudo docker exec -it CONTAINER_ID bundle exec rails c
```

NB: Once in the Rails console we may need to 'require' the api library to access
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
