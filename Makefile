##-----------------------------------------------------------------------
## Retrieve Details Used in Single Account Setup
##-----------------------------------------------------------------------
singleAccountProfile := $(shell yq e '.single.profile' single.yaml)
singleAccountId := $(shell aws --profile ${singleAccountProfile}\
	sts get-caller-identity | jq -r .Account\
)

##-----------------------------------------------------------------------
## Retrieve Details Used in Multiple Account Setup
##-----------------------------------------------------------------------
logProfile := $(shell yq e '.multiple.log.profile' multiple.yaml)
logAccountId := $(shell aws --profile ${logProfile} \
	sts get-caller-identity | jq -r .Account \
)

iAmProfile := $(shell yq e '.multiple.iam.profile' multiple.yaml)
iAmAccountId := $(shell aws --profile ${iAmProfile} \
	sts get-caller-identity | jq -r .Account \
)

##-----------------------------------------------------------------------
## Make Commands
##-----------------------------------------------------------------------


.PHONY: tf-operational-resources #relies on the absence/presence of env arg
ifndef env 
tf-operational-resources:	
	aws cloudformation deploy\
		--output json\
		--profile ${singleAccountProfile}\
		--region $(shell yq e '.single.region' single.yaml)\
		--stack-name create-tf-operational-resources\
		--template-file 0-tf-operational-resources.cf.yaml\
		--parameter-overrides\
		Env=${env}\
		OperationalResourcesAccountId=${singleAccountId}\
		Region=$(shell yq e '.single.region' single.yaml)\
		LogBucketName=$(shell yq e '.single.logBucket' single.yaml)\
		LockTableName=$(shell yq e '.single.lockTable' single.yaml)\
		StateBucketName=$(shell yq e '.single.stateBucket' single.yaml)
else
tf-operational-resources:
	@echo "$(info current env is $(value env))"
	aws cloudformation deploy\
		--output json\
		--profile ${logProfile}\
		--stack-name create-${env}-tf-state-resources\
		--template-file 0-tf-operational-resources.cf.yaml\
		--region $(shell yq e '.multiple.${env}.region' multiple.yaml)\
		--parameter-overrides\
		Env=${env}\
		OperationalResourcesAccountId=$(logAccountId)\
		Region=$(shell yq e '.multiple.${env}.region' multiple.yaml)\
		LogBucketName=$(shell yq e '.multiple.${env}.logBucket' multiple.yaml)\
		LockTableName=$(shell yq e '.multiple.${env}.lockTable' multiple.yaml)\
		StateBucketName=$(shell yq e '.multiple.${env}.stateBucket' multiple.yaml)
endif

.PHONY: tf-operational-resources-role #requires setup arg (arg value must equal single or multiple)
ifeq ($(setup), single)
tf-operational-resources-role:
	@echo "$(info setup is: $(value setup))"
	aws	 cloudformation deploy\
		--output json\
		--profile ${singleAccountProfile}\
		--capabilities CAPABILITY_NAMED_IAM\
		--template-file 1-tf-operational-resources-role.cf.yaml\
		--stack-name create-tf-state-role\
		--parameter-overrides\
		Setup=${setup}\
		ResourceAccessorAccountId=${singleAccountId}\
		OperationalResourcesAccountId=${singleAccountId}\
		UserTagValue=$(shell yq e '.${setup}.user.tagValue' single.yaml)\
		LockTableArns=$(shell yq e '.${setup}.lockTableArn' single.yaml)\
		MaxSession=$(shell yq e '.${setup}.maxSessionDuration' single.yaml)\
		RoleName=$(shell yq e '.${setup}.operationalResourcesRole' single.yaml)\
		StateBucketArns=$(shell yq e '.${setup}.stateBucketArn' single.yaml)\
		PolicyName=$(shell yq e '.${setup}.operationalResourcesPolicy' single.yaml)
else
ifeq ($(setup), multiple)
tf-operational-resources-role:
	@echo "$(info setup is: $(value setup))"	
	aws	 cloudformation deploy\
		--output json\
		--profile ${logProfile}\
		--capabilities CAPABILITY_NAMED_IAM\
		--template-file 1-tf-operational-resources-role.cf.yaml\
		--stack-name create-tf-state-role\
		--parameter-overrides\
		Setup=${setup}\
		ResourceAccessorAccountId=${iAmAccountId}\
		OperationalResourcesAccountId=${logAccountId}\
		UserTagValue=$(shell yq e '.${setup}.user.tagValue' multiple.yaml)\
		LockTableArns=$(shell yq e '.${setup}.log.lockTableArns' multiple.yaml)\
		MaxSession=$(shell yq e '.${setup}.maxSessionDuration' multiple.yaml)\
		RoleName=$(shell yq e '.${setup}.operationalResourcesRole' multiple.yaml)\
		PolicyName=$(shell yq e '.${setup}.operationalResourcesPolicy' multiple.yaml)\
		StateBucketArns=$(shell yq e '.${setup}.log.stateBucketArns' multiple.yaml)
