// Determines the taxes for the cart
public class B2BSyncTax {
    // You MUST change this to be your service or you must launch your own Heroku Service
    // and add the host in Setup | Security | Remote site settings.
    private static String httpHost = 'https://example.com';
    private static Boolean useHTTPService = false;
    // This invocable method only expects one ID
    @InvocableMethod(callout=true label='Prepare the taxes' description='Runs a synchronous version of taxes' category='B2B Commerce')
    public static void syncTax(List<ID> cartIds) {
        // Validate the input
        if (cartIds == null || cartIds.size() != 1) {
            String errorMessage = 'A cart id must be included to B2BSyncTax'; // Get wording from doc!!!
            // Sync non-user errors skip saveCartValidationOutputError
            throw new CalloutException (errorMessage);
        }
        
        // Extract cart id and start processing
        Id cartId = cartIds[0];
        startCartProcessSync(cartId);
    }

    private static void startCartProcessSync(Id cartId) {
        // If there are any Products with null SKU throw exception.
        CartItem[] nullSKUs = [SELECT Id FROM CartItem WHERE CartId=:cartId AND Type='Product' AND Sku=null];
        if (!nullSKUs.isEmpty()) {
            String errorMessage = 'The SKUs for all products in your cart must be defined.';
            saveCartValidationOutputError(errorMessage, cartId);
            throw new CalloutException (errorMessage);
        }

        // In the Spring '20 release, there should be one delivery group per cart.
        // In the future, when multiple delivery groups can be created,
        // this sample should be updated to loop through all delivery groups.
        // We need to get the ID of the delivery group in order to get the DeliverTo info.
        Id cartDeliveryGroupId = [SELECT CartDeliveryGroupId FROM CartItem WHERE CartId = :cartId][0].CartDeliveryGroupId;
        CartDeliveryGroup deliveryGroup = [SELECT DeliverToState, DeliverToCountry FROM CartDeliveryGroup WHERE Id = :cartDeliveryGroupId][0];
        String taxType = [SELECT TaxType FROM WebCart WHERE Id = :cartId][0].TaxType;
        
        Map<ID, CartItem> cartItemsMap = new Map<ID, CartItem>([SELECT Id, Sku, Quantity, TotalLineAmount, AdjustmentAmount, (Select Id, TotalAmount from CartItemPriceAdjustments) FROM CartItem  WHERE CartId = :cartId]);

        // Following snippet of code fetches a mocked static json response from getDataFromStaticResponse.
        // Another example that demonstrates how to call a live 3rd party HTTP Service to fetch the desired 
        // response is implemented in getDataFromExternalService method.
        
        Map<String, Object> dataFromService = null;
        if(useHTTPService) {
            dataFromService = getDataFromExternalService(cartItemsMap, deliveryGroup.DeliverToState, deliveryGroup.DeliverToCountry, taxType);
        } else {
            dataFromService = getDataFromStaticResponse(cartItemsMap, deliveryGroup.DeliverToState, deliveryGroup.DeliverToCountry, taxType);
        }
        
        // If there are taxes from a previously cancelled checkout, delete them.
        delete [SELECT Id FROM CartTax WHERE CartItemId IN (Select Id FROM CartItem WHERE CartId = :cartId)];
        
        // For each cart item, insert a new tax line in the CartTax entity.
            // The total tax is automatically rolled up to TotalLineTaxAmount in the corresponding CartItem line.
            CartTax[] cartTaxestoInsert = new CartTax[]{};

            List<CartItem> cartItemsList = new List<CartItem>(cartItemsMap.values());

            for (CartItem cartItemToUpdate : cartItemsList) {
                // Update CartItem with taxes
                String cartItemId = cartItemToUpdate.id;
                Map<String, Object> cartItemsMapFromService = (Map<String, Object>) dataFromService.get(cartItemId);
                cartItemToUpdate.AdjustmentTaxAmount = (Decimal)cartItemsMapFromService.get('adjustmentTaxAmount');
                cartItemToUpdate.NetUnitPrice = (Decimal)cartItemsMapFromService.get('netUnitPrice');
                cartItemToUpdate.GrossUnitPrice = (Decimal)cartItemsMapFromService.get('grossUnitPrice');

                CartTax tax = new CartTax(
                    Amount = (Decimal)cartItemsMapFromService.get('taxAmount'),
                    CartItemId = cartItemId,
                    Name = (String)cartItemsMapFromService.get('taxName'),
                    TaxCalculationDate = Date.today(),
                    TaxRate = (Decimal)cartItemsMapFromService.get('taxRate'),
                    TaxType = 'Actual'
                );
                cartTaxestoInsert.add(tax);

                List<Object> itemTaxList = (List<Object>)cartItemsMapFromService.get('itemizedPromotionTaxAmounts');
                for (Object cipaTax : itemTaxList) {
                    CartTax promoTax = new CartTax(
                        Amount = (Decimal)((Map<String, Object>) cipaTax).get('taxAmount'),
                        CartItemId = cartItemId,
                        Name = (String)cartItemsMapFromService.get('taxName'),
                        TaxCalculationDate = Date.today(),
                        TaxRate = (Decimal)cartItemsMapFromService.get('taxRate'),
                        TaxType = 'Actual',
                        CartItemPriceAdjustmentId = (String)((Map<String, Object>) cipaTax).get('id')
                    );
                    cartTaxestoInsert.add(promoTax);
                }
            }

            update(cartItemsList);
            insert(cartTaxestoInsert);
    }

