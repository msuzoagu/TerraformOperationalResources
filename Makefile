##----------------------------------------------------------------------
## Retrieve profile names
##----------------------------------------------------------------------
userMgtProfile := $(shell yq e '.vars.userMgt.profile' vars.yaml)
devAcctProfile := $(shell yq e '.vars.dev.profile' vars.yaml)
stgAcctProfile := $(shell yq e '.vars.stg.profile' vars.yaml)
prdAcctProfile := $(shell yq e '.vars.prd.profile' vars.yaml)

tfProfile := $(shell yq e '.vars.terraform.profile' vars.yaml)
workloadacctprofile := $(shell yq e '.vars.${env}.profile' vars.yaml)



##----------------------------------------------------------------------
## Retrieve profile acccount numbers
##----------------------------------------------------------------------
userMgtAcctId := $(shell aws --profile ${userMgtProfile} \
	sts get-caller-identity | jq -r .Account \
)

devAcctId := $(shell aws --profile ${devAcctProfile} \
	sts get-caller-identity | jq -r .Account \
)

stgAcctId := $(shell aws --profile ${stgAcctProfile} \
	sts get-caller-identity | jq -r .Account \
)

prdAcctId := $(shell aws --profile ${prdAcctProfile} \
	sts get-caller-identity | jq -r .Account \
)

tfAcctId := $(shell aws --profile ${tfProfile} \
	sts get-caller-identity | jq -r .Account \
)

workloadacctid := $(shell aws --profile ${workloadacctprofile} \
	sts get-caller-identity | jq -r .Account \
)



##----------------------------------------------------------------------
## Retrieve Terraform Account Admin RoleId
##----------------------------------------------------------------------
tfAdminRole := $(shell yq e '.vars.terraform.admin' vars.yaml) 

tfAdminRoleId := $(shell aws --profile ${tfProfile} \
	iam get-role --role-name ${tfAdminRole} | jq -r .Role.RoleId \
)



##----------------------------------------------------------------------
## Create Terraform Operational Resources
##----------------------------------------------------------------------
.PHONY: backendResources
backendResources: 
ifndef env
	@echo "env is not defined"
	exit 1
endif
	aws cloudformation deploy \
		--output json\
		--profile ${tfProfile}\
		--template-file 0-backendResources.cf.yaml\
		--stack-name ${env}TfBackendResources\
		--region $(shell yq e '.vars.${env}.region' vars.yaml)\
		--parameter-overrides\
		Env=${env}\
		Region=$(shell yq e '.vars.${env}.region' vars.yaml)\
		TerraformAccountId=$(tfAcctId)\
		LogBucketName=$(shell yq e '.vars.${env}.project.lbucket' vars.yaml)\
		LockTableName=$(shell yq e '.vars.${env}.project.locktable' vars.yaml)\
		StateBucketName=$(shell yq e '.vars.${env}.project.sbucket' vars.yaml)



.PHONY: logBucketPolicy
logBucketPolicy:
ifndef env
	@echo "env is not defined"
	exit 1
endif
	aws cloudformation deploy \
		--output json\
		--profile ${tfProfile}\
		--template-file 1-logBucketPolicy.cf.yaml\
		--stack-name ${env}TfLogBucketPolicy\
		--region $(shell yq e '.vars.${env}.region' vars.yaml)\
		--parameter-overrides\
		Env=${env}\
		LogBucketName=$(shell yq e '.vars.${env}.project.lbucket' vars.yaml)\
		TerraformAccountId=$(tfAcctId)



.PHONY: backendRole
backendRole:
ifndef env
	@echo "env is not defined"
	exit 1
endif
	aws cloudformation deploy \
		--output json\
		--profile ${tfProfile}\
		--template-file 2-backendRole.cf.yaml\
		--stack-name create-role-used-to-access-terrform-backend\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		Env=${env}\
		UserMgtAccountId=${userMgtAcctId}\
		TerraformAccountId=${tfAcctId}\
		ValueOfUserTag=$(shell yq e '.vars.userMgt.tagValue' vars.yaml)\
		SessionDuration=$(shell yq e '.vars.terraform.session' vars.yaml)\
		PolicyName=$(shell yq e '.vars.terraform.policyname' vars.yaml)\
		BackendRole=$(shell yq e '.vars.terraform.rolename' vars.yaml)



.PHONY: backendGroup
backendGroup:
	aws cloudformation deploy \
		--output json\
		--profile ${userMgtProfile}\
		--template-file 3-backendGroup.cf.yaml\
		--stack-name create-group-used-to-manage-access-to-terraform-commands\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		UserMgtAccountId=${userMgtAcctId}\
		TerraformAccountId=${tfAcctId}\
		GroupName=$(shell yq e '.vars.group.name' vars.yaml)\
		PolicyName=$(shell yq e '.vars.group.backend.policyname' vars.yaml)\
		PolicyDesc=$(shell yq e '.vars.group.backenddescription' vars.yaml)\
		BackendRole=$(shell yq e '.vars.terraform.rolename' vars.yaml)



