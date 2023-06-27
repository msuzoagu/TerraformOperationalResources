# Introductions
Inspired by [Chris Kent](https://thirstydeveloper.io/), this repository implements a skeleton repository used to create operational resources for Terraform. It uses Cloudformation as a workflow tool. 

If you are interested, you can read my [post]() outlining how I use this to get projects up and running.


## Assumptions

1. AWS Account Setup

	This template can be adapted to suit either a [__Single AWS Account Setup__](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/single-aws-account.html) or a [__Multiple AWS Accounts Setup__](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/benefits-of-using-multiple-aws-accounts.html). 

	Multiple Accounts can be manages as separate entities but I personally find creating and managing accounts via [AWS Organizations](https://docs.aws.amazon.com/controltower/latest/userguide/organizations.html) easiest.  The ability to access member accounts as an Admin user via [OrganizationAccoutAccessRole](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html) makes it easy to create the initial operational resources needed to get started codifying infrastructure with Terraform. 

2. Workload Accounts 

	> A workload is defined as "as a collection of resources and code that delivers business value, such as a customer-facing application or a backend process." 

	This template assumes an adherence to environment-based deployments (development, staging, etc ) and the existence of corresponding environment-based workload accounts. 

	I define a workload account as a environment-based AWS Account (for example, a development account; which would be an aws account where all development-related resouces like buckets, databases, etc are deployed). 

3. Existing Resources

	Although working on a Greenfield project is rare, this template assumes a cleaning starting plate. Time permitting, I will outline how it can be used to move existing AWS infrastructure to Terraform.


## Prerequisites

1. [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

2. [jq](https://jqlang.github.io/jq/download/)

3. [yq](https://github.com/mikefarah/yq#install). For quick instructions, read [this](https://www.sanderh.dev/parsing-YAML-files-using-yq/)

4. [cfn-lint](https://github.com/aws-cloudformation/cfn-lint). 

5. AWS user with admin access in the [trusting account](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html). This is the user who will, via Cloudformation, deploy/create the Terraform backend resources. Or if using AWS Org, an admin user with [OrganizationAccoutAccessRole](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html) 

6. Existence of named profiles in `$HOME/.aws/config`. Edits can be made to accomodate your needs. 

7. `vars.yaml` configuration file. Use [`sample.env.yaml`](https://github.com/msuzoagu/TerraformOperationalResources/blob/8b8668a46c7baf29ed8b19b5cfbb14b76cea06ab/sample.env.yaml) as a template.


## AWS Account Setup: Single vs Multiple

Almost all commands rely on the presence/absence of `env=${arg}` flag to determine what AWS account setup to follow:

	* without `env=${arg}` flag, single account setup is presumed 

	* with `env=${arg}` flag, multiple accounts setup is presumed

The exceptions, __make tf-state-Role__ and __make group__ rely on the value of `setup=${arg}` flag.

>Important Note: the value of env=${arg} arg is used to: 
> * determine the workload account (development, staging, etc) 
> * construct the exported values of bucket names and arns, which are used in some of the stacks and thus introduces cross-stack dependencies


## Limitations/Todo
At the moment, this template does not implement the use of [Cloudformation Macros](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-macros.html), which I believe is the only way to handle dynamic creation of resources. 

Therefore some templates, for example [__1Tf-state-role.cf.yaml__](https://github.com/msuzoagu/TerraformOperationalResources/blob/8b8668a46c7baf29ed8b19b5cfbb14b76cea06ab/1Tf-state-role.cf.yaml), need to be edited before use. 

Time permitting, will introduce the use of macros.


## Make Commands
List of available commands is displayed via `make list`

1. *make tf-operational-resources*: adds operational resources 
	
	+ relies on the presence/absence of `env=${arg}` flag. 
	
	+ when `env` flag is not set, a single aws account setup is presumed and only a single set of operation resources are created in account specified by __.profile__ section of configuration file
	
	+ when `env` flag is set, a multiple aws accounts setup is presumed and a unique set of terraform operational resources is created. For example, if `env=dev` then this command creates a statebucket, a logbucket, and a locktable 
		* these operatonal resources are created in the account specified in the __.${env}.log.profile__ section of the configuration file. 
		* the assumption is that all terraform operational resources (state buckets, log buckets, kms keys, and lock tables) are created in a separate AWS log account 


2. *make tf-state-role*: creates a role users must assume to READ/WRITE terraform state
	
	+ requires a `setup` flag which must be one of "single" or "multiple"
		* if a single account setup, role is created in account specified by __.profile__ section of configuration file
		
		* if multiple account setup, role is created in account specified by the __.log.profile__ section of configuration file
	
	+ requires StateBucketArns and LockTableArns exported in `make tf-operational-resources`
			- when multiple accoount setup, edit template to include all StateBucketArns and LockTableArns; example provided in template

3. *make group*: creates a group users must belong to in order to assume the role created by `make tf-state-role`

4. *make user*: creates and adds a user to the group created by `make group`

5. *make tf-log-bucket-policy*: adds bucket policy to terraform log buckets


6. *make tf-state-bucket-policy*: adds a bucket policy to each state bucket created by `make tf-operational-resources`
	+ uses output(s) exported by `make tf-operational-resources` 


7. *make tf-workload-role*: adds a role to a workload account
	

8. *make tf-workload-policy*: adds policy to group created by `make group`
	