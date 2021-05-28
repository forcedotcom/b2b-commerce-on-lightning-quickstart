#!/bin/bash
# Comment out the modules that you don't want to setup in your org
# Usage:
# Synchronous Flow installation:  ./convert-examples-to-sfdx.sh
# Asynchronous Flow installation: ./convert-examples-to-sfdx.sh -f async

while getopts f: flag
do
    case "${flag}" in
        f) flow=${OPTARG}
        flow=`echo "${flow,,}"` # Ensure lower case
         ;;
    esac
done

sfdx force:mdapi:convert -r ../examples/checkout/payment-gateway-integration/Salesforce/
sfdx force:mdapi:convert -r ../examples/checkout/notifications/

sfdx force:mdapi:convert -r ../examples/users/buyer-user-profile-setup/
sfdx force:mdapi:convert -r ../examples/users/sharing-settings-setup/

sfdx force:mdapi:convert -r ../examples/diagnostic/commerce-diagnostic-event-setup/

# Contains some files that are only used for asynchronous checkouts, but others are shared for sync as well 
sfdx force:mdapi:convert -r ../examples/checkout/integrations/
sfdx force:mdapi:convert -r ../tests/integration/

# Payments related changes
mkdir force-app/main/default/lwc/
cp ../examples/lwc/force-app/main/default/classes/B2BGetInfo.cls* force-app/main/default/classes/
cp ../examples/lwc/force-app/main/default/classes/B2BUtils.cls* force-app/main/default/classes/
cp ../examples/lwc/force-app/main/default/classes/B2BPaymentController* force-app/main/default/classes/
cp ../examples/lwc/force-app/main/default/classes/B2BAuthorizeTokenizedPayment* force-app/main/default/classes/
cp -r ../examples/lwc/force-app/main/default/lwc/paymentMethod force-app/main/default/lwc/
cp -r ../examples/lwc/force-app/main/default/lwc/billingAddressSelector force-app/main/default/lwc/
cp -r ../examples/lwc/force-app/main/default/lwc/cardPaymentMethod force-app/main/default/lwc/

if [[ "$flow" = "async" ]]
then
    # Async Checkout
    sfdx force:mdapi:convert -r ../examples/checkout-async
    printf "\nConverted the asynchronous flow.\n"
else
    # Sync Checkout
    sfdx force:mdapi:convert -r ../examples/checkout-sync
    printf "\nConverted the synchronous flow.\n"
fi
