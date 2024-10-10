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

# Makes sure a "force-app" directory exists, as later commands depend on this directory
mkdir -p force-app

sf project convert mdapi -r ../examples/checkout/payment-gateway-integration/Salesforce/
sf project convert mdapi -r ../examples/checkout/notifications/

sf project convert mdapi -r ../examples/users/buyer-user-profile-setup/
sf project convert mdapi -r ../examples/users/sharing-settings-setup/

sf project convert mdapi -r ../examples/diagnostic/commerce-diagnostic-event-setup/

# Contains some files that are only used for asynchronous checkouts, but others are shared for sync as well
sf project convert mdapi -r ../examples/checkout/integrations/
sf project convert mdapi -r ../tests/integration/

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
    sf project convert mdapi -r ../examples/checkout-reentrant
    printf "\nConverted the re-entrant checkout flow.\n"
else
    # Main Checkout
    sf project convert mdapi -r ../examples/checkout-main
    printf "\nConverted the main checkout flow.\n"
fi
