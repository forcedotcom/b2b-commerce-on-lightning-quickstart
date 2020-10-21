# Viewing CommerceDiagnosticEvent Events with Process Builder and Custom Objects

This provides an example of how a Salesforce Admin can monitor the CommerceDiagnosticEvent platform events generated during B2B Lightning operations like checkout. It is **NOT** recommended to use this in production because it can affect the performance of your system. It is presented here as a possible option during the development process. 

For more options see the [Subscribing to Platform Events](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_subscribe.htm) documentation.

# Setup

## Use Metadata API to deploy this using Workbench:
 1. From this folder as your current location, create a .zip file: 
	```zip -r -X <your-zip-file>.zip *```
 2. Open Workbench and go to migration -> deploy.
 3. Select the file you created ( ```<your-zip-file>.zip``` ).
 4. Check the "Single Package" checkbox on that page.
 5. Click "Next".
 6. Click "Deploy".


## To listen to the CommerceDiagnosticEvents:

In Setup search for the Process Builder.

Open the **Process CommerceDiagnosticEvents** process.

In the first box after the "Start" box (called "Specify When to Start the Process"), update the Store ID Value to an ID of a valid Webstore and save.

Click "Activate" to activate the process. After this, whenever a CommerceDiagnosticEvent is generated, a new record will be added to the "Commerce Diagnostic Custom Object".


## To view those records:

Log in as the administrator for your org.

In the list of Lightning apps, search for "Commerce Diagnostic Custom Objects" and open that tab. The Admins should have access to that.

From the List Views dropdown, select "Commerce Diagnostic Event Fields" that should show you the most useful fields that were populated from the CommerceDiagnosticEvent.


