// This sample is for the situation when the pricing is validated in an external service. For Salesforce internal price validation please see the corresponding documentation.

// This must implement the sfdc_checkout.CartPriceCalculations interface
// in order to be processed by the checkout flow and used for your Price Calculations integration.
global with sharing class B2BPricingSample implements sfdc_checkout.CartPriceCalculations {
    global sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
        sfdc_checkout.IntegrationStatus integStatus = new sfdc_checkout.IntegrationStatus();
        try {
            // To retrieve sale prices for a customer, get the cart owner's ID and pass it to the external service.
            // 
            // In the real-life scenario, the ID will probably be an external ID
            // that identifies the customer in the external system,
            // but for simplicity we are using the Salesforce ID in this sample.
            Id customerId = [SELECT OwnerId FROM WebCart WHERE id = :cartId WITH SECURITY_ENFORCED][0].OwnerId;
            
            // Get all SKUs and their sale prices (customer-specific prices) from the cart items.
            Map<String, Decimal> salesPricesFromSalesforce = new Map<String, Decimal>();
            for (CartItem cartItem : [SELECT Sku, SalesPrice FROM CartItem WHERE CartId = :cartId AND Type = 'Product' WITH SECURITY_ENFORCED]) {
                if (String.isBlank(cartItem.Sku)) {
                    String errorMessage = 'The SKUs for all products in your cart must be defined.';
                    return integrationStatusFailedWithCartValidationOutputError(
                        integStatus,
                        errorMessage,
                        jobInfo,
                        cartId
                    );
                }
                salesPricesFromSalesforce.put(cartItem.Sku, cartItem.SalesPrice);
            }
            
            // Get all sale prices for the products in the cart (cart items) from an external service
            // for the customer who owns the cart.
            Map<String, Object> salesPricesFromExternalService = getSalesPricesFromExternalService(salesPricesFromSalesforce.keySet(), Id.valueOf(customerId));            
            
            // For each cart item SKU, check that the price from the external service
            // is the same as the sale price in the cart.
            // If that is not true, set the integration status to "Failed".
            for (String sku : salesPricesFromSalesforce.keySet()) {
                Decimal salesPriceFromSalesforce = salesPricesFromSalesforce.get(sku);
                Decimal salesPriceFromExternalService = (Decimal)salesPricesFromExternalService.get(sku);
                if (salesPriceFromExternalService == null){
                   String errorMessage = 'The product with sku ' + sku + ' could not be found in the external system';
                   return integrationStatusFailedWithCartValidationOutputError(
                       integStatus,
                       errorMessage,
                       jobInfo,
                       cartId
                   );
                } 
                else if (salesPriceFromExternalService != salesPriceFromSalesforce){
                   // Add your logic here for when the price from your external service
                   // does not match what we have in Salesforce.
                   // For example, you may want to cause your pricing integration to fail.
                   // EXAMPLE: integStatus.status = sfdc_checkout.IntegrationStatus.Status.FAILED;
                   // 
                   // Our Heroku external service is a test service and returns a sale price of 0.00 for any SKU except 'SKU_FOR_TEST'.
                   // If the SKU of the product is 'SKU_FOR_TEST', the price returned by the external service is 100.
                   // For testing purposes, we set the integration status to SUCCESS if salesPriceFromExternalService is 0.00,
                   // regardless of the value of the Salesforce price 
                   if (salesPriceFromExternalService == 0.00){
                       integStatus.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;
                   }
                   else {
                       String errorMessage = 'The sale price has changed for the product with sku ' + sku + ': was ' 
                               + salesPriceFromSalesforce + ', but now is '
                               + salesPriceFromExternalService + '.';
                       return integrationStatusFailedWithCartValidationOutputError(
                           integStatus,
                           errorMessage,
                           jobInfo,
                           cartId
                       );
                   }
                   // ----- End of the section that is only for testing.                   
                }
                else {
                    // If the prices in the external system are the same as the prices in Salesforce, set integration status as SUCCESS.
                    integStatus.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;
                }
            }
        } catch(Exception e) {
            // For testing purposes, this example treats exceptions as user errors, which means they are displayed to the buyer user.
            // In production you probably want this to be an admin-type error. In that case, throw the exception here
            // and make sure that a notification system is in place to let the admin know that the error occurred.
            // See the readme section about error handling for details about how to create that notification.
            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                'An exception of type ' + e.getTypeName() + ' has occurred: ' + e.getMessage(),
                jobInfo,
                cartId
            );
        }
        return integStatus;
    }
    
    private Map<String, Object> getSalesPricesFromExternalService (Set<String> skus, String customerId) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Integer SuccessfulHttpRequest = 200;

        // Encode the product SKUs to avoid any invalid characters in the request URL.
        Set<String> encodedSkus = new Set<String>();
        for (String sku : skus) {
            encodedSkus.add(EncodingUtil.urlEncode(sku, 'UTF-8'));
        }

        // To access the service below you may need to add endpoint = https://b2b-commerce-test.herokuapp.com in Setup | Security | Remote site settings.
        request.setEndpoint('https://b2b-commerce-test.herokuapp.com/get-sales-prices?customerId=' 
                            + customerId + '&skus=' + JSON.serialize(encodedSkus));
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        // If the request is successful, parse the JSON response.
        // The response includes the sale price for each SKU and looks something like this:
        // {"SKU-25-10028":0.00, "SKU-25-10030":0.00, "SKU_FOR_TEST":100.00}
        // Because this is a sample only and we want this integration to return success in order to allow the checkout to pass,
        // the external service created for this sample returns the exact list of SKUs it receives,
        // and the same sale price 0.00 for each SKU.
        if (response.getStatusCode() == SuccessfulHttpRequest) {
            Map<String, Object> salesPricesFromExternalService = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return salesPricesFromExternalService;
        }
        else {
            throw new CalloutException ('There was a problem with the request. Error: ' + response.getStatusCode());
        }
    }
    
    private sfdc_checkout.IntegrationStatus integrationStatusFailedWithCartValidationOutputError(
        sfdc_checkout.IntegrationStatus integrationStatus, String errorMessage, sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
            integrationStatus.status = sfdc_checkout.IntegrationStatus.Status.FAILED;
            // In order for the error to be propagated to the user, we need to add a new CartValidationOutput record.
            // The following fields must be populated:
            // BackgroundOperationId: Foreign Key to the BackgroundOperation
            // CartId: Foreign key to the WebCart that this validation line is for
            // Level (required): One of the following - Info, Error or Warning
            // Message (optional): Message to be shown to the user
            // Name (required): The name of this CartValidationOutput record. For example CartId:BackgroundOperationId
            // RelatedEntityId (required): Foreign key to WebCart, CartItem, CartDeliveryGroup
            // Type (required): One of the following - SystemError, Inventory, Taxes, Pricing, Shipping, Entitlement, Other
            CartValidationOutput cartValidationError = new CartValidationOutput(
                BackgroundOperationId = jobInfo.jobId,
                CartId = cartId,
                Level = 'Error',
                Message = errorMessage.left(255),
                Name = (String)cartId + ':' + jobInfo.jobId,
                RelatedEntityId = cartId,
                Type = 'Pricing'
            );
            insert(cartValidationError);
            return integrationStatus;
    }
}