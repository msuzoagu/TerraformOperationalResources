include .env

dummy-target: 
	@echo ${HOSTNAME}

##############################################################################
# granted access to resources 																							 # 																										 #
##############################################################################
TrustedAccount := $(shell \
	aws --profile ${TrustedAccount} sts get-caller-identity | jq -r .Account \
)

##############################################################################
# resources created here																										 #
##############################################################################
TrustingAccount := $(shell \
	aws --profile ${TrustingAccount} sts get-caller-identity | jq -r .Account \
)


########################################
# dry-run to see parameter values 		 #
########################################
.PHONY: dry-run
dry-run:
	aws cloudformation deploy \
		--dry-run \
		--output json \
		--region ${AwsRegion} \
		--profile ${AwsProfile} \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-file role.cf.yaml \
		--stack-name create-${RoleName}-in-${NameOfTrustingAccount}-account\
		--parameter-overrides \
			TagKey=${TagKey} \
			TagVal=${TagVal} \
			Region=${AwsRegion} \
			RoleName=${RoleName} \
			TrustedAccount=${TrustedAccount} \
			TrustingAccount=${TrustingAccount}\
			LockTable=${Env}-${LT}-${Project} \
			LogBucket=${Env}-${LB}-${Project} \
			StateBucket=${Env}-${SB}-${Project} \
			PermissionPolicyName=PermissionPolicy4${RoleName}	

########################################
# deploy via debug
########################################
.PHONY: role
debug:
	aws cloudformation deploy \
		--debug \
		--output json \
		--region ${AwsRegion} \
		--profile ${AwsProfile} \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-file role.cf.yaml \
		--stack-name create-${RoleName}-in-${NameOfTrustingAccount}-account\
		--parameter-overrides \
			TagKey=${TagKey} \
			TagVal=${TagVal} \
			Region=${AwsRegion} \
			RoleName=${RoleName} \
			TrustedAccount=${TrustedAccount} \
			TrustingAccount=${TrustingAccount} \
			LockTable=${Env}-${LT}-${Project} \
			LogBucket=${Env}-${LB}-${Project} \
			StateBucket=${Env}-${SB}-${Project} \
			PermissionPolicyName=PermissionPolicy4${RoleName} \
		--disable-rollback 					