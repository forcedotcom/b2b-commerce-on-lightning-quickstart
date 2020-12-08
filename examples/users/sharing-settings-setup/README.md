# Sharing Settings Setup
This section will update your organization's sharing settings. For B2B, we need to allow at least "Read" access for some of the B2B-specific objects, for both internal and external access.

**WARNING!** By executing the steps below (or the corresponding SFDX commands), the sharing settings will be automatically updated! 

Processing the updates might take some time. You should wait for a confirmation email (with a content like "Your request to change your organization-wide sharing defaults has successfully completed.") or check the ```Sharing Settings``` page in setup to be sure that the change was completed.

## Use Metadata API to deploy this using Workbench:
 1. From this folder as your current location, create a .zip file: 
	```zip -r -X <your-zip-file>.zip *```
 2. Open Workbench and go to migration -> deploy.
 3. Select the file you created ( ```<your-zip-file>.zip``` ).
 4. Check the "Single Package" checkbox on that page.
 5. Click "Next".
 6. Click "Deploy".
