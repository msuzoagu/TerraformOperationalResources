.PHONY: operationalResourceSet	#creates operational resource set 
ifdef env 
ifdef project
region:=$(shell yq e '.${project}.${env}.region' vars.yaml)
logProfile:=$(shell yq e '.${project}.log.profile' vars.yaml)
logAccountId:=$(shell aws --profile ${logProfile} \
	sts get-caller-identity | jq -r .Account \
)
operationalResourceSet:
	aws cloudformation deploy\
		--output json\
		--region ${region}\
		--profile ${logProfile}\
		--template-file 0createOperationalResources.cf.yaml\
		--stack-name ${env}TerraformBackendResources-${project}Project\
		--parameter-overrides\
		Env=${env}\
		Region=${region}\
		Project=${project}\
		LogAccountId=$(logAccountId)\
		LogBucketName=$(shell yq e '.${project}.${env}.logBucket' vars.yaml)\
		LockTableName=$(shell yq e '.${project}.${env}.lockTable' vars.yaml)\
		StateBucketName=$(shell yq e '.${project}.${env}.stateBucket' vars.yaml)	
endif
else
operationalResourceSet: 
	@echo "$(info command: make operationalResourceSet env=env_name project=project_name)"
endif


.PHONY: backendRole #resource set creation requires template update; see README
ifdef env
ifdef project	
tfRole := $(shell yq e '.${project}.roles.backend.name' vars.yaml)
tagValue := $(shell yq e '.${project}.user.tagValue' vars.yaml)
iAmProfile := $(shell yq e '.${project}.iam.profile' vars.yaml)
session:=$(shell yq e '.${project}.maxSessionDuration' vars.yaml)
iAmAccountId := $(shell aws --profile ${iAmProfile} sts get-caller-identity | jq -r .Account)
backendRole:
	aws	cloudformation deploy\
		--output json\
		--profile ${logProfile}\
		--stack-name terraformBackendRole\
		--capabilities CAPABILITY_NAMED_IAM\
		--template-file 1createTfBackendRole.cf.yaml\
		--parameter-overrides\
		Session=${session}\
		RoleName=${tfRole}\
		LogAccountId=${logAccountId}\
		ValueForPrincipalTag=${tagValue}\
		TrustedAccountId=${iAmAccountId}\
		LockTableArns=$(shell yq e '.${project}.log.lockTableArns' vars.yaml)\
		StateBucketArns=$(shell yq e '.${project}.log.stateBucketArns' vars.yaml)
endif
else
backendRole: 
	@echo "$(info command: make backendRole env=env_name project=project_name)"
endif


.PHONY: group #creates group in trusting account
ifdef env
ifdef project
groupName:= $(shell yq e '.${project}.group.name' vars.yaml)	
group: 
	aws cloudformation deploy \
		--output json\
		--profile ${iAmProfile}\
		--template-file 2createGroup.cf.yaml\
		--capabilities CAPABILITY_NAMED_IAM\
		--stack-name operationalResourceGroup\
		--parameter-overrides\
		GroupName=${groupName}\
		LogAccountId=${logAccountId}\
		TrustedAccountId=${iAmAccountId}\
		BackendRole=$(shell yq e '.${project}.log.role.name' vars.yaml)\
		AssumePolicy=$(shell yq e '.${project}.group.policies[1]' vars.yaml)\
		UserDataPolicy=$(shell yq e '.${project}.group.policies[0]' vars.yaml)
endif
else
group:
		@echo "$(info command: make group env=env_name project=project_name)"
endif


.PHONY: user #creates user in trusting account
ifdef env
ifdef project	
userName := $(shell yq e '.${project}.user.name' vars.yaml)
user: 
	aws cloudformation deploy\
		--output json\
		--profile ${iAmProfile}\
		--template-file 3createUser.cf.yaml\
		--capabilities CAPABILITY_NAMED_IAM\
		--stack-name operationalResourceUser\
		--parameter-overrides\
		Username=${userName}\
		UserGroup=${groupName}\
		LogAccountId=${logAccountId}\
		ValueForPrincipalTag=${tagValue}\
		TrustedAccountId=${iAmAccountId}\
		KeyForPrincipalTag=$(shell yq e '.${project}.user.tagKey' vars.yaml)
