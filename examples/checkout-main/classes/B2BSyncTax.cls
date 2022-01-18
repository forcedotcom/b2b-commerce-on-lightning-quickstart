// Determines the taxes for the cart
public class B2BSyncTax {
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
        // In the Spring '20 release, there should be one delivery group per cart.
        // In the future, when multiple delivery groups can be created,
        // this sample should be updated to loop through all delivery groups.

        // We need to get the ID of the delivery group in order to get the DeliverTo info.
        Id cartDeliveryGroupId = [SELECT CartDeliveryGroupId FROM CartItem WHERE CartId = :cartId WITH SECURITY_ENFORCED][0].CartDeliveryGroupId;
        CartDeliveryGroup deliveryGroup = [SELECT DeliverToState, DeliverToCountry FROM CartDeliveryGroup WHERE Id = :cartDeliveryGroupId WITH SECURITY_ENFORCED][0];
        
        // Get all SKUs, the cart item IDs, and the total prices from the cart items.
        Map<String, Id> cartItemIdsBySKU = new Map<String, Id>();
        Map<String, Decimal> cartItemTotalPriceBySKU = new Map<String, Decimal>();
        for (CartItem cartItem : [SELECT Sku, TotalPrice, Type FROM CartItem WHERE CartId = :cartId WITH SECURITY_ENFORCED]) {
            String cartItemSKU = '';
            if (cartItem.Type == 'Product') {
                if (String.isBlank(cartItem.Sku)) {
                    String errorMessage = 'The SKUs for all products in your cart must be defined.';
                    saveCartValidationOutputError(errorMessage, cartId);
                    throw new CalloutException (errorMessage);
                }
                cartItemSKU = cartItem.Sku;
            }
            else if (cartItem.Type == 'Charge') {
                // This is an example for a Cart Item of type shipping charge.
                // For simplicity and testing purposes, we just assign some SKU to this charge so that the taxation external service returns some value.
                cartItemSKU = 'ChargeSKU';
            }
            cartItemIdsBySKU.put(cartItemSKU, cartItem.Id);
            cartItemTotalPriceBySKU.put(cartItemSKU, cartItem.TotalPrice);
        }      
        
        // Get the tax rates and tax amounts from an external service
        // Other parameters will be passed here, like ship_from, bill_to, more details about the ship_to, etc.
        Map<String, TaxDataFromExternalService> rateAndAmountFromExternalServicePerSku = getTaxRatesAndAmountsFromExternalService(
            cartId, cartItemTotalPriceBySKU, deliveryGroup.DeliverToState, deliveryGroup.DeliverToCountry
        );
        
        // If there are taxes from a previously cancelled checkout, delete them.
        List<Id> cartItemIds = cartItemIdsBySKU.values();
        delete [SELECT Id FROM CartTax WHERE CartItemId IN :cartItemIds WITH SECURITY_ENFORCED];
        
