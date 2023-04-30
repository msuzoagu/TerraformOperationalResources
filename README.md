# Terraform Backend Resources
Inspired by [Chris Kent](https://thirstydeveloper.io/), this repository implements a skeleton repository used to create operational resources for Terraform. It uses Cloudformation as a workflow tool. 

If you are interested, you can read my [post]() outlining how I use this to get projects up and running.


### Assumptions
1. AWS Account Setup

	This template assumes the existence of at least 2 AWS accounts -  one for managing Users and the other for housing Terraform backends. You can create/manage these accounts as separate entities but I personally find managing and creating accounts via [AWS Organizations](https://docs.aws.amazon.com/controltower/latest/userguide/organizations.html) easier.  

	The ability to access member accounts as an Admin user via [OrganizationAccoutAccessRole](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html) makes it easy to create the initial operational resources needed to get started codifying infrastructure with Terraform. 

	Note that it is possible to adapt this template for use in a single AWS account setup but that is an exercise left to the user to accomplish.

2. Existing Resources
	
   Although working on a Greenfield project is rare, this template assumes a cleaning starting plate. Time permitting, I will outline how it can be used to move existing AWS infrastructure to Terraform.


### Prerequisites 
1. [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), [cfn-lint](https://github.com/aws-cloudformation/cfn-lint), and [jq](https://formulae.brew.sh/formula/jq) installed
2. Two AWS accounts: 
	- user management account 
	- terraform backend account
	
3. AWS user with admin access in the [trusting account](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html). This is the user who will, via Cloudformation, deploy/create the Terraform backend resources . Or if using AWS Org, an admin user with [OrganizationAccoutAccessRole](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html) 

4. Values for `.env` created using `.env.template`


### Good To Know
1. There are 2 CloudFormation templates: 
	a. `backend.cf.yaml` creates resources in the trusting account 
	b. `groups-and-users.cf.yaml` creates resources in the trusted account. 
	
2. `make dry-run-backend` prints out parameters in terminal. This is a chance to debug before deploying the stack. 

3. `make backend` and `make groups-and-users` will deploy resources in their respective accounts 

4. `make display-` displays errors (in the event of failure) in the terminal 

5. `make pipe-` pipes errors into txt file

6. `make delete-` deletes the stack in the event of failure


## Usage
1. Fork repository and set [upstream remote](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/configuring-a-remote-repository-for-a-fork)
2. `cd` into git directory
3. Add appropriate values for `.env`; see `.env.template`
4. Run `make dry-run-` command, debug `.env` variables if necessary. 
5. Run `make-backed` or `make groups-and-users` when ready