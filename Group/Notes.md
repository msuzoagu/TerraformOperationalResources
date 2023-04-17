# Notes 
The resource created - the group and its attached policy and permissions, are created in the TrustedAccount. Thus enabling members of the group to assume relevant role in TrustingAccount.

Caller, that is AwsProfile, must have permission to: 
	- create group
	- create policy 
	- create permissions 
in the TrustedAccount. 	