# New Document
# Terraform Backend Resources
This repository implements a skeleton repository for teams to use when first getting started with terraform. It uses Cloudformation as a workflow tool. 

## Assumptions

1. AWS Account Setup
	
    This template assumes the existence of 2 AWS accounts. You can
    create/manage these accounts as separate entities but I personally
    find managing and creating accounts via [AWS Organizations](https://docs.aws.amazon.com/controltower/latest/userguide/organizations.html) easier.  
    
    If using AWS Organizations, your ability to switch access member accounts as Admin user (not root user) via the [OrganizationAccoutAccessRole](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html) makes it easy to create the initial operational resources you need to get started codifying your infrastructure with Terraform or your Iac tool of choice.

    Note that it is possible to adapt this template for use in a single AWS account setup but that is an exercise left to the user to accomplish.
	
	

2. Existing Resources 
	
	Although working on a Greenfield project is rare, this template assumes a clean starting plate. 
	Time permitting, I hope to discuss how to use this template when moving existing infrastructure to 
	Terraform.



## Prerequisites 
1. 2 separate AWS accounts: 
	 - one dedicated to user management 
	 - one dedicated to storing/holding Terraform backend resources 

2. An AWS User with: 
	- Administrative access in the [trusting account](https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html) - this is the user who will, via Cloudformaion, deploy/create the Terraform backend resources

4). Values for `.env` in **backend** and **policies** directories
		

## How Things Work
1. First create the backend resources: 

	- **_backend/backend.cf.yaml_** creates the following backend resources: 
		- a role: permits users in the trusted account with the correct **tag key** and **tag value** to access to resources in the trusting account

		- a policy: attached to the role above. It permits users who can the assume said role access to the resources listed in the policy

			- a terraform state bucket 
			- a terraform state log bucket 
			- a terraform dynamodb lock table

2. We want to make it easy for multiple users to assume the role created in the trusting account, thus: 
	- **_policies.cf.yaml_** creates a group and attaches a policy that permits members of the group to assume the role created in the trusting account.


## Getting Started

1. ensure you have [awscli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed

2. Clone this repository and cd into its root directory

3. The keys in `dot_env_file` are what you need to create an `.env`, which is read by the Makefiles. 


### Usage
1. cd into _backend.cf.yaml_ directory and run `make backend-dry-run` for test run. 

	i. If satisfied with values printed out, run `make backend` to create/deploy resources 

2. cd into _policies.cf.yaml_ directory and run `make policies-dry-run` for test run. 

	i. If satisfied with values printed out, run `make policies` to create/deploy resources 
 
