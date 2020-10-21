# B2B-Checkout Framework
The Lightning B2B Commerce checkout has several moving parts that work together to make a highly customizable checkout. This guide contains a general checkout implementation that you can use in your own org. When deployed, this package sets up a basic checkout in your org, including a framework of flows. The checkout included in this package is re-entrant. Re-entrancy saves a buyer’s spot in a checkout so they can start a checkout, leave, and come back to complete it later. With this feature, the checkout also functions if the buyer has two checkout tabs open at the same time.

This framework helps you get started, but the integration examples are also important.  The integrations support the checkout by providing information like cost of tax and available inventory.

## Use Metadata API to deploy this using Workbench:
 1. From this folder as your current location, create a .zip file: 
	```zip -r -X <your-zip-file>.zip *```
 2. Open Workbench and go to migration -> deploy.
 3. Select the file you created ( ```<your-zip-file>.zip``` ).
 4. Check the **Single Package** checkbox on that page.
 5. Click **Next**.
 6. Click **Deploy**.

## Managed and Unmanaged Flows

There are two versions of each flow in this package. Some flows are marked with an `Unmanaged` package type and have a version prefix (Winter 2021, for example). Other flows have a `Managed Installed` package type.

The `Unmanaged` versions of the flows are uploaded as part of this example and are your primary focus. They can be modified when necessary to suit the needs of individual checkouts. You can disregard the `Managed Installed `flows except to use as reference. The `Managed Installed` versions are automatically updated each release, which is convenient, but unstable. If your checkout relies on the behavior of a previous release, automatic updates could break your implementation. We suggest using the unmanaged flows.

## Flow

Flows are central to the checkout process. Our example contains all the flows you need to make a working checkout, including the primary flow (Checkout Flow) and many subflows. Subflows have a “Subflow” prefix in their names. Import the example flows into your org to avoid starting from scratch and get a head start on the checkout process.

After importing your flows and creating a store, make sure your store uses the checkout you created here. To do so, navigate to Experience Builder in your store.

- Navigate to the **Checkout** page.
- From the content pane, select the checkout component.
- Find the Checkout Flow Name attribute. Select your primary Checkout Flow. Don't select any of the flows with Subflow in the name even if they are available.


### Flow Naming

Checkout flows are prefixed with the version of the software they are expected to work with. For example, if you see a flow labelled "(Winter 2021) Checkout Flow", the flow was designed and tested to work with the Winter 2021 release. This naming structure is used primarily for convenience and transparency. Flows still work in future versions of the software, regardless of name.
