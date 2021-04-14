# B2B Checkout V2

Checkout V2 is the next iteration of the example Checkout Flow. V2 is nearly identical to Checkout V1, deployed [here](../../sfdx), except that the payment screen is placed earlier in the flow. The payment screen now appears between the Delivery Address and Checkout Summary screens. This example also uses payment tokenization. When a buyer submits their payment, the checkout creates a token rather than storing payment details. The checkout uses that token after the Checkout Summary Screen to complete payment.

This repository is an SFDX project that you can deploy directly to your org and then modify. Start the deployment process by setting up [B2B Advanced Reference Components](../lwc).

## Getting Started

### SFDX Setup

1. Before you complete the steps below, see [Salesforce DX Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm) to setup SFDX.

## Setup

1. If you haven't already, clone this repository.
1. Set up the [B2B Advanced Reference Components](../lwc). *Note:* When you complete these steps, if you've already set up a store, skip the Usage section and skip the step for creating an org.
1. Push the source code in this folder (`examples/checkout-v2`) to the new org, such as `sfdx force:source:push -u <org username>`.
1. Setup a store manually, or use [sfdx](../../sfdx).
1. After the store is set up, navigate to Experience Builder, and select the Checkout page. Change the flow to the V2 <Release Version> Checkout Flow.
1. Publish your store.
1. Add profiles to the enabled profiles for the `B2BPaymentController` Apex class so that buyer can access its methods.
   1. From Setup, enter `Apex Classes` in the Quick Find box, and then select *Apex Classes*.
   1. Find the `B2BPaymentController` class, and click *Security*.
   1. Find a buyer or buyer manager profile that you want to add, and add it to the list of enabled profiles.
   1. Save your changes.


## Payments
You can find additional information in [Payment Method Tokenization](https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_payment_method_tokenization.htm)
and [Payment Authorization](https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_payment_auth.htm)
