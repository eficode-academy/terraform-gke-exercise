# Exercise 1 - Create your first cluster

1. Clone the exercises git repo


```
git clone https://github.com/praqma-training/terraform-gke-exercise.git

```

2. Initialize terraform 

This prepares the working directory and installs the Google provider plugin.

```
terraform init 

```

3. Run the provided example

Inspect the `main.tf` file and test it:


```
terraform plan 

```

Inspect the plan output and see what terraform is going to do. If all looks good, proceed with:


```
terraform apply 

```

> You can pass the needed input variables with in command line as follows : terraform apply -var 'name=value' -var 'name2=value2' ...

----

# Exercise 2 - Let's make it more interesting

1. Now, let's make everything dynamic. Replace all hardcoded values with variables and allow multiple tags and labels to be provided as input. Choose default values for variables where it makes sense.

2. Also, add some output variables to extract some information about the generated cluster (e.g, the cluster endpoint).

3. So far, we used few configuration options. Check the rest of the [options](https://www.terraform.io/docs/providers/google/r/container_cluster.html ) and add some of them to your `main.tf`

4. Test your new configuration with `terraform plan`and `terraform apply`. Notice how terraform deals with config changes (e.g. changing the number of machines in the default node pool).

-----

# Exercise 3 - Let's scale the cluster

1. In your `main.tf`, add a node pool (if you haven't done so in the previous exercise). A node pool can be added as follows:

```terraform
resource "google_container_cluster" "primary" {
  ...
  # non-default node pool
  node_pool {
    name       = "${var.node_pool_name}"
    node_count = "${var.node_pool_count}"
     
   # more configurations goes here. For available options, check https://www.terraform.io/docs/providers/google/r/container_node_pool.html
  }
} 
```

2. Test your configurations with `terraform plan` and `terraform apply` 
3. Now change some of your node pool configurations (e.g, machine type) and run `terraform plan` 
4. Let's assume we want to scale the cluster and add a new node pool with new configurations. Add another node pool in your `main.tf` and run `terraform plan`. Try changing different configurations and notice the plan that Terraform generates. How about removing (commenting out) a node pool?

----

# Exercise 4 - Let's make our configurations change-resilient 

1. Move out the node pools from the cluster resource in your `main.tf` into it's own resource. Keep only one node pool and set the  `remove_default_node_pool = "true"` to remove the default node pool. This will look like: 

> Keep the number of nodes low to shorten terraform execution time.

``` 
resource "google_container_cluster" "primary" {
    ...
    remove_default_node_pool = "true"
}

# variables below need to be defined    
resource "google_container_node_pool" "np" {
  name       = "${var.node_pool_name}"
  node_count = "${var.node_pool_count}"
  zone       = "${var.cluster_zone}"
  cluster    = "${var.cluster_name}"

  # rest of pool configurations
}
``` 

2. Run `terraform plan` and `terraform apply` 
3. Now you should have a cluster with one node pool. Let's deploy a sample workload:

> If you don't have gcloud and/or kubectl on your machine, you cn do the steps below in the Google Cloud GKE console: Kubernetes Engine -> Workloads -> Deploy

```
# start a new terminal
# setup kubectl to connect to your cluster.
gcloud container clusters get-credentials <your-cluster-name> --zone <your_cluster_zone> --project <Google_cloud_project_name>

# this deploys nginx with 2 replicas 
kubectl run nginx --image=nginx --replicas=2 

# watche the changes to pods 
kubectl get pods -o wide -w

```

4. Add a new node pool in your `main.tf` with your choice of configurations and run `terraform plan` then `terraform apply`.
5. Remove the first node pool (the one hosting your nginx pods) from your `main.tf` and run `terraform plan` then `terraform apply`. While terraform apply is executing, keep an eye on the pods in the terminal you started in step 3.

> What would happen to your workload (nginx) if you have done step 5 befoer step 4? 

----

# Exercise 5 - Let's pipeline it with Circleci.

1. Create a git repo with your `main.tf` and push it to your **personal** Github account.

> Don't add terraform state files to your git repo. You can use `.gitignore` file to ignore them.

``` 
git init 
git add main.tf
git commit -m "first commit"
git remote add origin <your_github_repo_url>
git push -u origin master

```

2. Login to [circleci.com](https://circleci.com/) with your Github account. Make sure you select the correct orgainization in the top left corner and click on `Add Projects` on the left menu and make sure your new Github repo is available in the list. Click on setup project button next to your repo name and in the new page, click `Start Building`. This will start a dummy build. 

3. Now, we need to setup some environement variables for our build process. Go to Workflows -> <your repo name> and click on the settings ( the gear icon). Then you will find `Environment Variables` under the `Build Settings`section. Let's add our gcloud credentials json file contents into a variable called `GCLOUD_CREDENTIALS`. We will need this for the next step.

4. Create `.circleci` directory in your repo and add the following in a new file called `config.yml` :

```yaml
version: 2
jobs:
    terraform-plan:
      docker:
          # this image takes gcloud credentials from an env variable called: GCLOUD_CREDENTIALS and authenticates gcloud with it.
          # the credentials file is made available inside the container in: /tmp/credentials.json
        - image: praqma/terraform-gcloud

      working_directory: ~/repo
      
      steps:
        - checkout
        # you may have different input variables needed below. These will be passed from circleci environment variables
        - run:
            name: running terraform plan
            command: |
              terraform init
              terraform plan \
              -var credentials_path=/tmp/credentials.json \
              -var cluster_username=$CLUSTER_USERNAME \
              -var cluster_password=$CLUSTER_PASSWORD  

    terraform-apply:
      docker:
          # this image takes gcloud credentials from an env variable called: GCLOUD_CREDENTIALS and authenticates gcloud with it.
          # the credentials file is made available inside the container in: /tmp/credentials.json
        - image: praqma/terraform-gcloud

      working_directory: ~/repo
      
      steps:
        - checkout
        # you may have different input variables needed below. These will be passed from circleci environment variables
        - run:
            name: running terraform apply
            command: |
              terraform init
              terraform apply --auto-approve  \
              -var credentials_path=/tmp/credentials.json \
              -var cluster_username=$CLUSTER_USERNAME \
              -var cluster_password=$CLUSTER_PASSWORD  

workflows:
  version: 2
  clusters-plan-approve-and-deploy:
    jobs:
      - terraform-plan:
          filters:
            branches:
              only:
                - master

      - hold-before-creating-cluster:
          type: approval
          requires:
            - terraform-plan

      - terraform-apply:
          requires:
            - hold-before-creating-cluster     
```

5. Push the `.circleci` directory and it's content to Github and watch the workflow building in [circleci.com](https://circleci.com/) 
