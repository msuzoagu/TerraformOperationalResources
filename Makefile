##-----------------------------------------------------------------------
## Retrieve Details Used in Single Account Setup
##-----------------------------------------------------------------------
singleAccountProfile := $(shell yq e '.profile' vars.yaml)
singleAccountId := $(shell aws --profile ${singleAccountProfile}\
	sts get-caller-identity | jq -r .Account\
)

##-----------------------------------------------------------------------
## Retrieve Details Used in Multiple Account Setup
##-----------------------------------------------------------------------
logProfile := $(shell yq e '.log.profile' vars.yaml)
logAccountId := $(shell aws --profile ${logProfile} \
	sts get-caller-identity | jq -r .Account \
)

iAmProfile := $(shell yq e '.iam.profile' vars.yaml)
iAmAccountId := $(shell aws --profile ${iAmProfile} \
	sts get-caller-identity | jq -r .Account \
)

##-----------------------------------------------------------------------
## Make Commands
##-----------------------------------------------------------------------

.PHONY: tf-operational-resources 
ifndef env 
tf-operational-resources:	
	@echo "single account setup"
	aws cloudformation deploy\
		--output json\
		--profile ${singleAccountProfile}\
		--template-file 0Tf-operational-resources.cf.yaml\
		--stack-name create-tf-operational-resources\
		--region $(shell yq e '.region' vars.yaml)\
		--parameter-overrides\
		Env=${env}\
		Region=$(shell yq e '.region' vars.yaml)\
		OperationalResourcesAccountId=${singleAccountId}\
		LogBucketName=$(shell yq e '.logBucket' vars.yaml)\
		LockTableName=$(shell yq e '.lockTable' vars.yaml)\
		StateBucketName=$(shell yq e '.stateBucket' vars.yaml)
else
tf-operational-resources:
	@echo "$(info current env is $(value env))"
	aws cloudformation deploy\
		--output json\
		--profile ${logProfile}\
		--template-file 0Tf-operational-resources.cf.yaml\
		--stack-name create-${env}-tf-state-resources\
		--region $(shell yq e '.${env}.region' vars.yaml)\
		--parameter-overrides\
		Env=${env}\
		Region=$(shell yq e '.${env}.region' vars.yaml)\
		OperationalResourcesAccountId=$(logAccountId)\
		LogBucketName=$(shell yq e '.${env}.logBucket' vars.yaml)\
		LockTableName=$(shell yq e '.${env}.lockTable' vars.yaml)\
		StateBucketName=$(shell yq e '.${env}.stateBucket' vars.yaml)
endif


.PHONY: tf-state-role
ifeq ($(setup), single)
tf-state-role:
	@echo "single account setup"
	aws cloudformation deploy\
		--output json\
		--profile ${singleAccountProfile}\
		--template-file 1Tf-state-role.cf.yaml\
		--stack-name create-tf-state-role-${setup}\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		Setup=${setup}\
		ResourceAccessorAccountId=${singleAccountId}\
		OperationalResourcesAccountId=${singleAccountId}\
		ValueOfUserTag=$(shell yq e '.user.tagValue' vars.yaml)\
		TfStateRoleName=$(shell yq e '.tfStateRole.${setup}.name' vars.yaml)\
		MaxSession=$(shell yq e '.tfStateRole.${setup}.session' vars.yaml)\
		PolicyName=$(shell yq e '.tfStateRole.${setup}.policyname' vars.yaml)\
		ListOfLockTableArns=$(shell yq e '.lockTableArn' vars.yaml)\
		ListOfStateBucketArns=$(shell yq e '.stateBucketArn' vars.yaml)
else 
ifeq ($(setup), multiple)
tf-state-role:
	aws cloudformation deploy\
		--output json\
		--profile ${logProfile}\
		--template-file 1Tf-state-role.cf.yaml\
		--stack-name create-tf-state-role-${setup}\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		Setup=${setup}\
		ResourceAccessorAccountId=${iAmAccountId}\
		OperationalResourcesAccountId=${logAccountId}\
		ValueOfUserTag=$(shell yq e '.user.tagValue' vars.yaml)\
		TfStateRoleName=$(shell yq e '.tfStateRole.${setup}.name' vars.yaml)\
		MaxSession=$(shell yq e '.tfStateRole.${setup}.session' vars.yaml)\
		PolicyName=$(shell yq e '.tfStateRole.${setup}.policyname' vars.yaml)\
		ListOfLockTableArns=$(shell yq e '.log.logTableArns' vars.yaml)\
		ListOfStateBucketArns=$(shell yq e '.log.stateBucketArns' vars.yaml) 