        // For each cart item, insert a new tax line in the CartTax entity.
        // The total tax is automatically rolled up to TotalLineTaxAmount in the corresponding CartItem line.
        CartTax[] cartTaxestoInsert = new CartTax[]{};
        for (String sku : cartItemIdsBySKU.keySet()) {
            TaxDataFromExternalService rateAndAmountFromExternalService = rateAndAmountFromExternalServicePerSku.get(sku);
            if (rateAndAmountFromExternalService == null) {
                String errorMessage = 'The product with sku ' + sku + ' could not be found in the external system';
                saveCartValidationOutputError(errorMessage, cartId);
                throw new CalloutException (errorMessage);
            }
            // If the sku was found in the external system, add a new CartTax line for that sku
            // The following fields from CartTax can be filled in:
            // Amount (required): Calculated tax amount.
            // CartItemId (required): ID of the cart item.
            // Description (optional): Description of CartTax.
            // Name (required): Name of the tax.
            // TaxCalculationDate (required): Calculation date for this tax line.
            // TaxRate (optional): The percentage value of the tax. Null if the tax is a flat amount.
            // TaxType (required): The type of tax, e.g. Actual or Estimated.
            CartTax tax = new CartTax( 
                Amount = rateAndAmountFromExternalService.getAmount(),
                CartItemId = cartItemIdsBySKU.get(sku),
                Name = rateAndAmountFromExternalService.getTaxName(),
                TaxCalculationDate = Date.today(),
                TaxRate = rateAndAmountFromExternalService.getRate(),
                TaxType = 'Actual'
            );
            cartTaxestoInsert.add(tax);
        }
        insert(cartTaxestoInsert);
    }
    
    private static Map<String, TaxDataFromExternalService> getTaxRatesAndAmountsFromExternalService (
        String cartId, Map<String, Decimal> cartItemTotalAmountBySKU, String state, String country) {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            Integer SuccessfulHttpRequest = 200;
            String encodedState = (state == null) ? '' : EncodingUtil.urlEncode(state, 'UTF-8').replace('+', '%20');
            String encodedCountry = (country == null) ? '' : EncodingUtil.urlEncode(country, 'UTF-8').replace('+', '%20');
            
            Map<String, Decimal> encodedCartItemTotalAmountBySKU = new Map<String, Decimal>();
            for(String sku: cartItemTotalAmountBySKU.keySet()) {
                encodedCartItemTotalAmountBySKU.put(EncodingUtil.urlEncode(sku, 'UTF-8'), cartItemTotalAmountBySKU.get(sku));
            }
            
            // To access the service below, you may need to add endpoint = https://b2b-commerce-test.herokuapp.com in Setup | Security | Remote site settings.
            String requestURL = 'https://b2b-commerce-test.herokuapp.com/get-tax-rates?state=' + encodedState
                            + '&country=' + encodedCountry
                            + '&amountsBySKU=' + JSON.serialize(encodedCartItemTotalAmountBySKU);
            request.setEndpoint(requestURL);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
        
            // If the request is successful, parse the JSON response;
            // The response includes the tax amount, rate, and name for each SKU. It looks something like this:
            // {"SKU_1_september10-1568355297":{"taxAmount":2.8229012971048855,"taxRate":0.08,"taxName":"GST"},"SKU_0_september10-1568355296":{"taxAmount":5.0479003481482385,"taxRate":0.08,"taxName":"GST"}}
            if (response.getStatusCode() == SuccessfulHttpRequest) {
                Map<String, Object> resultsFromExternalServiceBySKU = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                Map<String, TaxDataFromExternalService> taxDataFromExternalServiceBySKU = new Map<String, TaxDataFromExternalService>();
                for (String sku : resultsFromExternalServiceBySKU.keySet()) {
                    Map<String, Object> rateAndAmountFromExternalService = (Map<String, Object>) resultsFromExternalServiceBySKU.get(sku);
                    taxDataFromExternalServiceBySKU.put(sku, new TaxDataFromExternalService(
                        (Decimal)rateAndAmountFromExternalService.get('taxRate'),
                        (Decimal)rateAndAmountFromExternalService.get('taxAmount'),
                        (String)rateAndAmountFromExternalService.get('taxName')
                    ));
                }
                return taxDataFromExternalServiceBySKU;
            }
            else {
                String errorMessage = 'There was a problem with the request. Error: ' + response.getStatusCode();
                // Sync non-user errors skip saveCartValidationOutputError
                throw new CalloutException (errorMessage);
            }
    }
    
    // Structure to store the tax data retrieved from external service
    // This simplifies our ability to access it when storing it in Salesforce's CartTax entity
    Class TaxDataFromExternalService {
        private Decimal rate;
        private Decimal amount;
        private String taxName;
        
        public TaxDataFromExternalService () {
            rate = 0.0;
            amount = 0.0;
            taxName = '';
        }
        
        public TaxDataFromExternalService (Decimal someRate, Decimal someAmount, String someTaxName) {
            rate = someRate;
            amount = someAmount;
            taxName = someTaxName;
        }
        
        public Decimal getRate() {
            return rate;
        }
        
        public Decimal getAmount() {
            return amount;
        }
        
        public String getTaxName() {
            return taxName;
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