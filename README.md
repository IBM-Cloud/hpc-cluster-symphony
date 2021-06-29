# symphony-poc-test

Note: The Symphony Entitlement values are already provided for easier testing

1. Go to <https://cloud.ibm.com/schematics/workspaces> and create a workspace using Schematics
2. After creating the Schematics workspace, at the bottom of the page enter this github repo URL and provide the SSH token to access Github repo, and also select Terraform version as 0.13 and click Save.
3. Go to Schematic Workspace Settings, under variable section, click on "burger icons" to update the following parameters:
    - ssh_key_name with your ibm cloud SSH key name such as "sunil-ssh-key" created in a specific region in IBM Cloud
    - api_key with the api key value and mark it as sensitive to hide the API key in the IBM Cloud Console.
    - Update the hostPrefix value to the specific hostPrefix for your Symphony cluster
    - Update the management_node_count, worker_node_min_count and worker_node_max_count as per your requirement
4. Click on "Generate Plan" and ensure there are no errors and fix the errors if there are any
5. After "Generate Plan" gives no errors, click on "Apply Plan" to create resources.
6. Check the "Activity" section on the left hand side to view the resource creation progress.
7. Click on "View log" if the "Apply Plan" activity is successful and copy the output SSH command to your laptop terminal to SSH to master/primary node via a jump host public ip to SSH one of the nodes.
8. Also use this jump host public ip and change the IP address of the node you want to access via the jump host to access specific hosts.
