# WDS Helm Charts

For detailed docuemntation visit the [official website](https://webdatasource.com/releases/latest/index.html)

## Deploy locally

To deploy this helm chart locally run the following commands. 

```sh
# Add the repo (if using a remote repository)
helm repo add webdatasource https://github.com/webdatasource/wds.helm

# Update your local repo cache
helm repo update

# Search for the chart
helm search repo webdatasource

# Install the chart
helm install webdatasource wds-helm-chart \
	--set global.coreServices.databases.mongodb.connectionString="mongodb+srv://<user>:<password>@<host>/WebDataSource?appName=<cluster>&readPreference=secondary"
```

