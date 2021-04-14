# B2B Advanced Reference Components

We provide this collection of Lightning Web Components (LWCs) as examples of configured B2B core components. Use these structures and behaviors to guide your own creation of custom B2B components that leverage existing platform features and APIs.

This repository is an SFDX project that you can deploy directly to an org and modify.

## Getting Started

### SFDX Setup

1. Before continuing with the steps below, see [Salesforce DX Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm) to setup SFDX.

## Setup

1. If you haven't already, clone this repository.
1. If you haven't already, create a B2B Commerce org.
    Optional: Use the included [project-scratch-def.json](config/project-scratch-def.json), e.g. `sfdx force:org:create -f ./config/project-scratch-def.json`
1. Push the source code in this repository to the new org, e.g. `sfdx force:source:push -u <org username>`.
1. Grant permissions to the APEX class (do this only once):

    1. Login to the org, e.g., `sfdx force:org:open -u <org username>`.
    1. Go to Setup -> Custom Code -> APEX Classes.
    1. On the B2BGetInfo class, click "Security".
    1. Assign the buyer user profile(s) or other user profiles that will use your components.
    1. Click Save.
    1. Repeat steps iii-v for B2BCartControllerSample class.

## Usage

1. Create a Commerce store.
1. Go to the Commerce app, and select the store.
1. Open Experience Builder.
1. Go to the Product Detail page.
1. Open the Builder component palette, and add the "B2B Custom Product Details" component to the page.
1. Go to the Category Detail page (repeat the next step for the Search Results page).
1. Open the Builder component palette and add the "B2B Custom Results Layout" component to the page.
1. Publish the store.

## A note on communicating between components in B2B Commerce for Lightning

As of the Winter ’21 release, Lightning Message Service (LMS) isn’t available in B2B Commerce for Lightning. As an alternative method for communication between components, these samples use the [publish-subscribe (pubsub) module](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.use_message_channel_considerations).
In a pubsub pattern, one component publishes an event while other components subscribe to receive (and handle) the event. Every component that subscribes to the event receives the event.
When LMS is supported in B2B Commerce for Lightning (Safe Harbor), we’ll update these samples to use LMS.

## Optional - Setup Demo External API Integrations

The productDetails component demonstrates how to call an external API. In our example, we call a [Demo Inventory Manager](https://inventorymanagerdemo.herokuapp.com/api/inventory/) External Service, which returns a product’s availability as a simple Boolean value. To enable this demo service in your org:

1. From Setup, enter Remote Site Settings in the Quick Find box, then select Remote Site Settings.
    This page displays a list of any remote sites that are already registered. It provides additional information about each site, including remote site name and URL.
1. Click New Remote Site.
1. For the Remote Site Name, enter Demo Inventory Manager.
1. For the remote site URL, enter https://inventorymanagerdemo.herokuapp.com.
1. Optionally, enter a site description.
1. Click Save.

## Search-specific Steps (to use Named Credentials)

Connect APIs for search don't have Apex enabled yet. So we can call those Connect APIs only through REST from Apex classes. For security reasons, the Lightning Component framework places restrictions on making API calls from JavaScript. 

* To call third-party APIs from your component’s JavaScript, add the API endpoint as a CSP Trusted Site.
* To call Salesforce APIs, make the API calls from your component’s Apex controller. Use a named credential to authenticate to Salesforce. (Documentation is [here](https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/apex_api_calls.htm) and [here](https://developer.salesforce.com/docs/atlas.en-us.228.0.apexcode.meta/apexcode/apex_callouts_named_credentials.htm).)
* Create a Named Credential callout. The steps are documented [here](/examples/lwc/docs/NamedCredentials.md).