endif
endif


.PHONY: group
ifeq ($(setup), single)
group:
	@echo $(info account setup is $(value setup) )
	aws cloudformation deploy \
		--output json\
		--profile ${singleAccountProfile}\
		--template-file 2Group.cf.yaml\
		--stack-name create-group-4-SingleAccountSetup\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		GroupName=$(shell yq e '.group.${setup}.name' vars.yaml)\
		GroupPolicyName=$(shell yq e '.group.${setup}.policyname' vars.yaml)\
		GroupPolicyDesc=$(shell yq e '.group.${setup}.policydesc' vars.yaml)\
		TfStateRoleName=$(shell yq e '.tfStateRole.${setup}.name' vars.yaml)\
		PowerUserPolicyArn=$(shell yq e '.group.${setup}.powerarn' vars.yaml)\
		ResourceAccessorAccountId=${singleAccountId}\
		OperationalResourcesAccountId=${singleAccountId}
else
ifeq ($(setup), multiple)
group:
	@echo $(info account setup is $(value setup) )
	aws cloudformation deploy \
		--output json\
		--profile ${iAmProfile}\
		--template-file 2Group.cf.yaml\
		--stack-name create-group-4-MultiAccountSetup\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		GroupName=$(shell yq e '.group.${setup}.name' vars.yaml)\
		GroupPolicyName=$(shell yq e '.group.${setup}.policyname' vars.yaml)\
		GroupPolicyDesc=$(shell yq e '.group.${setup}.policydesc' vars.yaml)\
		TfStateRoleName=$(shell yq e '.tfStateRole.${setup}.name' vars.yaml)\
		PowerUserPolicyArn=$(shell yq e '.group.${setup}.powerarn' vars.yaml)\
		ResourceAccessorAccountId=${iAmAccountId}\
		OperationalResourcesAccountId=${logAccountId}
endif
endif


.PHONY: user
ifeq ($(setup), single)
user:
	@echo $(info account setup is $(value setup) )	
	aws cloudformation deploy\
		--output json\
		--stack-name create-user-4-SingleAccountSetup\
		--profile ${singleAccountProfile}\
		--template-file 3User.cf.yaml\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		Setup=${setup}\
		ResourceAccessorAccountId=${singleAccountId}\
		Username=$(shell yq e '.user.name' vars.yaml)\
		UserTagKey=$(shell yq e '.user.tagkey' vars.yaml)\
		ValueOfUserTag=$(shell yq e '.user.tagValue' vars.yaml)\
		UserGroup=$(shell yq e '.group.${setup}.name' vars.yaml)
else
ifeq ($(setup), multiple)
user:
	@echo $(info account setup is $(value setup) )
	aws cloudformation deploy\
		--output json\
		--profile ${iAmProfile}\
		--stack-name create-user-4-MultiAccountSetup\
		--template-file 3User.cf.yaml\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		Setup=${setup}\
		ResourceAccessorAccountId=${iAmAccountId}\
		Username=$(shell yq e '.user.name' vars.yaml)\
		UserTagKey=$(shell yq e '.user.tagkey' vars.yaml)\
		ValueOfUserTag=$(shell yq e '.user.tagValue' vars.yaml)\
		UserGroup=$(shell yq e '.group.${setup}.name' vars.yaml)
endif
endif


.PHONY: tf-log-bucket-policy
ifndef env 
tf-log-bucket-policy:
	@echo "single account setup"
	aws cloudformation deploy \
		--output json\
		--profile ${singleAccountProfile}\
		--template-file 4Tf-log-bucket-policy.cf.yaml\
		--stack-name add-tf-logBucket-policy\
		--region $(shell yq e '.region' vars.yaml)\
		--parameter-overrides\
		Env=${env}\
		OperationalResourcesAccountId=${singleAccountId}\
		LogBucketName=$(shell yq e '.logBucket' vars.yaml)
else
tf-log-bucket-policy:
	@echo "$(info current env is $(value env))"
	aws cloudformation deploy \
		--output json\
		--profile ${logProfile}\
		--template-file 4Tf-log-bucket-policy.cf.yaml\
		--stack-name add-${env}-tf-logBucket-policy\
		--region $(shell yq e '.${env}.region' vars.yaml)\
		--parameter-overrides\
		Env=${env}\
		OperationalResourcesAccountId=$(logAccountId)\
		LogBucketName=$(shell yq e '.${env}.logBucket' vars.yaml)
