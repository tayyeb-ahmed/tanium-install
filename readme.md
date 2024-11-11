we must create the yaml file for the dashboard using the dashboard_tool.py script in LZ-SBNA-Custom-Config/compliance-dashboard. You can run it using the command:

./dashboard_tool.py cfn-sec-compliance-compliance-dashboard.yaml 5d053b2e-0007-41ab-ae06-aec39ae199e0 | tee cfn-sec-compliance-compliance-dashboard-new.yaml


Replace the bolded text with the dashboard ID of the dashboard you want to create the yaml template for, which is located in the URL of the dashboard.
