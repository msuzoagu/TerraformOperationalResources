include .env

dummy-target: 
	@echo ${HOSTNAME}

##############################################################################
# group and policies created here                                            #
##############################################################################
TrustedAccount := $(shell \
	aws --profile ${TrustedAccount} sts get-caller-identity | jq -r .Account \
)

##############################################################################
# grants access to users in group                                            #
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
		--template-file group.cf.yaml \
		--stack-name create-${GroupName}-in-${NameOfTrustedAccount}-account\
		--parameter-overrides\
			Region=${AwsRegion}\
			RoleName=${RoleName}\
			GroupName=${GroupName}\
			TrustedAccount=${TrustedAccount}\
			TrustingAccount=${TrustingAccount}\
			NameOfTrustingAccount=${NameOfTrustingAccount}\
			PermissionPolicyName=PermissionPolicy4${GroupName}

########################################
# deploy via debug option         		 #
########################################
.PHONY: group
group:
	aws cloudformation deploy \
		--debug \
		--output json \
		--region ${AwsRegion} \
		--profile ${AwsProfile} \
		--capabilities CAPABILITY_NAMED_IAM \
		--template-file group.cf.yaml \
		--stack-name create-${GroupName}-in-${NameOfTrustedAccount}-account\
		--parameter-overrides\
			Region=${AwsRegion}\
			RoleName=${RoleName}\
			GroupName=${GroupName}\
			TrustedAccount=${TrustedAccount}\
			TrustingAccount=${TrustingAccount}\
			NameOfTrustingAccount=${NameOfTrustingAccount}\
			PermissionPolicyName=PermissionPolicy4${GroupName}\
		--disable-rollback 		