endif
endif

.PHONY: group #requires setup arg (arg value must equal single or multiple)
ifeq ($(setup), single)
group:
	@echo $(info setup is: $(value setup))
	aws cloudformation deploy \
		--output json\
		--stack-name create-group\
		--template-file 2-group.cf.yaml\
		--profile ${singleAccountProfile}\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		ResourceAccessorAccountId=${singleAccountId}\
		OperationalResourcesAccountId=${singleAccountId}\
		GroupName=$(shell yq e '.${setup}.groupName' single.yaml)\
		GroupPolicyName=$(shell yq e '.${setup}.groupPolicy' single.yaml)\
		PowerUserPolicyArn=$(shell yq e '.${setup}.powerUserPolicyArn' single.yaml)\
		OperationalResourcesRole=$(shell yq e '.${setup}.operationalResourcesRole' single.yaml)
else
ifeq ($(setup), multiple)
group: 
	@echo $(info setup is: $(value setup))
	aws cloudformation deploy \
		--output json\
		--profile ${iAmProfile}\
		--stack-name create-group\
		--template-file 2-group.cf.yaml\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		ResourceAccessorAccountId=${iAmAccountId}\
		OperationalResourcesAccountId=${logAccountId}\
		GroupName=$(shell yq e '.${setup}.groupName' multiple.yaml)\
		GroupPolicyName=$(shell yq e '.${setup}.groupPolicy' multiple.yaml)\
		PowerUserPolicyArn=$(shell yq e '.${setup}.powerUserPolicyArn' multiple.yaml)\
		OperationalResourcesRole=$(shell yq e '.${setup}.operationalResourcesRole' multiple.yaml)
endif
endif


.PHONY: user #requires setup arg (arg value must equal single or multiple)
ifeq ($(setup), single)
user:
	@echo $(info setup is: $(value setup))
	aws cloudformation deploy\
		--output json\
		--stack-name create-user\
		--template-file 3-user.cf.yaml\
		--profile ${singleAccountProfile}\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		Setup=${setup}\
		ResourceAccessorAccountId=${singleAccountId}\
		OperationalResourcesAccountId=${singleAccountId}\
		Username=$(shell yq e '.${setup}.user.name' single.yaml)\
		UserGroup=$(shell yq e '.${setup}.groupName' single.yaml)\
		UserTagKey=$(shell yq e '.${setup}.user.tagKey' single.yaml)\
		UserTagValue=$(shell yq e '.${setup}.user.tagValue' single.yaml)\
		UserPolicyName=$(shell yq e '.${setup}.user.policyName' single.yaml)\
		RoleName=$(shell yq e '.${setup}.operationalResourcesRole' single.yaml)
else
ifeq ($(setup), multiple)
user: 
	@echo $(info setup is: $(value setup))	
	aws cloudformation deploy\
		--output json\
		--profile ${iAmProfile}\
		--stack-name create-user\
		--template-file 3-user.cf.yaml\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		Setup=${setup}\
		ResourceAccessorAccountId=${iAmAccountId}\
		OperationalResourcesAccountId=${logAccountId}\
		Username=$(shell yq e '.${setup}.user.name' multiple.yaml)\
		UserGroup=$(shell yq e '.${setup}.groupName' multiple.yaml)\
		UserTagKey=$(shell yq e '.${setup}.user.tagKey' multiple.yaml)\
		UserTagValue=$(shell yq e '.${setup}.user.tagValue' multiple.yaml)\
		UserPolicyName=$(shell yq e '.${setup}.user.policyName' multiple.yaml)\
		RoleName=$(shell yq e '.${setup}.operationalResourcesRole' multiple.yaml)
endif
endif

.PHONY: tf-log-bucket-policy #relies on the absence/presence of env arg
ifndef env 
tf-log-bucket-policy:
	@echo "single account setup"
	aws cloudformation deploy \
		--output json\
		--profile ${singleAccountProfile}\
		--template-file 4-tf-log-bucket-policy.cf.yaml\
		--stack-name add-tf-logBucket-policy\
		--region $(shell yq e '.single.region' single.yaml)\
		--parameter-overrides\
		Env=${env}\
		OperationalResourcesAccountId=${singleAccountId}\
		LogBucketName=$(shell yq e '.single.logBucket' single.yaml)
else
tf-log-bucket-policy:
	@echo "$(info current env is $(value env))"
	aws cloudformation deploy \
		--output json\
		--profile ${logProfile}\
		--template-file 4-tf-log-bucket-policy.cf.yaml\
		--stack-name add-${env}-tf-logBucket-policy\
		--region $(shell yq e '.multiple.${env}.region' multiple.yaml)\
		--parameter-overrides\
		Env=${env}\
		OperationalResourcesAccountId=$(logAccountId)\
		LogBucketName=$(shell yq e '.multiple.${env}.logBucket' multiple.yaml)
