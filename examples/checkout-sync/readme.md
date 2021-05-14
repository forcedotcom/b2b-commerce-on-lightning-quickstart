# B2B Synchronous Checkout
The Lightning B2B Commerce checkout has several moving parts that work together to make a highly customizable checkout. This guide contains a general checkout implementation that you can use in your own org. When deployed, this package sets up a basic checkout in your org, including a framework of flows.

The Synchronous Checkout differs from the [Asynchronous Checkout](../checkout-async) in several important ways. It's no longer re-entrant and being synchronous means that if the integrations take too long, the checkout may fail. However, this checkout is simpler, contains a built in previous button and should be a bit faster.

## SFDX Scratch Org
If you are creating a brand new scratch org, the easiest way to install is to:
1. Go to the [SFDX directory](../../sfdx)
1. Delete the force-app folder.
   * rm -rf force-app
1. Convert the examples to the force-app directory. With no flag specified, it will copy over the synchronous files by default.
   * ./convert-examples-to-sfdx.sh
1. Follow the remaining instructions to deploy using sfdx.

## Use Metadata API to deploy this using Workbench:
1. If you haven't already, clone this repository.
1. Set up the [B2B Advanced Reference Components](../lwc). *Note:* When you complete these steps, if you've already set up a store, skip the Usage section and skip the step for creating an org
1. From this folder as your current location, create a .zip file: zip -r -x readme.md -X <your-zip-file>.zip *
1. Open Workbench and go to migration -> deploy.
1. Select the file you created ( <your-zip-file>.zip ).
1. Check the Single Package checkbox on that page.
1. Click Next.
1. Click Deploy.

## Flow
Flows are central to the checkout process. Our example contains both of the flows you need to make a working checkout, including the primary flow (Simple B2B Checkout) and one subflow for handling errors. Import the example flows into your org to avoid starting from scratch and get a head start on the checkout process.

After importing your flows and creating a store, make sure your store uses the checkout you created here. To do so, navigate to Experience Builder in your store.

## Navigate to the Checkout page.
From the content pane, select the checkout component.
Find the Checkout Flow Name attribute. Select your primary Checkout Flow. Don't select any of the flows with Subflow in the name even if they are available.