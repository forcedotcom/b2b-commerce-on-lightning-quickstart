# Payment Gateway Integration Reference Implementations
Reference Implementation samples for B2B payment gateway integrations. Includes Apex classes and Named Credential files.

*Warning*: The named credential files _DO NOT_ contain valid usernames and passwords.  Once installed, they need to be manually updated with valid credentials in order to work with your preferred Gateway.

## Use Metadata API to deploy this using Workbench:
 1. From within the folder you want to use as your Gateway, create a .zip file: 
	```zip -r -X <your-zip-file>.zip *```
 2. Open Workbench and go to migration -> deploy.
 3. Select the file you created ( ```<your-zip-file>.zip``` ).
 4. Check the "Single Package" checkbox on that page.
 5. Click "Next".
 6. Click "Deploy".
  
# This repository includes examples for:

## Salesforce Gateway
A mocked gateway that will not make any external gateway calls, but great for demo purposes (eg. for displaying a credit card UI in Checkout).

## Payeezy Gateway
A gateway adapter to interact with the Payeezy gateway.  

## Stripe Gateway
A gateway adapter to interact with the Stripe gateway.

# Additional Setup

The following also needs to be set up for a successful Checkout experience:

## Payment Gateway Provider
Create through Workbench, no UI setup available.

**Workbench:**
1. Go to Data > Insert
2. Object Type: PaymentGatewayProvider
3. [x]Single Record
4. Click Next
5. Fill out required fields:

    _ApexAdapterId_ - query for ApexClass with Workbench or find it in the URL in the Setup UI (eg. 01pR0000000iA5UIAU)

## Payment Gateway
Can be created through the UI or through Workbench.

**Workbench:**
1. Go to Data > Insert
2. Object Type: PaymentGateway
3. [x]Single Record
4. Click Next
5. Fill out required fields:

    _MerchantCredentialId_ - query for the Named Credential ID with Workbench or find it in the URL in the Setup UI (eg. 0XAR00000000107OAA )

    _PaymentGatewayProviderId_ - query for PaymentGatewayProvider in Workbench (eg. 0cJR00000004CRqMAM)

    _Status_ - set to "Active"

## Store Integrated Service
Once your Payment Gateway has been created you need to map it to your store.

Go to your Store settings page (<your app>/lightning/o/WebStore/list and select your store).  Click the  Store Integrations tab then click the Link Integrations button under Card Payment Gateway.  Choose the Payment Gateway you have just set up.