endif
else
user: 
		@echo "$(info command: make user env=env_name project=project_name)"
endif




.PHONY: logBucketPolicy #run once for each new resource set created
ifdef env 
ifdef project
logBucketPolicy:
	aws cloudformation deploy \
		--output json\
		--region ${region}\
		--profile ${logProfile}\
		--template-file 4createLogBucketPolicy.cf.yaml\
		--stack-name ${env}TerraformLogBucketPolicy-${project}Project\
		--parameter-overrides\
		Env=${env}\
		Project=${project}\
		LogAccountId=$(logAccountId)\
		LogBucketName=$(shell yq e '.${project}.${env}.logBucket' vars.yaml)
endif
else
logBucketPolicy:
	@echo "$(info command: make logBucketPolicy env=env_name project=project_name)"	
endif


.PHONY: stateBucketPolicy #run once for each new resource set created
ifdef env
ifdef project
stateBucketPolicy:
	aws cloudformation deploy\
		--output json\
		--region ${region}\
		--profile ${logProfile}\
		--template-file 5createStateBucketPolicy.cf.yaml\
		--stack-name ${env}TerraformStateBucketPolicy-${project}Project\
		--parameter-overrides\
		Env=${env}\
		Project=${project}\
		Username=${userName}\
		BackendRoleName=${tfRole}\
		LogAccountId=${logAccountId}\
		ValueForPrincipalTag=${tagValue}\
		TrustedAccountId=${iAmAccountId}\
		AdminRoleId=$(shell yq e '.${project}.adminRoleId' vars.yaml)\
		AdminRoleName=$(shell yq e '.${project}.adminRoleName' vars.yaml)\
		StateBucketName=$(shell yq e '.${project}.${env}.stateBucket' vars.yaml)
endif
else
stateBucketPolicy:
	@echo "$(info command: make stateBucketPolicy env=env_name project=project_name)"
endif


.PHONY: resourceRole #run once for each new resource set created
ifdef env
ifdef project	
trustingProfile := $(shell yq e '.${project}.${env}.profile' vars.yaml)
trustingAccountId := $(shell aws --profile ${trustingProfile} sts get-caller-identity | jq -r .Account \
)
resourceRole=$(shell yq e '.${project}.roles.resource.name' vars.yaml)
resourceRole:
	aws cloudformation deploy\
		--output json\
		--profile $(value trustingProfile)\
		--capabilities CAPABILITY_NAMED_IAM\
		--template-file 6createResourceRole.cf.yaml\
		--stack-name ${env}${resourceRole}Role-for-${project}Project\
		--parameter-overrides\
		Session=${session}\
		ResourceRoleName=${resourceRole}\
		TrustedAccountId=${iAmAccountId}\
		ValueForPrincipalTag=${tagValue}\
		TrustingAccountId=${trustingAccountId}\
		PolicyName=$(shell yq e '.${project}.roles.resource.policyName' vars.yaml)\
		PowerUserArn=$(shell yq e '.${project}.roles.resource.powerUserArn' vars.yaml)
endif	
else
resourceRole:
	@echo "$(info command: make resourceRole env=env_name project=project_name)"
endif


.PHONY: resourceRolePolicy #update req. for each resourceRole created; see README
ifdef env
ifdef project		
resourceRolePolicy:
	aws cloudformation deploy\
		--output json\
		--profile ${iAmProfile}\
		--template-file 7createResourceRolePolicy.cf.yaml\
		--stack-name ${env}${resourceRole}RolePolicy-for-${project}Project\
		--capabilities CAPABILITY_NAMED_IAM\
		--parameter-overrides\
		GroupName=${groupName}\
		ResourceAccountRoleName=${resourceRole}\
		PolicyName=$(shell yq e '.${project}.group.assumeResourceRole' vars.yaml)\
		TrustedAccountId=${iAmAccountId}\
		TrustingAccountId=${trustingAccountId}
endif
else
resourceRolePolicy:
	@echo "$(info command: make resourceRolePolicy env=env_name project=project_name)"
endif



.PHONY: help 
help: 
	@grep --color=always '^.PHONY: .*#' Makefile | sed 's/.PHONY: /\make /' | expand -t20 | column -t -s '###'
