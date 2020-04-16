// This must implement the sfdc_checkout.CartInventoryValidation interface
// in order to be processed by the checkout flow and used for your Check Inventory integration.
global class B2BCheckInventorySample implements sfdc_checkout.CartInventoryValidation {
    global sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo jobInfo, ID cartId) {
        sfdc_checkout.IntegrationStatus integStatus = new sfdc_checkout.IntegrationStatus();
        try {
            // Get all SKUs and their quantities from cart items.
            Map<String, Decimal> quantitiesFromSalesforce = new Map<String, Decimal>();
            for (CartItem cartItem : [SELECT Sku, Quantity FROM CartItem WHERE CartId = :cartId AND Type = 'Product']) {
                quantitiesFromSalesforce.put(cartItem.Sku, cartItem.Quantity);
            }

            // Stop checkout if there are no items in the cart
            if (quantitiesFromSalesforce.isEmpty()) {
                String errorMessage = 'Looks like your cart is empty.';
                return integrationStatusFailedWithCartValidationOutputError(
                    integStatus,
                    errorMessage,
                    jobInfo,
                    cartId
                );
            }
            
            // Get all available quantities for products in the cart (cart items) from an external service.
            Map<String, Object> quantitiesFromExternalService = getQuantitiesFromExternalService(quantitiesFromSalesforce.keySet());            
            
            // For each cart item SKU, check that the quantity from the external service
            // is greater or equal to the quantity in the cart.
            // If that is not true, set the integration status to "Failed".
            for (String sku : quantitiesFromSalesforce.keySet()) {
                Decimal quantityFromSalesforce = quantitiesFromSalesforce.get(sku);
                Decimal quantityFromExternalService = (Decimal)quantitiesFromExternalService.get(sku);
                if (quantityFromExternalService == null){
                    String errorMessage = 'The product with sku ' + sku + ' could not be found in the external system';
                    return integrationStatusFailedWithCartValidationOutputError(
                       integStatus,
                       errorMessage,
                       jobInfo,
                       cartId
                   );
                } 
                else if (quantityFromExternalService < quantityFromSalesforce){
                   String errorMessage = 'Insufficient quantity for the product with sku ' + sku + ': ' 
                               + quantityFromSalesforce + ' needed, but only '
                               + quantityFromExternalService + ' available.';
                   return integrationStatusFailedWithCartValidationOutputError(
                       integStatus,
                       errorMessage,
                       jobInfo,
                       cartId
                   );
                }
                else {
                    // If the product exists and the available quantity is enough, set status as SUCCESS
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
    
    private Map<String, Object> getQuantitiesFromExternalService (Set<String> skus) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Integer SuccessfulHttpRequest = 200;

        // Encode the product SKUs to avoid any invalid characters in the request URL.
        Set<String> encodedSkus = new Set<String>();
        for (String sku : skus) {
            encodedSkus.add(EncodingUtil.urlEncode(sku, 'UTF-8'));
        }

        // To access the service below, add endpoint = https://b2b-commerce-test.herokuapp.com in Setup | Security | Remote site settings.
        request.setEndpoint('https://b2b-commerce-test.herokuapp.com/get-inventory?skus=' + JSON.serialize(encodedSkus));
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        // If the request is successful, parse the JSON response.
        // The response includes the available quantity for each SKU and uses the following format:
        // {"SKU-25-10028":9999.00, "SKU-25-10030":9999.00}
        // Because this is a sample, and we want this integration to return success.
        // The external service returns the exact list of SKUs it receives
        // and an available quantity of 9999 for each SKU.
        // If the cart has an item with a quantity higher than 9999, the integration returns an error.
        if (response.getStatusCode() == SuccessfulHttpRequest) {
            Map<String, Object> quantitiesFromExternalService = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return quantitiesFromExternalService;
        }
        else {
            throw new CalloutException ('There was a problem with the request. Error: ' + response.getStatusCode());
        }
    }  
    
    private sfdc_checkout.IntegrationStatus integrationStatusFailedWithCartValidationOutputError(
        sfdc_checkout.IntegrationStatus integrationStatus, String errorMessage, sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
            integrationStatus.status = sfdc_checkout.IntegrationStatus.Status.FAILED;
            // To propagate the error to the user, we need to add a new CartValidationOutput record.
            // The following fields must be populated:
            // BackgroundOperationId: Foreign Key to the BackgroundOperation
            // CartId: Foreign key to the WebCart that this validation line is for
            // Level (required): One of the following - Info, Error, or Warning
            // Message (optional): Message displyed to the user
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
                Type = 'Inventory'
            );
            insert(cartValidationError);
            return integrationStatus;
    }
}