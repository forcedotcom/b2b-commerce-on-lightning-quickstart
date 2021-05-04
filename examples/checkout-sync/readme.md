## Limitations
This currently only works for orgs with multiple currencies enabled.

## Use Metadata API to deploy this using Workbench:
1. If you haven't already, clone this repository.
1. Set up the [Checkout V2](../checkout-v2). *Note:* When you complete these steps, if you've already set up a store, skip the Usage section and skip the step for creating an org. This will also require you to setup lwc.
1. From this folder as your current location, create a .zip file: 
	```zip -r -x readme.md -X checkout-sync.zip *```
1. Open Workbench and go to migration -> deploy.
1. Select the file you created ( ```checkout-sync.zip``` ).
1. Check the **Single Package** checkbox on that page.
1. Click **Next**.
1. Click **Deploy**.
