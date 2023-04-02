This project contains code for creating an EKS cluster.

The initial version of this project used terraform to stand up some basic infratructure (vpc, subnets, nat gateway, etc) and then used eksctl to create the cluster in the provided vpc.  From there, I grabbed the terraform that eksctl generated and converted that to terraform and just used terraform from then on.  I"ve kept the original terraform templates (managed-node-cf.json and cluster-cfn.json) for reference; they're not actually used for anything.

To deploy, 
 - edit ./terraform/terrform.tfvars to satisfy input variable requirements.
 - run terraform apply

The terraform will create a vpc with two private and two public subnets, internet gateway and nat gateway.  It puts a jumpbox on the public subnet and the cluster's nodes go in the private subnets.  You can use ```terraform  output -json | jq -r '.ssh_private_key.value``` to get the ssh private key for the jump box.  I plan to eventually disable public access endpoints, so you'll need to ssh into the jumpbox in order to interact with the cluster.  The worker nodes are setup for ssh access using the same ssh key as the jumpbox.  The jumpbox doesnt have anything installed on it, so you'll need to install kubectl and the aws cli (you'll need to use ```aws eks update-kubeconfig --name <cluster-name>``` to get your kubectl config)

Some observations and questions:

- You really cant see anything about the control plane node; kubectl get nodes doesnt even show them and kubectl get pods -A doesnt show anything that runs on the control plan nodes
- eksctl was good to start with, but I cant tell just how useful it would be as the 'go-to' tool for managing the cluster or whether it'd make more sense to just rely on the aws cli
- eksctl seems to generate some extra stuff by default (maybe just in case you choose certain options - like unmanaged nodes). I removed things that didnt look like I needed them
- It's not clear to me if I really need to tell eks about my public subnet.  I'm going to need to deploy an app and get some load balancers and see what eks does with that
- I was able to deploy the aws-ebs CSI driver and the k8s dashboard using scripts from my kubeadm-play repo without really needing to make any changes to them - they seemed to just work
- You can pass eksctl a config file which seems to allow more granular control of options (you can also generate a config file using the --dry-run flag).  Since I've converted to terraform, I doubt I'll use that unless I need to do some more experiments with eksctl to see what kind of infrastructure it generates
- It took me quite a while to get squared away in my head what security groups are actually needed.  Part of the problem was eksctl generating some extra un-used security groups.  THere are only two security groups that matter - the one that eks generates for the cluster which allows the nodes and the control plane to talk to each other, and a separate one that allow the jumpbox to access the cluster's private api endpoints.
- EKS generates lots of ENIs.  I'm not sure what all of them are for, but I assume they're at least in part support for the aws vpc CNI driver.
- I need to look at IAM Roles for Service account (requires an OIDC endpoint) as it seems that most of the official addons supported by EKS require it
  + is IRSA only available in EKS
- How do we want to do node groups (important for persistent storage that uses EBS)
  + If pv created in 1 az, will node group spawn new node in same az to make sure pods that need that volume can get scheduled in the right az
- Do we want/need to do custom AMI for our worker nodes (adds non-trivial complexity if we do)
- Need to understand better how to grant access to the cluster (kubectl) to IAM users
 	+ Look at ./kube/config and note the exec section under user for doing authentication
   + The process for granting users access seems to be well-documented - I just need to try it out 
 - Need to do some more experiments to understand better how ingress and elbs are handled
 - Do we need the cloud-controller-manager or the AWS ELB controller manager?


Resources:
1. https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html
2. https://docs.aws.amazon.com/eks/latest/userguide/creating-a-vpc.html
3. https://eksctl.io/
4. https://github.com/weaveworks/eksctl