.PHONY: backendUser
backendUser:
	aws cloudformation deploy\
		--output json\
		--profile ${userMgtProfile}\
		--template-file 4-backendUser.cf.yaml\
		--stack-name create-user-permitted-to-run-terraform-commands\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		Username=$(shell yq e '.vars.userMgt.username' vars.yaml)\
		GroupName=$(shell yq e '.vars.group.name' vars.yaml)\
		UserMgtAccountId=${userMgtAcctId}\
		UserTagKey=$(shell yq e '.vars.userMgt.tagkey' vars.yaml)\
		ValueOfUserTag=$(shell yq e '.vars.userMgt.tagValue' vars.yaml)



.PHONY: stateBucketPolicy
stateBucketPolicy:
ifndef env
	@echo "env is not defined"
	exit 1
endif
	aws cloudformation deploy\
		--output json\
		--profile ${tfProfile}\
		--template-file 5-stateBucketPolicy.cf.yaml\
		--stack-name ${env}TerraformStateBucketPolicy\
		--region $(shell yq e '.vars.${env}.region' vars.yaml)\
		--parameter-overrides\
		Env=${env}\
		Username=$(shell yq e '.vars.userMgt.username' vars.yaml)\
		UserMgtAccountId=${userMgtAcctId}\
		TerraformAccountId=$(tfAcctId)\
		TerrformAdminRole=${tfAdminRole}\
		TerraformAdminRoleId=${tfAdminRoleId}\
		BackendRole=$(shell yq e '.vars.terraform.rolename' vars.yaml)\
		ValueOfUserTag=$(shell yq e '.vars.userMgt.tagValue' vars.yaml)\
		StateBucketName=$(shell yq e '.vars.${env}.project.sbucket' vars.yaml)



.PHONY: workloadRole
workloadRole:
ifndef env 
	@echo "env is not defined"
	exit 1
endif
	aws cloudformation deploy\
		--output json\
		--profile ${workloadacctprofile}\
		--template-file 6-workloadRole.cf.yaml\
		--stack-name addRoleUsed2CreateResourcesIn-DevStgPrd-Accts\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		WorkloadAccountId=${workloadacctid}\
		BackendRole=$(shell yq e '.vars.terraform.rolename' vars.yaml)\
		SessionDuration=$(shell yq e '.vars.${env}.session' vars.yaml)\
		UserMgtAccountId=${userMgtAcctId}\
		ValueOfUserTag=$(shell yq e '.vars.userMgt.tagValue' vars.yaml)


.PHONY: workloadGroupPolicy
workloadGroupPolicy:
	aws cloudformation deploy\
		--output json\
		--profile ${userMgtProfile}\
		--template-file 7-workloadPolicy.cf.yaml\
		--stack-name addGroupPolicyUsed2CreateResourcesIn-DevStgPrd-Accts\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		UserMgtAccountId=${userMgtAcctId}\
		GroupName=$(shell yq e '.vars.group.name' vars.yaml)\
		PolicyName=$(shell yq e '.vars.group.workload.policyname' vars.yaml)\
		PolicyDesc=$(shell yq e '.vars.group.workload.policydesc' vars.yaml)\
		BackendRole=$(shell yq e '.vars.terraform.rolename' vars.yaml)\
		DevelopmentAccountId=${devAcctId}


# .PHONY: add-staging-accountId-to-workloadGroupPolicy
# add-staging-accountId-to-workloadGroupPolicy:
# 	aws cloudformation update-stack\
# 		--output json\
# 		--profile ${userMgtProfile}\
# 		--template-body file://7-workloadPolicy.cf.yaml\
# 		--stack-name addGroupPolicyUsed2CreateResourcesIn-DevStgPrd-Accts\
# 		--capabilities CAPABILITY_NAMED_IAM\
# 		--parameters\
# 		ParameterKey=UserMgtAccountId,UsePreviousValue=true\
# 		ParameterKey=GroupName,UsePreviousValue=true\
# 		ParameterKey=PolicyName,UsePreviousValue=true\
# 		ParameterKey=PolicyDesc,UsePreviousValue=true\
# 		ParameterKey=BackendRole,UsePreviousValue=true\
# 		ParameterKey=DevelopmentAccountId,UsePreviousValue=true\
# 		ParameterKey=StagingAccountId,ParameterValue=${stgAcctId}


# .PHONY: add-production-accountId-to-workloadGroupPolicy
# add-production-accountId-to-workloadGroupPolicy:
# 	aws cloudformation update-stack\
# 		--output json\
# 		--profile ${userMgtProfile}\
# 		--template-body file://7-workloadPolicy.cf.yaml\
# 		--stack-name addGroupPolicyUsed2CreateResourcesIn-DevStgPrd-Accts\
# 		--capabilities CAPABILITY_NAMED_IAM\
# 		--parameters\
# 		ParameterKey=UserMgtAccountId,UsePreviousValue=true\
# 		ParameterKey=GroupName,UsePreviousValue=true\
# 		ParameterKey=PolicyName,UsePreviousValue=true\
# 		ParameterKey=PolicyDesc,UsePreviousValue=true\
# 		ParameterKey=BackendRole,UsePreviousValue=true\
# 		ParameterKey=DevelopmentAccountId,UsePreviousValue=true\
# 		ParameterKey=StagingAccountId,UsePreviousValue=true\
# 		ParameterKey=ProductionAccountId,ParameterValue=${prdAcctId}