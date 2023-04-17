# Notes 
The resource created: 
	- StateBucket (and its policy)
	- LogBucket
	- LockTable  
are created in the TrustingAccount. 

Thus the caller, that is AwsProfile, must have permission to create these resources in the TrustingAccount.