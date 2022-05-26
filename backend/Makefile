include .env

dummy-target: 
	@echo ${HOSTNAME}

#######################################
# account where resources are created #
#######################################
TrustedAccount := $(shell \
	aws --profile ${TRUSTED_ACCOUNT} sts get-caller-identity | jq -r .Account \
)

#######################################
# account granted access to resources #
#######################################
TrustingAccount := $(shell \
	aws --profile ${TRUSTING_ACCOUNT} sts get-caller-identity | jq -r .Account \
)

######################################
# create terraform backend resources #
######################################
.PHONY: backend-dry-run
backend-dry-run:
	aws cloudformation deploy \
		--dry-run \
		--region ${AWS_REGION} \
		--profile ${AWS_PROFILE} \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-file backend.cf.yaml \
		--stack-name create-${STACK_NAME}-for-${PROJECT} \
		--parameter-overrides \
			Region=${AWS_REGION} \
			TrustedAccount=${TrustedAccount} \
			TrustingAccount=${TrustingAccount} \
			TerraformLogBucket=${PROJECT}-${LB} \
			TerraformStateBucket=${PROJECT}-${SB} \
			TerraformLockTable=${PROJECT}-${LT} \
			BackendRoleName=${BackendRoleName}

##################################################################
# if there is a failure, you can run: 													 #
# aws cloudformation describe-stack-event args >> errors.txt     #
# make changes to correct failure/error 												 #
# then run deploy command again basically, 											 #
# the addition of --disable-rollback removes need for changesets #
##################################################################
.PHONY: backend
backend:
	aws cloudformation deploy\
		--region ${AWS_REGION} \
		--profile ${AWS_PROFILE} \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-file backend.cf.yaml \
		--stack-name create-${STACK_NAME}-for-${PROJECT} \
		--parameter-overrides \
			Region=${AWS_REGION} \
			TrustedAccount=${TrustedAccount} \
			TrustingAccount=${TrustingAccount} \
			TerraformLogBucket=${PROJECT}-${LB} \
			TerraformStateBucket=${PROJECT}-${SB} \
			TerraformLockTable=${PROJECT}-${LT} \
			BackendRoleName=${BackendRoleName} \
		--disable-rollback 	
