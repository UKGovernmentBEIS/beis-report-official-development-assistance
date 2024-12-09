# Console access

Console access to the running containers is via a 'Jumphost' in AWS, you will need
a `digital-paas-production-account`, see [hosting
documentation](/doc/hosting.md#getting-an-account) for instructions for obtaining this. 

Once you have access, you can access a console by following these steps:

- sign in to AWS with your `digital-paas-production-account` account
- select the correct AWS region, 'London (eu-west-2)'
- assume the role for the appropriate environment, see [hosting
  documentation](/doc/hosting.md#assuming-roles)

You will need to make a note of the cluster name, ARN of the task and the
container name:

First the cluster name:

- Locate _Elastic Container Service_ (ECS) in the services menu
- You will see only a single cluster with a name that matches the environment,
  e.g. `ODA-dev` for development
- Note down the cluster name

Next, the task ARN:

- Click on the cluster
- Switch to the 'Tasks' tab
- Click on the copy icon for the first Task and make a note of it, it will be a
  long ARN string

And finally, the container name:

- Click on the task you copied the ARN of in the previous step
- Look at the list of containers, you will see the application and a 'SideCar',
  make a note of the application container name, this is usually `ODA-app`

You now have everything you need to use the console:

- Locate _EC2_ in the services menu
- In the sidebar, click on 'Instances'
- You will see a single 'Jumphost' instance for the environment, e.g.
  `Jumphost-dev` for development
- Check that row and click the _Connect_ button
- Switch to the _Session Manager_ tab
- Click on the _Connect_ button
- You will see a console on the Jumphost

You now have to connect to the container itself from the Jumphost:

Use the following command:

```
aws ecs execute-command --region [region] --cluster [cluster name] --task [task
arn] --container [container name] --command [command] --interactive
```

Where:

* `[region]`: `eu-west-2`
* `[cluster name]`: The cluster name you have noted down
* `[task arn]`: The task ARN you have noted down
* `[container name]`: The container name you have noted down
* `[command]`: `/bin/bash`

AWS documentation for the [aws ecs
execute-command](https://docs.aws.amazon.com/cli/latest/reference/ecs/execute-command.html)

## Troubleshooting

- If you cannot see anything in ECS or EC2, you likely need to [assume the correct
  role](/doc/hosting.md#assuming-roles)
- All variables are case sensitive
