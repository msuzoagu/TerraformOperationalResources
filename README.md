# Introductions
Inspired by [Chris Kent](https://thirstydeveloper.io/), this repository implements a skeleton repository used to create operational resources for Terraform. It uses Cloudformation as a workflow tool. 

If you are interested, you can read my [post]() outlining how I use this to get projects up and running.

### Prerequisites

1. [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

2. [jq](https://jqlang.github.io/jq/download/)

3. [yq](https://github.com/mikefarah/yq#install). For quick instructions, read [this](https://www.sanderh.dev/parsing-YAML-files-using-yq/)

4. [cfn-lint](https://github.com/aws-cloudformation/cfn-lint). 


5. At least 3 AWS accounts:
	- UserManagement Account 
	- Terraform Backend Account
	- Workload Account
	
6. AWS user with admin access in the [trusting account](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html). This is the user who will, via Cloudformation, deploy/create the Terraform backend resources. Or if using AWS Org, an admin user with [OrganizationAccoutAccessRole](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html) 

# Commands

- `make backendResources env={arg}`
- `make logBucketPolicy env={arg}`
- `make backendRole env={arg}`
- `make backendGroup`
- `make backendUser`
- `make stateBucketPolicy env={arg}`
- `make workloadRole env={arg}`
- `make workloadGroupPolicy`

To update `workloadGroupPolicy` with roles created in different __workload Accounts__, run: 

- `make add-stating-accountId-to-workloadGroupPolicy`
- `make add-production-accountId-to-workloadGroupPolicy`


# Assumptions

1. Workload Accounts 

	> A workload is defined as "as a collection of resources and code that delivers business value, such as a customer-facing application or a backend process." 

	This template assumes an adherence to environment-based deployments (development, staging, etc ) and the existence of corresponding environment-based workload accounts. 

	I define a workload account as a environment-based AWS Account (for example, a development account; which would be an aws account where all development-related resouces like buckets, databases, etc are deployed). 


2. Existing Resources

	Although working on a Greenfield project is rare, this template assumes a cleaning starting plate. Time permitting, I will outline how it can be used to move existing AWS infrastructure to Terraform.

3. AWS Account Setup

	This template assumes the existence of at least 3 AWS accounts -  one for managing Users, one for housing Terraform backends, and one for managing any of development/test/production workload resources. 

	> it is possible to adapt this template for use in a single AWS account setup but that is an exercise left to the user to accomplish.

	You can create/manage these accounts as separate entities but I personally find creating and managing accounts via [AWS Organizations](https://docs.aws.amazon.com/controltower/latest/userguide/organizations.html) easiest.  

	The ability to access member accounts as an Admin user via [OrganizationAccoutAccessRole](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html) makes it easy to create the initial operational resources needed to get started codifying infrastructure with Terraform. 



# Stack Dependencies

Second to having a template I could use to setup a project quickly was the ability to easily reason through how this template works. I tried to accomplish this by: 

1. making some stacks reliant on the `env` variable

	Terraform backend resources are created based on environments. For example __0-backend.cf.yaml__, which is used to create Terraform OperationalResources, requires a `env` flag. When `env=development` is passed to `make backend-resources`, development variables are pulled from `vars.yaml` resulting in the creation of __developmentTfStateBucket, developmentTfLogBucket, and developmentTfLocktable__. 

	To create Terraform backend resources for a production workload, simply run `make backend-resources env=production`. 

	In addition, the files below run once for each `env`-dependent workload account:

 - __1-logBucketPolicy.cf.yaml__
 - __5-stateBucketPolicy.cf.yaml__
 - __6-workloadRole.cf.yaml__
 - __7-workloadPolicy.cf.yaml__

	
2. enforcing separation of concerns
	
	I find long cloudformation templates hard to read and intensely dislike them. This template makes a stack responsible for doing one thing and one thing only. 

	For example, since buckets can be created sans policies, __1-logBucketPolicy.cf.yaml__ and __5-stateBucketPolicy.cf.yaml__ craft policies for every `env`-dependent terraform log and state bucket created. 

3. forcing run order (implied by filenames)
	
	Access to Terraform log and state buckets needs to be restricted. Restriction is accomplised via bucket policies, which in turn require the creation of roles/groups/users. Therefore __2-backendRole.cf.yaml__, __3-backendGroup.cf.yaml__, and __4-backendUser.cf.yaml__ have to be run before __5-stateBucketPolicy.cf.yaml__. 

	Basically, the numbers in filenames indicate the order stacks should be created. 

	> the expection is __1-logBucketPolicy__. The creation of logBucket is run-order independent because only the admin account has access to bucket logs. If you wish to change this you may do so. 


4. storing variables in a Yaml file 
	
	All environment variables are stored in a Yaml file (see sample.vars.yaml)


# Important
#### working with `workloadRole` and `workloadPolicy` stacks
	
- a __workloadRole__ is a role created in a **workload Account**
	
- a **workload Account** is an AWS account delegated to housing all resources used in a specific enviornment. For example, a **development account** contains all resources used to create/deploy/maintain/destroy development resources. 
	
- thus a __workloadRole__ is the role assumed by all IAM principals permitted to interact with resources in a corresponding **workload Account**. For example, a user will assume a `development-backendRole` to create resources in a `development account`. 

- A __workloadRole__ is created only once in your UserManagementAccount. It is attached to a group and all members of that group are permitted to assume it. Ideally, all members of the group should have tags. This way restrictions can be implemented in your __workload Accounts__. For example, using conditions, limit what a user with a certain tag key and value can do. 


> __7-workloadPolicy.cf.yaml__ is attached to the group created in __3-backendGroup__. It grants members of this group the permission to create resources in your **workload Account**


Basically: 

1. Step 1
	- In Terraform account (or any account where logs are kept):
		+  create a role whose trust policy grants `sts:AssumeRole` to users in your UserManagement Account. 

2. Step 2
	- In UserManagement Account:
		+ create a group 
		+ create a policy that grants users permission to assume the role in Step 1 above. attach this policy to the group 
		+ create a user and add user to group 
		
3. Step 3
	- In Workload Accounts:
		+ create a role whose trust policy grants 'sts:AssumeRole' to users in your UserManagement Account. 

4. Step 4
	- In UserManagement Account: 
		+ create a policy that grants users permission to assume the role in Step 3 abobe. attach this policy to the group created in Step 3 above

With the above steps, members of the group created in __Step 2__ can: 
- assume the role in Terraform Account. This role in combination with the bucket policy of the TerraformStateBucket grants users the ability to read from and write to TerraformState.
- assume the role(S) in Workload Accounts. This template does not include any policy that grants access to create/edit/delete/update resources in Workload Accounts. I cannot tell you what access to grant to your users; decide on what permissions you want to grant your users, create a policy and attach it to the you have to the group in Step 2 above. 


## Todo
- rename all `GroupName` parameters to `BackendGroup`; makes it clear that user belong to the same group; same group given permission to: 
	+ read from and write to terraform state in Terraform Account 
	+ CRUD resources via terraform in Development/Stating/Production accounts
