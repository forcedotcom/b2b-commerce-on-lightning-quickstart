#!/bin/sh
# Comment out the modules that you don't want to setup in your org

sfdx force:mdapi:convert -r ../examples/checkout/framework/
sfdx force:mdapi:convert -r ../examples/checkout/payment-gateway-integration/Salesforce/
sfdx force:mdapi:convert -r ../examples/checkout/integrations/
sfdx force:mdapi:convert -r ../examples/checkout/notifications/

sfdx force:mdapi:convert -r ../examples/users/buyer-user-profile-setup/
sfdx force:mdapi:convert -r ../examples/users/sharing-settings-setup/

sfdx force:mdapi:convert -r ../examples/diagnostic/commerce-diagnostic-event-setup/

sfdx force:mdapi:convert -r ../tests/integration/

