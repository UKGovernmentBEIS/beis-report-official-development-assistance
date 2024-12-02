# Logging

Logging is handled by CloudWatch in the DSIT AWS, you will need
a `digital-paas-production-account`, see [hosting
documentation](/doc/hosting.md#getting-an-account) for instructions for obtaining this. 

Once you have access you can find the logs by following these steps:

- sign in to AWS with your `digital-paas-production-account` account
- assume the role for the appropriate environment, see [hosting
  documentation](/doc/hosting.md#assuming-roles)
- Locate _Elastic Container Service_ (ECS) in the services menu
- Click on the cluster
- Click on the service
- Switch to the _Logs_ tab
- Refine the view of the logs

You can then switch to CloudWatch if desired:

- Click the _View in CloudWatch_ drop down
- Select the container
- Refine the view of the logs

## Via CloudWatch

You can access the container logs directly via CloudWatch, with some additional
steps:

- sign in to AWS with your `digital-paas-production-account` account
- assume the role for the appropriate environment, see [hosting
  documentation](/doc/hosting.md#assuming-roles)
- Locate _CloudWatch_ in the services menu
- From the side bar open _Logs_ and click on _Log groups_
- Locate either the application or worker container for that matches the
  environment, e.g. `/ecs/ODA-prod` and `/ecs/ODA-prod-SideCar` for production
- Click on the container
- The logs are split into 'streams' choose a steam or click _Search all log
  steams_ and refine
