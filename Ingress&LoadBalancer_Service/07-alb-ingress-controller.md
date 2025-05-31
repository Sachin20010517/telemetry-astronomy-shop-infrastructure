# How to setup alb add on

##  Setup OIDC Connector

### commands to configure IAM OIDC provider 

*The IAM OIDC provider is used to establish trust between your EKS cluster and AWS IAM, allowing Kubernetes service accounts to assume IAM roles using web identity federation. The IAM OIDC provider helps your EKS cluster talk securely with AWS IAM. It allows Kubernetes service accounts (used by pods in your cluster) to temporarily get permissions from AWS without needing access keys.

This is done using a trusted link (OIDC), so AWS knows the requests are coming from your cluster.
```
export cluster_name=demo-cluster
```
Get the OIDC issuer URL from your EKS cluster and extract the OIDC ID:

```
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5) 
```
Confirm the OIDC ID was retrieved
```
echo $oidc_id
```
## Check if there is an IAM OIDC provider configured already

- aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4\n 

If not, run the below command

```
eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve
```

## Download IAM policy

```
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json
```

Create IAM Policy

```
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
```

Create IAM Role

```
eksctl create iamserviceaccount \
  --cluster=<your-cluster-name> \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::<your-aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

## Deploy ALB controller

Add helm repo

```
helm repo add eks https://aws.github.io/eks-charts
```

Update the repo

```
helm repo update eks
```

Install

```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \            
  -n kube-system \
  --set clusterName=<your-cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=<region> \
  --set vpcId=<your-vpc-id>
```

Verify that the deployments are running.

```
kubectl get deployment -n kube-system aws-load-balancer-controller
```

You might face the issue, unable to see the loadbalancer address while giving k get ing -n robot-shop at the end. To avoid this your **AWSLoadBalancerControllerIAMPolicy** should have the required permissions for elasticloadbalancing:DescribeListenerAttributes.

## Run the following command to retrieve the policy details and look for **elasticloadbalancing:DescribeListenerAttributes** in the policy document.
```
aws iam get-policy-version \
    --policy-arn arn:aws:iam::<your-aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
    --version-id $(aws iam get-policy --policy-arn arn:aws:iam::<your-aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicy --query 'Policy.DefaultVersionId' --output text)
```

If the required permission is missing, update the policy to include it
## Download the current policy
```
aws iam get-policy-version \
    --policy-arn arn:aws:iam::<your-aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
    --version-id $(aws iam get-policy --policy-arn arn:aws:iam::<your-aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicy --query 'Policy.DefaultVersionId' --output text) \
    --query 'PolicyVersion.Document' --output json > policy.json
```
## Edit policy.json to add the missing permissions
```
{
  "Effect": "Allow",
  "Action": "elasticloadbalancing:DescribeListenerAttributes",
  "Resource": "*"
}
```
## Create a new policy version
```
aws iam create-policy-version \
    --policy-arn arn:aws:iam::<your-aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://policy.json \
    --set-as-default
```
