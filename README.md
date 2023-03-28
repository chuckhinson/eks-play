This project contains code for creating an EKS cluster.

This initial version uses terraform to create a vpc (with basic network infrastructure) and then used eksctl to stand up a cluster in that vpc.

To deploy, 
 - edit ./terraform/terrforma.tfvars to satisfy input variable requirements.
 - run mkcluster.sh which will run the terraorm and then run an eksctl command to create the cluster.  
 
Note that eksctl just creates two cloud formation templates and waits for them to complete.  It will also initialize your $HOME/.kube/config so that you can use kubectl to talk to the cluster.  For reference, the generated cloud formation templates have been saved as cluster-cfn.json and managed-nodes-cfn.json - we dont actually do anything with these (and we may delete them after we get a bit smarter about eks and eksctl)

Note that you cant see anything running on the control plane (kubectl get nodes wont even show you the control plane nodes)

I suspect we may ultimate not use eksctl for anything more than to generate the cloudformation so that we can see what needs to be created in order to get a working cluster

Unfortunately, experimentation is painful as it takes a good 15 minutes to create the cluster and see results

Still have lots of questions 
 - It appears that the only way to tell eksctl to use an existing vpc is to give it the ids of subnets that already exist in that vpc.  This also means that eksctl expects all of the networking infrastructure to already be setup (igs, nat gateway route tables, subnets)
 - You can pass eksctl a config file which seems to allow more granular control of options (you can also generate a config file using the --dry-run flag)
 - What security groups are needed and what actually needs to be in each of them
 - Look into IAM Roles for Service account (requires and OIDC endpoint)
 - What roles do we need to create and will we be able to create them or will we have to ask M2O
 - How do we want to do node groups (important for persistent storage that uses EBS)
 - Do we want/need to do customer AMI for our worker nodes (adds non-trivial complexity if we do)
 - Need to understand better how to grant access to the cluster (kubectl) to IAM users
 	+ Look at ./kube/config and note the exec section under user for doing authentication
 - Need to understand better how ingress and elbs are handled
 - eksctl seems to create the worker nodes on the public subnet - not sure if there's a reason for that of if it just makes some things easier for getting started.
 - Need to understand better the private and public networking options
 	+ I think we want our workers on the private subnets and our elbs on the publc subnets
 	


Resources:
1. https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html
2. https://docs.aws.amazon.com/eks/latest/userguide/creating-a-vpc.html
3. https://eksctl.io/
4. https://github.com/weaveworks/eksctl