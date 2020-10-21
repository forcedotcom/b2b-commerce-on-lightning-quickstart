#!/bin/sh

# Use this command followed by a store name.
#
# This script will set up all the required parts for using a new Payment Gateway
# - convert and push Named Credentials and Gateway Adapter apex to the org 
# - create a Payment Gateway Provider record
# - create a Payment Gateway record
# - create a Store Integrated Service record to map the payment integration to the store
#
# Note: The mapping to the store is not done here and needs to be done manually

function prompt_for_gateway {
    echo "Payment Gateway Adapter options:"
    echo "[0] Salesforce Mock Gateway"
    echo "[1] Payeezy"
    echo "[2] Stripe"
    read -p "Please enter the Gateway you would like to set up > " selectedAdapter
}

if [ -z "$1" ]
then
    echo "You need to specify the name of the store."
else
    while [[ ! $selectedAdapter =~ 0|1|2 ]]; do
        prompt_for_gateway
    done

    case $selectedAdapter in
    0)
        selection="Salesforce"
        ;;
    1)
        selection="Payeezy"
        ;;
    2)
        selection="Stripe"
        ;;
    esac

    namedCredentialMasterLabel=$selection
    paymentGatewayAdapterName="${selection}Adapter"
    paymentGatewayProviderName="${selection}PGP"
    paymentGatewayName="${selection}PG"
    examplesDir="../examples/checkout/payment-gateway-integration/$selection/";

    echo "Setting up $selection Gateway"

    echo "Converting Named Credentials and Gateway Adapter Apex for SFDX use..."
    sfdx force:mdapi:convert -r $examplesDir
    echo "Pushing Named Credentials and Gateway Adapter Apex to org..."
    sfdx force:source:push -f
    
    # Creating Payment Gateway Provider
    apexClassId=`sfdx force:data:soql:query -q "SELECT Id FROM ApexClass WHERE Name='$paymentGatewayAdapterName' LIMIT 1" -r csv |tail -n +2`
    echo "Creating PaymentGatewayProvider record using ApexAdapterId=$apexClassId."
    sfdx force:data:record:create -s PaymentGatewayProvider -v "DeveloperName=$paymentGatewayProviderName ApexAdapterId=$apexClassId MasterLabel=$paymentGatewayProviderName IdempotencySupported=Yes Comments=Comments"

    # Creating Payment Gateway
    paymentGatewayProviderId=`sfdx force:data:soql:query -q "SELECT Id FROM PaymentGatewayProvider WHERE DeveloperName='$paymentGatewayProviderName' LIMIT 1" -r csv | tail -n +2`
    namedCredentialId=`sfdx force:data:soql:query -q "SELECT Id FROM NamedCredential WHERE MasterLabel='$namedCredentialMasterLabel' LIMIT 1" -r csv | tail -n +2`
    echo "Creating PaymentGateway record using MerchantCredentialId=$namedCredentialId, PaymentGatewayProviderId=$paymentGatewayProviderId."
    sfdx force:data:record:create -s PaymentGateway -v "MerchantCredentialId=$namedCredentialId PaymentGatewayName=$paymentGatewayName PaymentGatewayProviderId=$paymentGatewayProviderId Status=Active"

    # Creating Store Integrated Service
    storeId=`sfdx force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$1' LIMIT 1" -r csv | tail -n +2`
    serviceMappingId=`sfdx force:data:soql:query -q "SELECT Id FROM StoreIntegratedService WHERE StoreId='$storeId' AND ServiceProviderType='Payment' LIMIT 1" -r csv | tail -n +2`
    if [ ! -z $serviceMappingId ]; then
        echo "StoreMapping already exists.  Deleting old mapping."
        sfdx force:data:record:delete -s StoreIntegratedService -i $serviceMappingId
    fi

    storeId=`sfdx force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$1' LIMIT 1" -r csv | tail -n +2`
    paymentGatewayId=`sfdx force:data:soql:query -q "SELECT Id FROM PaymentGateway WHERE PaymentGatewayName='$paymentGatewayName' LIMIT 1" -r csv | tail -n +2`
    echo "Creating StoreIntegratedService using the $1 store and Integration=$paymentGatewayId (PaymentGatewayId)"
    sfdx force:data:record:create -s StoreIntegratedService -v "Integration=$paymentGatewayId StoreId=$storeId ServiceProviderType=Payment"
    
    # To set store mapping to a different Gateway see Store Integrations or run:"
    # force:org:open -p /lightning/page/storeDetail?lightning__webStoreId=$storeId."

    namedCredentialId=`sfdx force:data:soql:query -q "SELECT Id FROM NamedCredential WHERE MasterLabel='$namedCredentialMasterLabel' LIMIT 1" -r csv | tail -n +2`
    echo "A Named Credential has been set up for you.  Please update it to use a valid username and password."
    read -p "Press [Enter/Return] to continue ..."
   
    sfdx force:org:open -p lightning/setup/NamedCredential/page?address=%2F$namedCredentialId
fi
