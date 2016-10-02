
# The AWS region to deploy to
region = "us-east-1"

# These are convenient images available in Docker Hub to test this application. To deploy your own images, fill in the
# image names and versions here
reveluxlabs_site_image = "519885712119.dkr.ecr.us-east-1.amazonaws.com/reveluxlabs/reveluxlabs"
reveluxlabs_site_version = "latest"

smart_machines_site_image = "519885712119.dkr.ecr.us-east-1.amazonaws.com/reveluxlabs/smart-machines"
smart_machines_site_version = "latest"

sittingapp_webapp_image = "519885712119.dkr.ecr.us-east-1.amazonaws.com/reveluxlabs/sitting"
sittingapp_webapp_version = "latest"

# The name of a Key Pair that can be used to SSH to each EC2 instance. Use the AWS EC2 console to create the Key Pair:
# https://console.aws.amazon.com/ec2/v2/home
key_pair_name = "deploy-key-pair-useast1"

# Specify the VPC to use here. If you're not using custom VPCs and custom subnets, then:
#
# 1. Set vpc_id to the id of the "Default" VPC from the VPC list: https://console.aws.amazon.com/vpc/home?region=us-east-1#vpcs:
#    (e.g. vpc_id = "vpc-123456")
# 2. Set both subnet_ids lists to the subnet ids (separated with commas) from the subnet list: https://console.aws.amazon.com/vpc/home?region=us-east-1#subnets:
#    (e.g. elb_subnet_ids = "subnet-123456,subnet-4dkd3414,subnet-344kk3k1")
vpc_id = "vpc-63e67f07"
elb_subnet_ids = "subnet-d7c3dcfc,subnet-2faa2d12,subnet-83fd10db"
ecs_cluster_subnet_ids = "subnet-d7c3dcfc,subnet-2faa2d12,subnet-83fd10db"


