include .env

dummy-target: 
	@echo ${HOSTNAME}


#########################
# resources reated here #
#########################
TrustedAccount := $(shell \
	aws --profile ${TrustedAccount} sts get-caller-identity | jq -r .Account \
)

###############################
# granted access to resources #
###############################
TrustingAccount := $(shell \
	aws --profile ${TrustingAccount} sts get-caller-identity | jq -r .Account \
)


########################################
# terraform policy for trusted account #
########################################
.PHONY: policies-dry-run
policies-dry-run:
	aws cloudformation deploy \
		--dry-run \
		--region ${AwsRegion} \
		--profile ${AwsProfile} \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-file policies.cf.yaml \
		--stack-name create-${StackName}-for-${Project} \
		--parameter-overrides \
			Region=${AwsRegion} \
			GroupName=${GroupName} \
			TrustedAccount=${TrustedAccount} \
			TrustingAccount=${TrustingAccount} \
			BackendRoleName=${BackendRoleName}

##################################################################
# if there is a failure, you can run: 													 #
# aws cloudformation describe-stack-event args >> errors.txt     #
# make changes to correct failure/error 												 #
# then run deploy command again basically, 											 #
# the addition of --disable-rollback removes need for changesets #
##################################################################
.PHONY: policies
policies:
	aws cloudformation deploy\
		--region ${AwsRegion} \
		--profile ${AwsProfile} \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-file policies.cf.yaml \
		--stack-name create-${StackName}-for-${Project} \
		--parameter-overrides \
			Region=${AwsRegion} \
			GroupName=${GroupName} \
			TrustedAccount=${TrustedAccount} \
			TrustingAccount=${TrustingAccount} \
			BackendRoleName=${BackendRoleName} \
		--disable-rollback 