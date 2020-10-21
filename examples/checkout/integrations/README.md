# Reference Implementations
Reference Implementation samples for B2B checkout integrations. Include Apex classes, tests and resource files for all integrations.

## Use Metadata API to deploy this using Workbench:
 1. From this folder as your current location, create a .zip file: 
	```zip -r -X <your-zip-file>.zip *```
 2. Open Workbench and go to migration -> deploy.
 3. Select the file you created ( ```<your-zip-file>.zip``` ).
 4. Check the "Single Package" checkbox on that page.
 5. Click "Next".
 6. Click "Deploy".
  
# This repository includes examples for:

## 1. Delivery
The example for Delivery implementation includes an Apex class (B2BDeliverySample.apxc) that makes a call to an external service to retrieve shipping rates and then saves that rate as an additional charge in the CartItems.

A test class is also included for reference. The test coverage of 76% will allow deployment from sandbox to production.

## 2. Check Inventory
The example for Check Inventory implementation includes an Apex class (B2BCheckInventorySample.apxc) that makes a call to an external service to verify if the quanity from the CartItems is available in the external service. For testing purposes, all items have an available quanity of 9999 in the external service.

A test class is also included for reference. The test coverage >74% will allow deployment from sandbox to production.

## 3. Pricing
The example for Pricing implementation includes an Apex class (B2BPricingSample.apxc) that makes a call to an external service to verify whether the prices of the CartItems are still the same as the ones in the external system.

A test class is also included for reference. The test coverage >74% will allow deployment from sandbox to production.

## 4. Taxation
The example for Taxation implementation includes an Apex class (B2BTaxSample.apxc) that makes a call to an external service to retrieve the tax percentages and amounts for all the CartItems, then adds those taxes to the CartTax.

A test class is also included for reference. The test coverage >74% will allow deployment from sandbox to production.

## Error Handling
There are two types of errors that surface from the reference implementations: user errors (which the buyer user sees and can correct) and admin errors (which the buyer user can’t fix).

To propagate an error to the user, add a new CartValidationOutput record. All reference implementations include examples of how to do this in integrationStatusFailedWithCartValidationOutputError.

To propagate the error to the admin, throw the exception from the reference implementation. The user is presented with a generic error message telling them to contact their admin. At the same time, a Platform Status Alert Event platform event  is published. In order for the admin to see the error message, a notification is created.

To learn how to create Platform Status Alert Event trigger for the notification, see PlatformStatusAlertEvent and Create a Custom Notification Flow.


