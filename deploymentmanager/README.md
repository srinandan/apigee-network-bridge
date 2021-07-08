
##How to deploy this using Google Deployment Manager

1. Create a service account with the following roles.
    - roles/storage.objectViewer
    - roles/logging.logWriter
    - roles/monitoring.metricWriter
    - roles/apigee.readOnlyAdmin
2. Modify the test_config.yaml file with the correct values

3. Run the following gcloud command
    ```
    gcloud deployment-manager deployments create  --config test_config.yaml bridge-us-east4
    ```

4. After the solution deploys it may take upto 60 mins to provision Google Managed
SSL certs for your domain. If you did not specify a domain it will auto-provision certs for
<Load-Balancer-IP>.xip.io domain.

5. If you specified a domain, update the DNS entry to point to the load 
balancer IP address

6. If you do not want to use the Google Managed SSL certs upload your certs and
 change the load balancer to use the new certs