# Deploying to a Cloud Environment

We'll post instructions once we figure it out--still working on getting the whole thing working on local containers. (2019-06-09)

## Preparing for Cloud Deployment

### Setting up Terraform 

#### Creating a Remote State Store in S3

In your AWS account:

1. Create a bucket in S3 to act as the remote state store. Yours will require a unique name, so for the rest of this document we'll refer to that as `tfstate_s3_bucket`. Per the Terraform docs, you should turn on Bucket Versioning to allow for state recovery.
1. In that bucket you will need to choose a key name for the state store, but you don't need to actually create the object now--just come up with a name. We'll call that `tfstate/oss_carto` for the rest of the document.
1. Create an IAM policy that, to comply with [this Hashicorp guide](https://www.terraform.io/docs/backends/types/s3.html), does the following:
    * On the bucket `tfstate_s3_bucket`, allow `s3:ListBucket`
    * On the key `tfstate/oss_carto` in that bucket, allow `s3:GetObject` and `s3:PutObject`
1. Create an IAM group (something like 'TerraformUsers') and attach the policy you created to that group.
1. Add the User or Role that you plan to execute Terraform as to the Group.

Your team should now be able to use your S3 bucket as a remote store for Terraform state.

### Setting up Vault

### Creating Organization-Specific Configuration
