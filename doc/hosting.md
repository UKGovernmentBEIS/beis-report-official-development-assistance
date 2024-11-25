# Hosting

## Introduction

All the environments are hosted on AWS provided by DSIT ICS.

This means we have no direct control of how the infrastructure is setup or
managed, depending on what your goal is, you may have to work with DSIT ICS.

## Getting an account

You will first need to get a `digital-paas-production-account`. Which will need
to be done via DIST. dxw support may be able to help, but work with your
delivery manager and DSIT colleges first.

Once you get an account you will have:

- username
- password
- MFA
- signin url

Once signed in you will need to assume a role for each environment, see below.

## Services

A brief overview of the AWS services used:

- Elastic Container Service (ECS)
- EC2
- Elastic Container Registry (ECR)
- CodeBuild
- CodeDeploy
- CodePipeline
- CloudWatch

For details on how deployments work, see the [deployment
documentation.](/doc/deployment-process.md)

For details of how to get a console in an environment, see the [console access
documentation.](/doc/console-access.md)

## Assuming roles

Each environment has its own role that you will need to assume in order to
interact with it.

The role variables are stored in the `RODA` vault in the dxw 1Password, you need
access to it first.

Once you have a `digital-paas-production-account` account and 1Password vault
access, sign into AWS and assume the role for the appropriate environment:

- From the user menu, top right of the window, click on the _Switch role_ button
- Locate the RODA 1Password vault and the `AWS environment roles` note
- copy and paste the values from the note to the Switch Role form
- click on the 'Switch role' button

You will see that your _role_ has changed in the top right of the window, you
can now view the environment, check deploys, connect to the console, etc.