endif


.PHONY: tf-state-bucket-policy #relies on the absence/presence of env arg
ifndef env
tf-state-bucket-policy:
	@echo "$(info env not reguired for setup $(value setup))"
	aws cloudformation deploy\
		--output json\
		--profile ${singleAccountProfile}\
		--stack-name add-tf-statebucket-policy\
		--template-file tf-state-bucket-policy.cf.yaml\
		--region $(shell yq e '.single.region' single.yaml)\
		--parameter-overrides\
		Env=${env}\
		ResourceAccessorAccountId=${singleAccountId}\
		OperationalResourcesAccountId=$(singleAccountId)\
		Username=$(shell yq e '.single.user.name' single.yaml)\
		AdminRoleId=$(shell yq e '.single.adminRoleId' single.yaml)\
		AdminRoleName=$(shell yq e '.single.adminRoleName' single.yaml)\
		UserTagValue=$(shell yq e '.single.user.tagValue' single.yaml)\
		StateBucketName=$(shell yq e '.single.stateBucket' single.yaml)\
		RoleName=$(shell yq e '.single.operationalResourcesRole' single.yaml)
else
ifdef env
tf-state-bucket-policy:
	@echo "$(info env reguired for setup $(value setup))"
	aws cloudformation deploy\
		--output json\
		--profile ${logProfile}\
		--template-file tf-state-bucket-policy.cf.yaml\
		--stack-name add-${env}-tf-statebucket-policy\
		--region $(shell yq e '.multiple.${env}.region' multiple.yaml)\
		--parameter-overrides\
		Env=${env}\
		ResourceAccessorAccountId=${iAmAccountId}\
		OperationalResourcesAccountId=${logAccountId}\
		Username=$(shell yq e '.multiple.user.name' multiple.yaml)\
		AdminRoleId=$(shell yq e '.multiple.adminRoleId' multiple.yaml)\
		AdminRoleName=$(shell yq e '.multiple.adminRoleName' multiple.yaml)\
		UserTagValue=$(shell yq e '.multiple.user.tagValue' multiple.yaml)\
		StateBucketName=$(shell yq e '.multiple.${env}.stateBucket' multiple.yaml)\
		RoleName=$(shell yq e '.multiple.operationalResourcesRole' multiple.yaml)
endif
endif


.PHONY: workload-role #run for only multi account setup (requires env arg)
ifndef env
workload-role:
	@echo "skip; single account setups do not need a workload policys"
else
wkLoadProfile := $(shell yq e '.multiple.${env}.profile' multiple.yaml)
wkLoadAccountId := $(shell aws --profile ${wkLoadProfile} \
	sts get-caller-identity | jq -r .Account \
)
workload-role:
	aws cloudformation deploy\
		--output json\
		--profile $(value wkLoadProfile)\
		--capabilities CAPABILITY_NAMED_IAM\
		--stack-name add-${env}-workload-role\
		--template-file 6-workload-role.cf.yaml\
		--parameter-overrides\
		WorkloadAccountId=${wkLoadAccountId}\
		ResourceAccessorAccountId=${iAmAccountId}\
		UserTagValue=$(shell yq e '.multiple.user.tagValue' multiple.yaml)\
		MaxSession=$(shell yq e '.multiple.${env}.sessionDuration' multiple.yaml)\
		WorkloadRoleName=$(shell yq e '.multiple.workload.roleName' multiple.yaml)	
endif	

.PHONY: workload-policy #run for only multi account setup (requires env arg)
ifndef env
workload-policy:
	@echo "skip; single account setups do not need a workload policys"	
else
wkLoadProfile := $(shell yq e '.multiple.${env}.profile' multiple.yaml)
wkLoadAccountId := $(shell aws --profile ${wkLoadProfile} \
	sts get-caller-identity | jq -r .Account \
)
workload-policy:
	aws cloudformation deploy\
		--output json\
		--profile ${iAmProfile}\
		--template-file 7-workload-policy.cf.yaml\
		--stack-name add-${env}-workload-policy\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		WorkloadAccountId=${wkLoadAccountId}\
		ResourceAccessorAccountId=${iAmAccountId}\
		GroupName=$(shell yq e '.multiple.groupName' multiple.yaml)\
		WorkloadRoleName=$(shell yq e '.multiple.workload.roleName' multiple.yaml)\
		WorkloadPolicyName=$(shell yq e '.multiple.workload.policyName' multiple.yaml)
endif


##-----------------------------------------------------------------------
## Print List of Make Commands
##-----------------------------------------------------------------------
.PHONY: commands 
commands: 
	@grep --color=always '^.PHONY: .* #' Makefile | sed 's/.PHONY: /\make /' | expand -t20 | column -t -s '###'