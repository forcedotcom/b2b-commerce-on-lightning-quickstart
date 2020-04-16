// This must implement the sfdc_checkout.CartShippingCharges interface
// in order to be processed by the checkout flow for the "Shipping" integration
global class B2BShippingSample implements sfdc_checkout.CartShippingCharges {
    global sfdc_checkout.IntegrationStatus startCartProcessAsync(sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
        sfdc_checkout.IntegrationStatus integStatus = new sfdc_checkout.IntegrationStatus();
        try {
            // In the Summer '20 release there should be one delivery group per cart.
            // We need to get the ID of that delivery group in order to use it for the shipping charge.
            Id cartDeliveryGroupId = [SELECT CartDeliveryGroupId FROM CartItem WHERE CartId = :cartId][0].CartDeliveryGroupId;
            
            // Get the shipping options from an external service.
            // Here we pass in parameters like ship_from, ship_to, details about the parcels, etc.
            ShippingOptionsAndRatesFromExternalService[] shippingOptionsAndRatesFromExternalService = getShippingOptionsAndRatesFromExternalService();
            
            // Delete all previous CartDeliveryGroupMehods for the given cartDeliveryGroupId
            delete [SELECT Id FROM CartDeliveryGroupMethod WHERE CartDeliveryGroupId = :cartDeliveryGroupId];

            Id defaultOrderDeliveryMethodId = getDefaultOrderDeliveryMethod();
            // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service
            populateCartDeliveryGroupMehodWithShippingOptions(shippingOptionsAndRatesFromExternalService,
                                                              cartDeliveryGroupId,
                                                              defaultOrderDeliveryMethodId,
                                                              cartId);
            
            // The following part is shown here as an exmple.
            // In production, it has to be moved to the shippment subflow, that will:
            // 1) Query all CartDeliveryGroupMethod to display all possible shipping options
            // 2) Capture selected CartDeliveryGroupMethod and pass to another Apex class that writes it back.
            // That Apex class has to be declared as an InvocableMethod and called from the subflow.
            // In our example we consider the first CartDeliveryGroupMethod to be the selected one.
            CartDeliveryGroupMethod selectedCartDeliveryGroupMethod = [SELECT ShippingFee, DeliveryMethodId FROM CartDeliveryGroupMethod WHERE CartDeliveryGroupId = :cartDeliveryGroupId][0];
            // We get the shipping fee and delivery method from the selected CartDeliveryGroupMethod.
            Decimal shippingRate = selectedCartDeliveryGroupMethod.ShippingFee;
            Id orderDeliveryMethodId = selectedCartDeliveryGroupMethod.DeliveryMethodId;
            
            // If there are shipping charges from a previously cancelled checkout, delete them.
            delete [SELECT Id FROM CartItem WHERE Type = 'Charge' and CartId = :cartId];
            
            // A shipping charge has to be associated with a Product2 record.
            Id shippingChargeProduct2Id = getShippingChargeProduct2Id(orderDeliveryMethodId);
            
            // To add shipping charges to the cart, we insert a new cart item and populate the following fields:
            // Type (optional but we want to set it to show this is a charge): 'Charge'.
            // Product2Id: The ID of a 'product' that is actually a shipping charge.
            // Quantity (optional): 1.0.
            // TotalPrice (optional): Total amount for this charge type cart item, including adjustments but excluding taxes.
            // ListPrice (required): List price of this cart item.
            // TotalListPrice (optional): Total amount for this cart item based on ListPrice, provided mostly for comparison.
            // TotalLineAmount (optional): Total amount for this cart item, based on sales price and quantity.
            // TotalAdjustmentAmount (optional): Total adjustments for this cart item.
            // CartId (required): The ID of the cart that this shipping charge belongs to.
            // CartDeliveryGroupId (required): Delivery group for this shipping charge.
            // Name (required): 'Shipping Cost' (can be any value).
            // 
            CartItem deliveryCharge = new CartItem(
                Type = 'Charge',
                Product2Id = shippingChargeProduct2Id,
                Quantity = 1.0,
                TotalPrice = shippingRate,
                ListPrice = shippingRate,
                TotalListPrice = shippingRate,
                TotalLineAmount = shippingRate,
                AdjustmentAmount = 0.0,
                CartId = cartId,
                CartDeliveryGroupId = cartDeliveryGroupId,
                Name = 'Shipping Cost'
            );
            insert(deliveryCharge);
          
            // A delivery method has to be associated to the cart delivery group.
            addOrderDeliveryMethodToCartDeliveryGroup(orderDeliveryMethodId, cartDeliveryGroupId);
            
            // If everything works well, the charge is added to the cart and our integration has been successfully completed.
            integStatus.status = sfdc_checkout.IntegrationStatus.Status.SUCCESS;

        // For testing purposes, this example treats exceptions as user errors, which means they are displayed to the buyer user.
        // In production you probably want this to be an admin-type error. In that case, throw the exception here
        // and make sure that a notification system is in place to let the admin know that the error occurred.
        // See the readme section about error handling for details about how to create that notification.
        } catch (DmlException de) {
            // Catch any exceptions thrown when trying to insert the shipping charge to the CartItems
            Integer numErrors = de.getNumDml();
            String errorMessage = 'There were ' + numErrors + ' errors when trying to insert the charge in the CartItem: ';
            for(Integer errorIdx = 0; errorIdx < numErrors; errorIdx++) {
                errorMessage += 'Field Names = ' + de.getDmlFieldNames(errorIdx);
                errorMessage += 'Message = ' + de.getDmlMessage(errorIdx);
                errorMessage += ' , ';
            }
            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                errorMessage,
                jobInfo,
                cartId
            );
        } catch(Exception e) {
            return integrationStatusFailedWithCartValidationOutputError(
                integStatus,
                'An exception of type ' + e.getTypeName() + ' has occurred: ' + e.getMessage(),
                jobInfo,
                cartId
            );
        }
        return integStatus;
    }
    
    private ShippingOptionsAndRatesFromExternalService[] getShippingOptionsAndRatesFromExternalService () {
        ShippingOptionsAndRatesFromExternalService[] shippingOptions = new List<ShippingOptionsAndRatesFromExternalService>();
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        Integer SuccessfulHttpRequest = 200;
        // To access the service below, you may need to add endpoint = https://b2b-commerce-test.herokuapp.com in Setup | Security | Remote site settings.
        request.setEndpoint('https://b2b-commerce-test.herokuapp.com/calculate-shipping-rates');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        // If the request is successful, parse the JSON response.
        // The response looks like this:
        // {"status":"calculated","rate":{"serviceName":"Canada Post","serviceCode":"SNC9600","shipmentCost":11.99,"otherCost":5.99}}
        if (response.getStatusCode() == SuccessfulHttpRequest) {
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> rate = (Map<String, Object>) results.get('rate');
            ShippingOptionsAndRatesFromExternalService shippingOption1 = new ShippingOptionsAndRatesFromExternalService((String) rate.get('serviceCode'), (Decimal) rate.get('shipmentCost'));
            shippingOptions.add(shippingOption1);
            return shippingOptions;
        }
        else {
            throw new CalloutException ('There was a problem with the request. Error: ' + response.getStatusCode());
        }
    }
    
    // Structure to store the shipping options retrieved from external service.
    Class ShippingOptionsAndRatesFromExternalService {
        private String provider;
        private Decimal rate;
        
        public ShippingOptionsAndRatesFromExternalService() {
            provider = '';
            rate = 0.0;
        }
        
        public ShippingOptionsAndRatesFromExternalService(String someProvider, Decimal someRate) {
            provider = someProvider;
            rate = someRate;
        }
        
        public String getProvider() {
            return provider;
        }
        
        public Decimal getRate() {
            return rate;
        }
    }
    
    // Create a CartDeliveryGroupMethod record for every shipping option returned from the external service
    private void populateCartDeliveryGroupMehodWithShippingOptions(ShippingOptionsAndRatesFromExternalService[] shippingOptionsAndRatesFromExternalService,
                                                                  Id cartDeliveryGroupId,
                                                                  Id deliveryMethodId,
                                                                  Id webCartId){
        for (ShippingOptionsAndRatesFromExternalService option : shippingOptionsAndRatesFromExternalService) {
            // When inserting a new CartDeliveryGroupMethod, the following fields have to be populated:
            // CartDeliveryGroupId: Id of the delivery group of this shipping option
            // DeliveryMethodId: Id of the delivery method for this shipping option (We are setting all the responses to one OrderDeliveryMethod, just for testing purposes.
            // In production implementation you need to query OrderDeliveryMethods based on service response)
            // ExternalProvider: Unique identifier of shipping provider
            // Name: Name of the CartDeliveryGroupMethod record
            // ShippingFee: The cost of shipping for the delivery group
            // WebCartId: Id if the cart that the delivery group belongs to
            CartDeliveryGroupMethod cartDeliveryGroupMethod = new CartDeliveryGroupMethod(
                CartDeliveryGroupId = cartDeliveryGroupId,
                DeliveryMethodId = deliveryMethodId,
                ExternalProvider = option.getProvider(),
                Name = 'Test Delivery Group Method',
                ShippingFee = option.getRate(),
                WebCartId = webCartId
            );
            insert(cartDeliveryGroupMethod);
        }
    }
    
    private sfdc_checkout.IntegrationStatus integrationStatusFailedWithCartValidationOutputError(
        sfdc_checkout.IntegrationStatus integrationStatus, String errorMessage, sfdc_checkout.IntegrationInfo jobInfo, Id cartId) {
            integrationStatus.status = sfdc_checkout.IntegrationStatus.Status.FAILED;
            // In order for the error to be propagated to the user, we need to add a new CartValidationOutput record.
            // The following fields must be populated:
            // BackgroundOperationId: Foreign Key to the BackgroundOperation
            // CartId: Foreign key to the WebCart that this validation line is for
            // Level (required): One of the following - Info, Error, or Warning
            // Message (optional): Message displayed to the user
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
                Type = 'Shipping'
            );
            insert(cartValidationError);
            return integrationStatus;
    }
    
    private Id getShippingChargeProduct2Id(Id orderDeliveryMethodId) {
        // The Order Delivery Method should have a Product2 associated with it, because we added that in getDefaultOrderDeliveryMethod if it didn't exist.
        List<OrderDeliveryMethod> orderDeliveryMethods = [SELECT ProductId FROM OrderDeliveryMethod WHERE Id = :orderDeliveryMethodId];
        return orderDeliveryMethods[0].ProductId;
    }
    
    private Id getDefaultOrderDeliveryMethod() {
        String defaultDeliveryMethodName = 'Default Delivery Method';
        Id defaultDeliveryMethodId = null;
        Id product2IdForThisDeliveryMethod = getDefaultShippingChargeProduct2Id();

        // Check to see if a default OrderDeliveryMethod already exists.
        // If it doesn't exist, create one.
        List<OrderDeliveryMethod> defaultOrderDeliveryMethods = [SELECT Id, ProductId FROM OrderDeliveryMethod WHERE Name = :defaultDeliveryMethodName];
        if (defaultOrderDeliveryMethods.isEmpty()) {
            OrderDeliveryMethod defaultOrderDeliveryMethod = new OrderDeliveryMethod(
                Name = defaultDeliveryMethodName,
                isActive = true,
                ProductId = product2IdForThisDeliveryMethod
            );
            insert(defaultOrderDeliveryMethod);
            defaultDeliveryMethodId = defaultOrderDeliveryMethod.Id;
        }
        else {
            // If the OrderDeliveryMethod doesn't have a Product2 associated with it, assign one
            OrderDeliveryMethod defaultOrderDeliveryMethod = defaultOrderDeliveryMethods[0];
            if (defaultOrderDeliveryMethod.ProductId == null) {
                defaultOrderDeliveryMethod.ProductId = product2IdForThisDeliveryMethod;
                update(defaultOrderDeliveryMethod);
                defaultDeliveryMethodId = defaultOrderDeliveryMethod.Id;
            }
            else {
                defaultDeliveryMethodId = defaultOrderDeliveryMethod.Id;
            }
        }
        
        return defaultDeliveryMethodId;
    }
    
    private Id getDefaultShippingChargeProduct2Id() {
        // In this example we will name the product representing shipping charges 'Shipping Charge for this delivery method'.
        // Check to see if a Product2 with that name already exists.
        // If it doesn't exist, create one.
        String shippingChargeProduct2Name = 'Shipping Charge for this delivery method';
        List<Product2> shippingChargeProducts = [SELECT Id FROM Product2 WHERE Name = :shippingChargeProduct2Name];
        if (shippingChargeProducts.isEmpty()) {
            Product2 shippingChargeProduct = new Product2(
                isActive = true,
                Name = shippingChargeProduct2Name
            );
            insert(shippingChargeProduct);
            return shippingChargeProduct.Id;
        }
        else {
            return shippingChargeProducts[0].Id;
        }
    }
    
    private void addOrderDeliveryMethodToCartDeliveryGroup(Id someOrderDeliveryMethodId, Id someCartDeliveryGroupId) {       
        // The OrderDeliveryMethod is added to the CartDeliveryGroup for the order to be properly created during checkout.
        CartDeliveryGroup cartDeliveryGroup = [SELECT Id, DeliveryMethodId FROM CartDeliveryGroup WHERE Id= :someCartDeliveryGroupId][0];
        cartDeliveryGroup.DeliveryMethodId = someOrderDeliveryMethodId;
        update cartDeliveryGroup;
    }
}