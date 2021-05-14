# B2B Asynchronous Checkout
The Lightning B2B Commerce checkout has several moving parts that work together to make a highly customizable checkout. This guide contains a general checkout implementation that you can use in your own org. When deployed, this package sets up a basic checkout in your org, including a framework of flows. The checkout included in this package is re-entrant. Re-entrancy saves a buyer’s spot in a checkout so they can start a checkout, leave, and come back to complete it later. With this feature, the checkout also functions if the buyer has two checkout tabs open at the same time.

This iteration of the Checkout by default tokenizes the buyer's credit information allowing for the payment screen to come before the Checkout summary screen. The payment screen is also customizable and can be found in the [lwc directory](../lwc).

## SFDX Scratch Org
If you are creating a brand new scratch org, the easiest way to install is to:
1. Go to the [SFDX directory](../../sfdx)
1. Delete the force-app folder.
   * rm -rf force-app
1. Convert the examples to the force-app directory. With the async flow flag, this will install the asynchronous checkout instead of the synchronous one.
   * ./convert-examples-to-sfdx.sh -f async
1. Follow the remaining instructions to deploy using sfdx.

## Use Metadata API to deploy this using Workbench:
1. If you haven't already, clone this repository.
1. Set up the [B2B Advanced Reference Components](../lwc). *Note:* When you complete these steps, if you've already set up a store, skip the Usage section and skip the step for creating an org
1. From this folder as your current location, create a .zip file: zip -r -x README.md -X <your-zip-file>.zip *
1. Open Workbench and go to migration -> deploy.
1. Select the file you created ( <your-zip-file>.zip ).
1. Check the Single Package checkbox on that page.
1. Click Next.
1. Click Deploy.

## Managed and Unmanaged Flows
There are two versions of each flow in this package. Some flows are marked with an Unmanaged package type and have a version prefix (Summer 2021, for example). Other flows have a Managed Installed package type.

The Unmanaged versions of the flows are uploaded as part of this example and are your primary focus. They can be modified when necessary to suit the needs of individual checkouts. You can disregard the Managed Installed flows except to use as reference. The Managed Installed versions are automatically updated each release, which is convenient, but unstable. If your checkout relies on the behavior of a previous release, automatic updates could break your implementation. We suggest using the unmanaged flows.

## Flow
Flows are central to the checkout process. Our example contains all the flows you need to make a working checkout, including the primary flow (Checkout Flow) and many subflows. Subflows have a “Subflow” prefix in their names. Import the example flows into your org to avoid starting from scratch and get a head start on the checkout process.

After importing your flows and creating a store, make sure your store uses the checkout you created here. To do so, navigate to Experience Builder in your store.

## Navigate to the Checkout page.
From the content pane, select the checkout component.
Find the Checkout Flow Name attribute. Select your primary Checkout Flow. Don't select any of the flows with Subflow in the name even if they are available.

## Flow Naming
Checkout flows are prefixed with the version of the software they are expected to work with. For example, if you see a flow labelled "(Spring 2021) Checkout Flow", the flow was designed and tested to work with the Spring 2021 release. This naming structure is used primarily for convenience and transparency. Flows still work in future versions of the software, regardless of name.

## Payments
You can find additional information in [Payment Method Tokenization](https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_payment_method_tokenization.htm)
and [Payment Authorization](https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_payment_auth.htm)