endif


.PHONY: tf-state-bucket-policy
ifndef env
ifeq ($(setup), single)
tf-state-bucket-policy:
	@echo "$(info account setup is $(value setup) and env is not required)"
	aws cloudformation deploy\
		--output json\
		--profile ${singleAccountProfile}\
		--template-file 5Tf-state-bucket-policy.cf.yaml\
		--stack-name add-tf-statebucket-policy\
		--region $(shell yq e '.region' vars.yaml)\
		--parameter-overrides\
		Env=${env}\
		Setup=${setup}\
		Username=$(shell yq e '.user.name' vars.yaml)\
		AdminRoleId=$(shell yq e '.adminRoleId' vars.yaml)\
		AdminRoleName=$(shell yq e '.adminRoleName' vars.yaml)\
		ValueOfUserTag=$(shell yq e '.user.tagValue' vars.yaml)\
		StateBucketName=$(shell yq e '.stateBucket' vars.yaml)\
		TfStateRoleName=$(shell yq e '.tfStateRole.${setup}.name' vars.yaml)\
		ResourceAccessorAccountId=${singleAccountId}\
		OperationalResourcesAccountId=$(singleAccountId)
endif
else
ifeq ($(setup), multiple)
ifdef env
tf-state-bucket-policy:
	@echo "$(info account setup is $(value setup) and env is required)"	
	aws cloudformation deploy\
		--output json\
		--profile ${logProfile}\
		--template-file 5Tf-state-bucket-policy.cf.yaml\
		--stack-name add-${env}-tf-statebucket-policy\
		--region $(shell yq e '.${env}.region' vars.yaml)\
		--parameter-overrides\
		Env=${env}\
		Setup=${setup}\
		Username=$(shell yq e '.user.name' vars.yaml)\
		AdminRoleId=$(shell yq e '.adminRoleId' vars.yaml)\
		AdminRoleName=$(shell yq e '.adminRoleName' vars.yaml)\
		ValueOfUserTag=$(shell yq e '.user.tagValue' vars.yaml)\
		StateBucketName=$(shell yq e '.${env}.stateBucket' vars.yaml)\
		TfStateRoleName=$(shell yq e '.tfStateRole.${setup}.name' vars.yaml)\
		ResourceAccessorAccountId=${iAmAccountId}\
		OperationalResourcesAccountId=${logAccountId}
endif
endif
endif



.PHONY: tf-workload-role
ifndef env
tf-workload-role:
	@echo "skip; no workloadRole for single accout setup"
else
wkLoadProfile := $(shell yq e '.${env}.profile' vars.yaml)
wkLoadAccountId := $(shell aws --profile ${wkLoadProfile} \
	sts get-caller-identity | jq -r .Account \
)
tf-workload-role:
	aws cloudformation deploy\
		--output json\
		--profile $(value wkLoadProfile)\
		--template-file 6Tf-workload-role.cf.yaml\
		--stack-name add-${env}-WorkloadRole\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		WorkloadAccountId=${wkLoadAccountId}\
		ResourceAccessorAccountId=${iAmAccountId}\
		ValueOfUserTag=$(shell yq e '.user.tagValue' vars.yaml)\
		TfStateRoleName=$(shell yq e '.tfStateRole.multiple.name' vars.yaml)\
		MaxSession=$(shell yq e '.${env}.session' vars.yaml)	
endif


.PHONY: tf-workload-policy ##Note
ifndef env
tf-workload-policy:	
	@echo "skip; no workload for single account setup"
else
wkLoadProfile := $(shell yq e '.${env}.profile' vars.yaml)
wkLoadAccountId := $(shell aws --profile ${wkLoadProfile} \
	sts get-caller-identity | jq -r .Account \
)
tf-workload-policy:
	aws cloudformation deploy\
		--output json\
		--profile ${iAmProfile}\
		--template-file 7Tf-workload-policy.cf.yaml\
		--stack-name add-${env}-workload-policy\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		WorkloadAccountId=${wkLoadAccountId}\
		ResourceAccessorAccountId=${iAmAccountId}\
		GroupName=$(shell yq e '.group.multiple.name' vars.yaml)\
		PolicyName=$(shell yq e '.workload.policyname' vars.yaml)\
		TfStateRoleName=$(shell yq e '.tfStateRole.multiple.name' vars.yaml)
endif


##-----------------------------------------------------------------------
## Print List of Make Commands
##-----------------------------------------------------------------------

.PHONY: list
list:
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$'
