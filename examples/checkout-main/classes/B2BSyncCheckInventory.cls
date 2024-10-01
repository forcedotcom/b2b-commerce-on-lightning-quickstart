// This class verifies that there is sufficient inventory to cover the buyer's order
global with sharing class B2BSyncCheckInventory {
    // You MUST change this to be your service or you must launch your own Heroku Service
    // and add the host in Setup | Security | Remote site settings.
    private static String httpHost = 'https://example.com';
    private static Boolean useHTTPService = false;
    // This invocable method only expects one ID
    @InvocableMethod(callout=true label='Ensure sufficient inventory' description='Runs a synchronous version of check inventory' category='B2B Commerce')
    public static void syncCheckInventory(List<ID> cartIds) {
        // Validate the input
        if (cartIds == null || cartIds.size() != 1) {
            String errorMessage = 'A cart id must be included to B2BSyncCheckInventory';
            // Sync non-user errors skip saveCartValidationOutputError
            throw new IllegalArgumentException (errorMessage);
        }
        
        // Extract cart id and start processing
        Id cartId = cartIds[0];
        startCartProcessSync(cartId);
    }
    
    private static void startCartProcessSync(ID cartId) {
        // Get all SKUs and their quantities from cart items.
        Map<String, Decimal> quantitiesFromSalesforce = new Map<String, Decimal>();
        for (CartItem cartItem : [SELECT Sku, Quantity FROM CartItem WHERE CartId = :cartId AND Type = 'Product' WITH SECURITY_ENFORCED]) {
            if (String.isBlank(cartItem.Sku)) {
                String errorMessage = 'The SKUs for all products in your cart must be defined.';
                saveCartValidationOutputError(errorMessage, cartId);
                throw new CalloutException(errorMessage);
            }
            quantitiesFromSalesforce.put(cartItem.Sku, cartItem.Quantity);
        }

        // Stop checkout if there are no items in the cart
        if (quantitiesFromSalesforce.isEmpty()) {
            String errorMessage = 'Looks like your cart is empty.';
            saveCartValidationOutputError(errorMessage, cartId);
            throw new CalloutException(errorMessage);        
        }
        
        // Following snippet of code fetches a mocked static json response from getQuantitiesFromStaticResponse.
        // Another example that demonstrates how to call a live 3rd party HTTP Service to fetch the desired 
        // response is implemented in getQuantitiesFromExternalService method.
        Map<String, Object> quantitiesFromExternalService = null;
        if(useHTTPService) {
            quantitiesFromExternalService = getQuantitiesFromExternalService(cartId, quantitiesFromSalesforce.keySet());
        } else {
            quantitiesFromExternalService = getQuantitiesFromStaticResponse(cartId, quantitiesFromSalesforce.keySet());
        }           
        
        // For each cart item SKU, check that the quantity from the external service
        // is greater or equal to the quantity in the cart.
        // If that is not true, set the integration status to "Failed".
        for (String sku : quantitiesFromSalesforce.keySet()) {
            Decimal quantityFromSalesforce = quantitiesFromSalesforce.get(sku);
            Decimal quantityFromExternalService = (Decimal)quantitiesFromExternalService.get(sku);
            if (quantityFromExternalService == null){
                String errorMessage = 'The product with sku ' + sku + ' could not be found in the external system';
                saveCartValidationOutputError(errorMessage, cartId);
                throw new CalloutException(errorMessage);
            } 
            else if (quantityFromExternalService < quantityFromSalesforce){
                String errorMessage = 'Insufficient quantity for the product with sku ' + sku + ': ' 
                           + quantityFromSalesforce + ' needed, but only '
                           + quantityFromExternalService + ' available.';
                saveCartValidationOutputError(errorMessage, cartId);
                throw new CalloutException(errorMessage);
            }
        }
    }

    private static Map<String, Object> getQuantitiesFromStaticResponse(ID cartId, Set<String> skus) {
        if (skus.isEmpty()) {
            return (Map<String, Object>) JSON.deserializeUntyped('{"error":"Input SKUs list is empty or undefined."}');
        }
        String responseJson = '{';
        for (String sku : skus) {
            responseJson = responseJson + '"'+sku+'"';
            responseJson = responseJson + ':';
            responseJson = responseJson + '9999.00';
            responseJson = responseJson + ',';
        }
        responseJson = responseJson.removeEnd(',') + '}';
        return (Map<String, Object>) JSON.deserializeUntyped(responseJson);
    }
    
    private static Map<String, Object> getQuantitiesFromExternalService (ID cartId, Set<String> skus) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Integer successfulHttpRequest = 200;

        // Encode the product SKUs to avoid any invalid characters in the request URL.
        Set<String> encodedSkus = new Set<String>();
        for (String sku : skus) {
            encodedSkus.add(EncodingUtil.urlEncode(sku, 'UTF-8'));
        }

        request.setEndpoint(httpHost + '/get-inventory?skus=' + JSON.serialize(encodedSkus));
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        // If the request is successful, parse the JSON response.
        // The response includes the available quantity for each SKU and uses the following format:
        // {"SKU-25-10028":9999.00, "SKU-25-10030":9999.00}
        // Because this is a sample, and we want this integration to return success.
        // The external service returns the exact list of SKUs it receives
        // and an available quantity of 9999 for each SKU.
        // If the cart has an item with a quantity higher than 9999, the integration returns an error.
        if (response.getStatusCode() == successfulHttpRequest) {
            Map<String, Object> quantitiesFromExternalService = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return quantitiesFromExternalService;
        } else if(response.getStatusCode() == 404) {
            throw new CalloutException ('404. You must create a sample application or add your own service which returns a valid response');
        } else {
            throw new CalloutException ('There was a problem with the request. Error: ' + response.getStatusCode());
        }
    }
    
    private static void saveCartValidationOutputError(String errorMessage, Id cartId) {
            // To propagate the error to the user, we need to add a new CartValidationOutput record.
            // The following fields must be populated:
            // CartId: Foreign key to the WebCart that this validation line is for
            // Level (required): One of the following - Info, Error, or Warning
            // Message (optional): Message displyed to the user
            // Name (required): The name of this CartValidationOutput record. For example CartId
            // RelatedEntityId (required): Foreign key to WebCart, CartItem, CartDeliveryGroup
            // Type (required): One of the following - SystemError, Inventory, Taxes, Pricing, Shipping, Entitlement, Other
            CartValidationOutput cartValidationError = new CartValidationOutput(
                CartId = cartId,
                Level = 'Error',
                Message = errorMessage.left(255),
                Name = (String)cartId,
                RelatedEntityId = cartId,
                Type = 'Inventory'
            );
            
            insert(cartValidationError);
    }
}