# Installing eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64" > eksctl
chmod +x eksctl
sudo mv eksctl /usr/local/bin

# Creating eksctl cluster with pre-configured yaml
eksctl create cluster -f eks-settings.yaml