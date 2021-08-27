#!/bin/bash
# Comment out the modules that you don't want to setup in your org
# Usage:
# Primary Flow installation:  ./convert-examples-to-sfdx.sh
# Re-entrant Flow installation: ./convert-examples-to-sfdx.sh -f reentrant

while getopts f: flag
do
    case "${flag}" in
        f) flow=${OPTARG}
        flow=`echo "$flow" | awk '{print tolower($0)}'` # Force to lowercase
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
newdir="force-app/main/default/lwc/"
[ -d "$newdir" ] || mkdir $newdir

cp ../examples/lwc/force-app/main/default/classes/B2BGetInfo.cls* force-app/main/default/classes/
cp ../examples/lwc/force-app/main/default/classes/B2BUtils.cls* force-app/main/default/classes/
cp ../examples/lwc/force-app/main/default/classes/B2BPaymentController* force-app/main/default/classes/
cp ../examples/lwc/force-app/main/default/classes/B2BAuthorizeTokenizedPayment* force-app/main/default/classes/
cp -r ../examples/lwc/force-app/main/default/lwc/paymentMethod force-app/main/default/lwc/
cp -r ../examples/lwc/force-app/main/default/lwc/billingAddressSelector force-app/main/default/lwc/
cp -r ../examples/lwc/force-app/main/default/lwc/cardPaymentMethod force-app/main/default/lwc/
cp -r ../examples/lwc/force-app/main/default/lwc/navigationButtons force-app/main/default/lwc/

if [[ "$flow" = "reentrant" ]]
then
    # Re-entrant Checkout
    sfdx force:mdapi:convert -r ../examples/checkout-reentrant
    printf "\nConverted the re-entrant checkout flow.\n"
else
    # Main Checkout
    sfdx force:mdapi:convert -r ../examples/checkout-main
    printf "\nConverted the main checkout flow.\n"
fi
