include .env

dummy-target: 
	@echo ${HOSTNAME}

##############################################################################
# granted access to resources 																							 #
##############################################################################
TrustedAccount := $(shell \
	aws --profile ${TrustedAccount} sts get-caller-identity | jq -r .Account \
)

##############################################################################
# resources created here  																							 		 #
##############################################################################
TrustingAccount := $(shell \
	aws --profile ${TrustingAccount} sts get-caller-identity | jq -r .Account \
)


########################################
# debug parameter values 							 #
########################################
.PHONY: dry-run
dry-run:
	aws cloudformation deploy \
		--dry-run \
		--output json \
		--region ${AwsRegion} \
		--profile ${AwsProfile} \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-file backend.cf.yaml \
		--stack-name create-terraform-backend-resources-in-${NameOfTrustingAccount}-account\
		--parameter-overrides \
			TagVal=${TagVal} \
			TagKey=${TagKey} \
			Region=${AwsRegion} \
			RoleName=${RoleName} \
			TrustedAccount=${TrustedAccount} \
			TrustingAccount=${TrustingAccount} \
			LogBucket=${Env}-${LB}-${Project} \
			LockTable=${Env}-${LT}-${Project} \
			StateBucket=${Env}-${SB}-${Project} 


########################################
# deploy via debug option							 #
########################################
.PHONY: backend
backend:
	aws cloudformation deploy \
		--debug \
		--output json \
		--region ${AwsRegion} \
		--profile ${AwsProfile} \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-file backend.cf.yaml \
		--stack-name create-terraform-backend-resources-in-${NameOfTrustingAccount}-account\
		--parameter-overrides \
			TagVal=${TagVal} \
			TagKey=${TagKey} \
			Region=${AwsRegion} \
			RoleName=${RoleName} \
			TrustedAccount=${TrustedAccount} \
			TrustingAccount=${TrustingAccount} \
			LogBucket=${Env}-${LB}-${Project} \
			LockTable=${Env}-${LT}-${Project} \
			StateBucket=${Env}-${SB}-${Project} \
		--disable-rollback 		