    private static Map<String, Object> getDataFromStaticResponse(Map<ID, CartItem> cartItemsMap, String state, String country, String taxType) {
        if (cartItemsMap == null) {
            return (Map<String, Object>) JSON.deserializeUntyped('{"error":"Input SKUs list is empty or undefined."}');
        }
        Double taxRate = 0.15;
        String responseJson = '{';
        for (ID key : cartItemsMap.keySet()) {
            CartItem cartItem = cartItemsMap.get(key);
            Id cartItemId = cartItem.Id;
            
            Double amount = cartItem.TotalLineAmount==null ? 0.00 : cartItem.TotalLineAmount;
            Double tierAdjustment = cartItem.AdjustmentAmount==null ? 0.00 : cartItem.AdjustmentAmount;
            Double quantity = cartItem.Quantity==null ? 0.00 : cartItem.Quantity;
            
            if(country == null || country == 'US' || country == 'United States') {
                taxRate = 0.08;
                String [] noSalesTaxUSStates = new String [] {'AK', 'DE', 'MT', 'NH', 'OR'};
                if (noSalesTaxUSStates.contains(state)) {
                    taxRate = 0.00;
                }
            }
            
            Double itemizedPromotionTax = 0.00;
            Double [] itemizedPromotionTaxArr = new Double [] {};
            Double netUnitPrice = 0.00;
            Double grossUnitPrice = 0.00;
            
            Double multiplier = 0.00;
        
            if(taxType == 'Gross') {
                multiplier = taxRate / (1 + taxRate);
            } else {
                multiplier = taxRate;
            }
            
            Double cartItemTax = amount * multiplier;
            Double tierAdjustmentTax = (tierAdjustment!=null ? tierAdjustment : 0.00) * multiplier;
            
            CartItemPriceAdjustment [] itemizedPromotions = cartItem.CartItemPriceAdjustments;
            
            String itemizedPromotionTaxResp = '[';
            for(CartItemPriceAdjustment itemAdj : itemizedPromotions) {
                Double itemTaxAmount = (itemAdj.TotalAmount!=null ? itemAdj.TotalAmount : 0.00) * multiplier;
                itemizedPromotionTaxResp = itemizedPromotionTaxResp + '{';
                itemizedPromotionTaxResp = itemizedPromotionTaxResp + '"id": "' + itemAdj.Id + '",';
                itemizedPromotionTaxResp = itemizedPromotionTaxResp + '"taxAmount": ' + itemTaxAmount;
                itemizedPromotionTaxResp = itemizedPromotionTaxResp + '},';
                itemizedPromotionTax = itemizedPromotionTax + itemTaxAmount;
            }
            itemizedPromotionTaxResp = itemizedPromotionTaxResp.removeEnd(',') + ']';
            
            if(taxType == 'Gross') {
                grossUnitPrice = amount / quantity;
                netUnitPrice = (amount - cartItemTax) / quantity;
            } else {
                grossUnitPrice = (amount + cartItemTax) / quantity;
                netUnitPrice = amount / quantity;
            }
            
            responseJson = responseJson + '"'+cartItemId+'":';
            responseJson = responseJson + '{';
            responseJson = responseJson + '"cartItemId": "' + cartItemId + '",';
            responseJson = responseJson + '"taxAmount": ' + cartItemTax + ',';
            responseJson = responseJson + '"adjustmentTaxAmount": ' + tierAdjustmentTax + ',';
            
            responseJson = responseJson + '"itemizedPromotionTaxAmounts": ';
            responseJson = responseJson + itemizedPromotionTaxResp;
            responseJson = responseJson + ',';
            
            responseJson = responseJson + '"totalItemizedPromotionTaxAmount": ' + itemizedPromotionTax + ',';
            responseJson = responseJson + '"grossUnitPrice": ' + grossUnitPrice + ',';
            responseJson = responseJson + '"netUnitPrice": ' + netUnitPrice + ',';
            responseJson = responseJson + '"taxRate": ' + taxRate + ',';
            responseJson = responseJson + '"taxName": "GST"';
            responseJson = responseJson + '},';
        }
        
        responseJson = responseJson.removeEnd(',') + '}';        
        return (Map<String, Object>) JSON.deserializeUntyped(responseJson);
    }
    
