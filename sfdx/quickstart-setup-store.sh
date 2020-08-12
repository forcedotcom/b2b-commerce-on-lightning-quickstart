#!/bin/sh
# Use this command followed by a store name.
#
# Before running this script make sure that you completed all the previous steps in the setup
# (run convert-examples-to-sfdx.sh, execute sfdx force:source:push -f, create store)
#
# This script will:
# - register the Apex classes needed for checkout integrations and map them to your store
# - associate the clone of the checkout flow to the checkout component in your store
# - add the Customer Community Plus Profile clone to the list of members for the store
# - import Products and necessary related store data in order to get you started
# - create a Buyer User and attach a Buyer Profile to it
# - create a Buyer Account and add it to the relevant Buyer Group
# - add Contact Point Addresses for Shipping and Billing to your new buyer Account
# - activate the store
# - publish your store so that the changes are reflected

if [ -z "$1" ]
then
    echo "You need to specify the name of the store."
else
    #############################
    #    Retrieve Store Info    #
    #############################

    communityNetworkName=$1
    # If the name of the store starts with a digit, the CustomSite name will have a prepended X.
    communitySiteName="$(echo $1 | sed -E 's/(^[0-9])/X\1/g')"
    # The ExperienceBundle name is similar to the CustomSite name, but has a 1 appended.
    communityExperienceBundleName="$communitySiteName"1

    # Replace the names of the components that will be retrieved.
    sed -E "s/YourCommunitySiteNameHere/$communitySiteName/g;s/YourCommunityExperienceBundleNameHere/$communityExperienceBundleName/g;s/YourCommunityNetworkNameHere/$communityNetworkName/g" quickstart-config/package-retrieve-template.xml > package-retrieve.xml

    echo "Using this to retrieve your store info:"
    cat package-retrieve.xml

    echo "Retrieving the store metadata and extracting it from the zip file."
    sfdx force:mdapi:retrieve -r experience-bundle-package -k package-retrieve.xml
    unzip -d experience-bundle-package experience-bundle-package/unpackaged.zip

    #############################
    #       Update Store        #
    #############################

    storeId=`sfdx  force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`

    # Register Apex classes needed for checkout integrations and map them to the store
    echo "1. Setting up your integrations."

    # For each Apex class needed for integrations, register it and map to the store
    function register_and_map_integration() {
        # $1 is Apex class name
        # $2 is DeveloperName
        # $3 is ExternalServiceProviderType

         # Get the Id of the Apex class
        local apexClassId=`sfdx  force:data:soql:query -q "SELECT Id FROM ApexClass WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`
        if [ -z "$apexClassId" ]
        then
            echo "There was a problem getting the ID of the Apex class $1 for checkout integrations."
            echo "The registration and mapping for this class will be skipped!"
            echo "Make sure that you run convert-examples-to-sfdx.sh and execute sfdx force:source:push -f before setting up your store."
        else
            # Register the Apex class. If the class is already registered, a "duplicate value found" error will be displayed but the script will continue.
            sfdx force:data:record:create -s RegisteredExternalService -v "DeveloperName=$2 ExternalServiceProviderId=$apexClassId ExternalServiceProviderType=$3 MasterLabel=$2"

            # Map the Apex class to the store if no other mapping exists for the same Service Provider Type
            local storeIntegratedServiceId=`sfdx  force:data:soql:query -q "SELECT Id FROM StoreIntegratedService WHERE ServiceProviderType='$3' AND StoreId='$storeId' LIMIT 1" -r csv |tail -n +2`
            if [ -z "$storeIntegratedServiceId" ]
            then
                # No mapping exists, so we will create one
                local registeredExternalServiceId=`sfdx  force:data:soql:query -q "SELECT Id FROM RegisteredExternalService WHERE ExternalServiceProviderId='$apexClassId' LIMIT 1" -r csv |tail -n +2`
                sfdx force:data:record:create -s StoreIntegratedService -v "Integration=$registeredExternalServiceId StoreId=$storeId ServiceProviderType=$3"
            else
                echo "There is already a mapping in this store for $3 ServiceProviderType: $storeIntegratedServiceId"
            fi
        fi
    }

    register_and_map_integration "B2BCheckInventorySample" "CHECK_INVENTORY" "Inventory"
    register_and_map_integration "B2BPricingSample" "COMPUTE_PRICE" "Price"
    register_and_map_integration "B2BShippingSample" "COMPUTE_SHIPPING" "Shipment"
    register_and_map_integration "B2BTaxSample" "COMPUTE_TAXES" "Tax"

    echo "You can view the results of the mapping in the Store Integrations page at /lightning/page/storeDetail?lightning__webStoreId=$storeId&storeDetail__selectedTab=store_integrations"
   
    # Map the checkout flow with the checkout component in the store
    echo "2. Updating flow associated to checkout."
    checkoutMetaFile="experience-bundle-package/unpackaged/experiences/$communityExperienceBundleName/views/checkout.json"
    tmpfile=$(mktemp)
    sed "s/sfdc_checkout__CheckoutTemplate/Summer_2020_Checkout_Flow/g" $checkoutMetaFile > $tmpfile
    mv -f $tmpfile $checkoutMetaFile

    # Add the Customer Community Plus Profile clone to the list of members for the store
    #    + add value 'Live' to field 'status' to activate community
    echo "3. Updating members list and activating community."
    networkMetaFile="experience-bundle-package/unpackaged/networks/$communityNetworkName".network
    tmpfile=$(mktemp)
    sed "s/<networkMemberGroups>/<networkMemberGroups><profile>buyer_user_profile_from_quickstart<\/profile>/g;s/<status>.*/<status>Live<\/status>/g" $networkMetaFile > $tmpfile
    mv -f $tmpfile $networkMetaFile

    # Import Products and related data
    # Get new Buyer Group Name
    echo "4. Importing products."
    buyergroupName=$(sh ./import_products.sh $1 | tail -n 1)

    # Assign a role to the admin user, else update user will error out
    echo "5. Mapping Admin User to Role."
    ceoID=`sfdx force:data:soql:query --query \ "SELECT Id FROM UserRole WHERE Name = 'CEO'" -r csv |tail -n +2`
    sfdx force:data:record:create -s UserRole -v "ParentRoleId='$ceoID' Name='AdminRoleFromQuickstart' DeveloperName='AdminRoleFromQuickstart' RollupDescription='AdminRoleFromQuickstart' "
    newRoleID=`sfdx force:data:soql:query --query \ "SELECT Id FROM UserRole WHERE Name = 'AdminRoleFromQuickstart'" -r csv |tail -n +2`
    username=`sfdx force:user:display | tail -n 1 | sed -E "s/Username[[:space:]]+//g"`
    sfdx force:data:record:update -s User -v "UserRoleId='$newRoleID'" -w "Username='$username'"

    # Create Buyer User. Go to config/buyer-user-def.json to change name, email and alias.
    echo "6. Creating Buyer User with associated Contact and Account."
    sfdx force:user:create -f config/buyer-user-def.json
    buyerusername=`grep -i '"Username":' config/buyer-user-def.json|cut -d "\"" -f 4`

    # Get most recently created account with JITUserAccount suffix
    # Convert Account to Buyer Account
    echo "Making Account a Buyer Account." 
    accountID=`sfdx force:data:soql:query --query \ "SELECT Id FROM Account WHERE Name LIKE '${buyerusername}JITUserAccount' ORDER BY CreatedDate Desc LIMIT 1" -r csv |tail -n +2`
    sfdx force:data:record:create -s BuyerAccount -v "BuyerId='$accountID' Name='BuyerAccountFromQuickstart' isActive=true"

    # Assign Account to Buyer Group
    echo "Assigning Buyer Account to Buyer Group."
    buyergroupID=`sfdx force:data:soql:query --query \ "SELECT Id FROM BuyerGroup WHERE Name = '${buyergroupName}'" -r csv |tail -n +2`
    sfdx force:data:record:create -s BuyerGroupMember -v "BuyerGroupId='$buyergroupID' BuyerId='$accountID'"

    # Add Contact Point Addresses to the buyer account associated with the buyer user.
    # The account will have 2 Shipping and 2 billing addresses associated to it.
    # To view the addresses in the UI you need to add Contact Point Addresses to the related lists for Account
    echo "7. Add Contact Point Addresses to the Buyer Account."
    existingCPAForBuyerAccount=`sfdx force:data:soql:query --query \ "SELECT Id FROM ContactPointAddress WHERE ParentId='${accountID}' LIMIT 1" -r csv |tail -n +2`
    if [ -z "$existingCPAForBuyerAccount" ]
    then
        sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Shipping' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='Vancouver' Country='Canada' IsDefault='true' Name='Default Shipping' PostalCode='V6B 5A7' State='BC' Street='333 Seymour Street (Shipping)'"
        sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Billing' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='Vancouver' Country='Canada' IsDefault='true' Name='Default Billing' PostalCode='V6B 5A7' State='BC' Street='333 Seymour Street (Billing)'"
        sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Shipping' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='Vancouver' Country='United States' IsDefault='false' Name='Non-Default Shipping' PostalCode='94105' State='CA' Street='415 Mission Street (Shipping)'"
        sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Billing' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='Vancouver' Country='United States' IsDefault='false' Name='Non-Default Billing' PostalCode='94105' State='CA' Street='415 Mission Street (Billing)'"
    else
        echo "There is already at least 1 Contact Point Address for your Buyer Account ${buyerusername}JITUserAccount"
    fi
    
    #############################
    #   Deploy Updated Store    #
    #############################

    echo "Creating the package to deploy, including the new flow."
    cd experience-bundle-package/unpackaged/
    cp -f ../../quickstart-config/package-deploy-template.xml package.xml
    zip -r -X ../"$communityExperienceBundleName"ToDeploy.zip *
    cd ../..

    # Uncomment the line below if you'd like to pause the script in order to save the zip file to deploy
    # read -p "Press any key to resume ..."

    echo "Deploy the new zip including the flow, ignoring warnings, then clean-up."
    sfdx force:mdapi:deploy -g -f experience-bundle-package/"$communityExperienceBundleName"ToDeploy.zip --wait -1 --verbose --singlepackage
    rm -fr experience-bundle-package

    echo "Removing the package xml files used for retrieving and deploying metadata at this step."
    rm package-retrieve.xml
    
    echo "8. Publishing the community."
    sfdx force:community:publish -n "$communityNetworkName"

fi
