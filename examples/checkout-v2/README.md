# B2B Checkout V2

Checkout V2 is the next iteration of the example Checkout Flow. V2 is nearly identical to Checkout V1, deployed [here](../../sfdx), except that the payment screen is placed earlier in the flow. The payment screen now appears between the Delivery Address and Checkout Summary screens. This example also uses payment tokenization. When a buyer submits their payment, the checkout creates a token rather than storing payment details. The checkout uses that token after the Checkout Summary Screen to complete payment.

This repository is an SFDX project that you can deploy directly to your org and then modify. Start the deployment process by setting up [B2B Advanced Reference Components](../lwc).

## Getting Started

### SFDX Setup

1. Before you complete the steps below, see [Salesforce DX Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm) to setup SFDX.

## Setup

1. Clone the repository.
1. Follow the steps to set up [B2B Advanced Reference Components](../lwc).
1. Push the source code in this repository to the new org, e.g. `sfdx force:source:push -u <org username>`.
1. Setup a store manually or follow the steps [here](../../sfdx).
1. Once your store is set up, navigate to Experience Builder and select the CHeckout page. Change the flow to the V2...Checkout Flow.
1. Publish your store.

## Payments
You can find additional information in [Payment Method Tokenization](https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_payment_method_tokenization.htm)
and [Payment Authorization](https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_payment_auth.htm)
