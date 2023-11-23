# Console access

We need console access to bootstrap the service with users and organisations. We may need a way to access live environments for debugging or incident management purposes in future.

If we do need to open a rails console on production we should pair through the commands we execute to mitigate the risk of data loss.

## Prerequisites

You must have an account that has been invited to DSIT's AWS account, managed by DSIT.

## Access

Log in via AWS.

Switch to the role for the environment where you need console access.

Go to the list of EC2 instances. (EC2 -> Instances)

Select one of the running instances, doesn't matter which.

Connect to the instance with Session Manager.

Get a list of running containers:
```sh
$ sudo docker ps
```

Start a Rails console in a running container using the ID of the container:

```sh
$ sudo docker exec -it CONTAINER_ID bundle exec rails c
```
