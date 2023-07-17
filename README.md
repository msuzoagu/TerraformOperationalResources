# Introduction
Inspired by [Chris Kent](https://thirstydeveloper.io/), this repository implements a skeleton repository used to create operational resources for Terraform. It uses Cloudformation as a workflow tool. 

If you are interested, you can read my [post]() outlining how I use this to get projects up and running.

## Overview
Run __make help__ for quick overview of available commands  

## Assumptions

1. AWS Account Setup

	This template assumes a [__Multiple AWS Accounts Setup__](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/benefits-of-using-multiple-aws-accounts.html). 

	Multiple Accounts can be manages as separate entities but I find creating and managing accounts via [AWS Organizations](https://docs.aws.amazon.com/controltower/latest/userguide/organizations.html) easiest.  The ability to access member accounts as an Admin user via [OrganizationAccountAccessRole](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html) makes it easy to create the initial operational resources needed to get started codifying infrastructure with Terraform. 

2. Resource Accounts 

	This template assumes an adherence to environment-based deployments (development, staging, etc ) and the existence of corresponding environment-based resource accounts. 

	I define a resource account as a environment-based AWS Account. For example, a development account; which would be an aws account where all development-related resouces like apis, databases, etc are deployed. 

3. Existing Resources

	Although working on a Greenfield project is rare, this template assumes a cleaning starting plate. Time permitting, I will outline how it can be used to move existing AWS infrastructure to Terraform.


## Prerequisites

1. [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

2. [jq](https://jqlang.github.io/jq/download/)

3. [yq](https://github.com/mikefarah/yq#install). For quick instructions, read [this](https://www.sanderh.dev/parsing-YAML-files-using-yq/)
 
4. AWS user with admin access in the [trusting account](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html). This is the user who will, via Cloudformation, deploy/create the Terraform backend resources. Or if using AWS Org, an admin user with [OrganizationAccountAccessRole](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html) 

5. Existence of named profiles in `$HOME/.aws/config`. Edits can be made to accomodate your needs. 

6. a `vars.yaml` configuration file. See [sample.var.yaml](https://github.com/msuzoagu/TerraformOperationalResources/blob/main/sample.var.yaml) for sample.


## Limitations/Todo
At the moment, this template does not implement the use of [Cloudformation Macros](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-macros.html), which I believe is the only way to create multiple resources of the same type without having to repeat the same resource block.

Therefore some templates, for example those that deal with the creation of roles and bucket policies, have to be edited each time permissions have to granted or revoked. 

Time permitting, will introduce the use of macros.

## Make Commands

All commands rely on the presence of both `env=${arg}` and `project=${arg}` flags to determine what values to pull from the `vars.yaml` configuration file.


1. __make operationalResourceSet__: creates operational resources in the account specified in *.${project}.${env}.log.profile* section of configuration file (assuming that all Terraform operational resources are created in a separate AWS log account )
	+ if `env=dev` this command creates a set of operational resources, namely _dev-statebucket, dev-logbucket, and dev-locktable_
	+ for each set of operational resources created, it outputs a ***StateBucketArn and LockTableArn*** 
	+ exported names must be added to *${project}.log.StateBucketArns* and  *${project}.log.lockTableArns* sections of configuration file before running `make backendRole`


2. __make backendRole__: creates a role and a policy in account specified in *.{project}.log.profile* section of configuration file: 
	+ policy attached to role grants any user who assumes the role READ/WRITE access to every set of operational resources created
	+ therefore when a new set of operational resources is create, the policy needs to be updated to include the newly exported ***StateBucketArn and LockTableArn***


3. __make group__: creates a group, and 2 poliies, in account specified in  *.{project}.iam.profile* section of configuration file
	+ AssumeRolePolicy allows group members to assume *backendRole*
	+ ManageDataPolicy allows group members to manage their data
		* ManageDataPolicy is an optional policy (you can omit it )

4. __make user__: creates a user in account specified in *.{project}.iam.profile* section of configuration file
	+ user is added to group created by `make group`

5. __make logBucketPolicy__: adds bucket policy to Terraform log bucket created by *make operationalResourceSet*
	+ see notes under *make operationalResourceSet* above
	

6. __make stateBucketPolicy__: adds a bucket policy to Terraform state bucket created by *make operationalResourceSet* 
	+ see notes under *make operationalResourceSet* above
	+ uses output(s) exported by *make operationalResourceSet*

7. __make resourceRole__: creates a role in an environment-based AWS Resource Account specified in *.${project}.${env}.profile* section of configuration file 
	+  user created by *make user* assumes this role to create resources, via Terraform, in the resource account

8. __make resourceRolePolicy__: creates and attaches a policy to group created by *make group*
	+ attached policy grants group members permission to assume *resourceRole*	in a *resource account*
	+ Due to the fact that we are using multi-account setup, the only way to update this policy with the arn of any`resourceRole` created after the initial setup is via the console or awscli. 
		* Cross-account and cross-region export/imports are not supported in CloudFormation. If you want to have everything done automatically, you would have to develop a custom resource in stack B in the form of a lambda function. The function would have to be able to access and query the stack in A in different account, and return desired attributes to stack B.[source](https://stackoverflow.com/questions/66040228/cross-stack-reference-from-different-aws-accounts)