    private static Map<String, Object> getDataFromExternalService (
        Map<ID, CartItem> cartItemsMap, String state, String country, String taxType) {

        String requestURL = httpHost + '/get-tax-rates-with-adjustments-post';
        String requestBody = '{"state":"'+state+'", "country":"'+country+'", "taxType":"'+taxType+'", '+'"amountsBySKU":'+JSON.serialize(cartItemsMap)+'}';
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(requestURL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(requestBody);
        HttpResponse response = http.send(request);

        // If the request is successful, parse the JSON response
        if (response.getStatusCode() == 200) {
            Map<String, Object> resultsFromExternalService = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return resultsFromExternalService;
        } else if(response.getStatusCode() == 404) {
            throw new CalloutException ('404. You must create a sample application or add your own service which returns a valid response');
        } else {
            throw new CalloutException ('There was a problem with the request. Error: ' + response.getStatusCode());
        }
    }

    private static void saveCartValidationOutputError(String errorMessage, Id cartId) {
        // For the error to be propagated to the user, we need to add a new CartValidationOutput record.
        // The following fields must be populated:
        // BackgroundOperationId: Foreign Key to the BackgroundOperation
        // CartId: Foreign key to the WebCart that this validation line is for
        // Level (required): One of the following - Info, Error, or Warning
        // Message (optional): Message displayed to the user (maximum 255 characters)
        // Name (required): The name of this CartValidationOutput record. For example CartId
        // RelatedEntityId (required): Foreign key to WebCart, CartItem, CartDeliveryGroup
        // Type (required): One of the following - SystemError, Inventory, Taxes, Pricing, Shipping, Entitlement, Other
        CartValidationOutput cartValidationError = new CartValidationOutput(
            CartId = cartId,
            Level = 'Error',
            Message = errorMessage.left(255),
            Name = (String)cartId,
            RelatedEntityId = cartId,
            Type = 'Taxes'
        );
        insert(cartValidationError);
    }
}