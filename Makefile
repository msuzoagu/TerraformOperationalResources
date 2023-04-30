# -----------------------------------------------------------------------------
# Pull in environment variables
# -----------------------------------------------------------------------------
include .env

# -----------------------------------------------------------------------------
# trusting account
# -----------------------------------------------------------------------------
ResourceOwner := $(shell \
	aws --profile ${ResourceOwnerProfile} sts get-caller-identity | jq -r .Account \
)

ResourceAccessor := $(shell \
	aws --profile ${ResourceAccessorProfile} sts get-caller-identity | jq -r .Account \
)


# -----------------------------------------------------------------------------
# dry run for creating groups and users
# -----------------------------------------------------------------------------
.PHONY: dry-run-groups-and-users
dry-run-groups-and-users:
	aws cloudformation deploy \
		--dry-run\
		--output json\
		--region ${AwsRegion}\
		--capabilities CAPABILITY_NAMED_IAM\
		--profile ${ResourceAccessorProfile}\
		--template-file groups-and-users.cf.yaml\
		--stack-name create-groups-and-users-for-terraform-operational-resources\
		--parameter-overrides\
			RoleName=${RoleName}\
			Group1Name=${Group1Name}\
			Group1UserName=${Group1UserName}\
			Group1UserTagValue=${Group1UserTagValue}\
			ResourceAccessor=${ResourceAccessor}\
			ResourceOwner=${ResourceOwner}\
			Group2Name=${Group2Name}\
			Group2UserName=${Group2UserName}\
			Group2UserTagValue=${Group2UserTagValue}\
			CommonGroupUserTagKey=${CommonGroupUserTagKey}\
			NameOfTrustingAccount=${NameOfTrustingAccount}\
			CommonGroupPermissionPolicyName=${CommonGroupPermissionPolicyName}


# -----------------------------------------------------------------------------
# deploy groups and users
# -----------------------------------------------------------------------------
.PHONY: groups-and-users
groups-and-users:
	aws cloudformation deploy \
		--output json\
		--region ${AwsRegion}\
		--capabilities CAPABILITY_NAMED_IAM\
		--profile ${ResourceAccessorProfile}\
		--template-file groups-and-users.cf.yaml\
		--stack-name create-groups-and-users-for-terraform-operational-resources\
		--parameter-overrides\
			RoleName=${RoleName}\
			Group1Name=${Group1Name}\
			Group1UserName=${Group1UserName}\
			Group1UserTagValue=${Group1UserTagValue}\
			ResourceAccessor=${ResourceAccessor}\
			ResourceOwner=${ResourceOwner}\
			Group2Name=${Group2Name}\
			Group2UserName=${Group2UserName}\
			Group2UserTagValue=${Group2UserTagValue}\
			CommonGroupUserTagKey=${CommonGroupUserTagKey}\
			NameOfTrustingAccount=${NameOfTrustingAccount}\
			CommonGroupPermissionPolicyName=${CommonGroupPermissionPolicyName}


# -----------------------------------------------------------------------------
# display errors in terminal
# -----------------------------------------------------------------------------
.PHONY: display-groups-and-users-errors
display-groups-and-users-errors:
	aws cloudformation describe-stacks\
		--stack-name create-groups-and-users-for-terraform-operational-resources\
		--profile ${ResourceAccessorProfile}\
		--region ${AwsRegion}

# -----------------------------------------------------------------------------
# pipe errors into text file
# -----------------------------------------------------------------------------
.PHONY: pipe-groups-and-users-errors
pipe-groups-and-users-errors:
	aws cloudformation describe-stacks\
		--stack-name create-groups-and-users-for-terraform-operational-resources\
		--profile ${ResourceAccessorProfile}\
		--region ${AwsRegion}\
		>> error-groups-and-users.txt 


# -----------------------------------------------------------------------------
# delete stack
# -----------------------------------------------------------------------------
.PHONY: delete-groups-and-users-stack
delete-groups-and-users-stack:
	aws cloudformation delete-stack \
	--stack-name create-groups-and-users-for-terraform-operational-resources \
	--profile ${ResourceAccessorProfile} \
	--region ${AwsRegion}


# -----------------------------------------------------------------------------
# dry run for creating backend resources
# -----------------------------------------------------------------------------
.PHONY: dry-run-backend
dry-run-backend:
	aws cloudformation deploy \
		--dry-run\
		--output json\
		--region ${AwsRegion}\
		--template-file backend.cf.yaml\
		--profile ${ResourceOwnerProfile}\
		--capabilities CAPABILITY_NAMED_IAM\
		--stack-name create-backend-for-terraform-operational-resources\
		--parameter-overrides\
			Region=${AwsRegion}\
			RoleName=${RoleName}\
			LogBucketName=${Env}-${LB}\
			LockTableName=${Env}-${LT}\
			StateBucketName=${Env}-${SB}\
			ResourceOwner=${ResourceOwner}\
			ResourceAccessor=${ResourceAccessor}\
			Group1UserTagValue=${Group1UserTagValue}\
			Group2UserTagValue=${Group2UserTagValue} \
			RolePermissionPolicyName=${RolePermissionPolicyName}


# -----------------------------------------------------------------------------
# deploy backend resources
# -----------------------------------------------------------------------------
.PHONY: backend
backend:
	aws cloudformation deploy \
		--output json\
		--region ${AwsRegion}\
		--template-file backend.cf.yaml\
		--profile ${ResourceOwnerProfile}\
		--capabilities CAPABILITY_NAMED_IAM\
		--stack-name create-backend-for-terraform-operational-resources\
		--parameter-overrides\
			Region=${AwsRegion}\
			RoleName=${RoleName}\
			LogBucketName=${Env}-${LB}\
			LockTableName=${Env}-${LT}\
			StateBucketName=${Env}-${SB}\
			ResourceOwner=${ResourceOwner}\
			ResourceAccessor=${ResourceAccessor}\
			Group1UserTagValue=${Group1UserTagValue}\
			Group2UserTagValue=${Group2UserTagValue} \
			RolePermissionPolicyName=${RolePermissionPolicyName}


# -----------------------------------------------------------------------------
# display errors in terminal
# -----------------------------------------------------------------------------
.PHONY: display-backend-errors
display-backend-errors:
	aws cloudformation describe-stacks\
		--stack-name create-backend-for-terraform-operational-resources\
		--profile ${ResourceOwnerProfile}\
		--region ${AwsRegion}


# -----------------------------------------------------------------------------
# pipe errors into text file
# -----------------------------------------------------------------------------
.PHONY: pipe-backend-errors
pipe-backend-errors:
	aws cloudformation describe-stack-events\
		--stack-name create-backend-for-terraform-operational-resources\
		--profile ${ResourceOwnerProfile}\
		--region ${AwsRegion}\
		>> error-backend.txt 


# -----------------------------------------------------------------------------
# delete stack
# -----------------------------------------------------------------------------
.PHONY: delete-backend-stack
delete-backend-stack:
	aws cloudformation delete-stack \
		--stack-name create-backend-for-terraform-operational-resources \
		--profile ${ResourceOwnerProfile}\
		--region ${AwsRegion}


# -----------------------------------------------------------------------------
# test your ability to assume roles in trusting and trusted account 
# -----------------------------------------------------------------------------
.PHONY: test-owner-profile
test:
	aws ec2 describe-availability-zones --profile ${ResourceOwnerProfile}

.PHONY: test-accessor-profile
test:
	aws ec2 describe-availability-zones --profile ${ResourceAccessorProfile}
