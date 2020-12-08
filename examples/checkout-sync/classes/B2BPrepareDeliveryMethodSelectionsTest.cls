@isTest
private class B2BPrepareDeliveryMethodSelectionsTest {
    
    @testSetup static void setup() {
        Account testAccount = new Account(Name='TestAccount');
        insert testAccount;
        WebStore testWebStore = new WebStore(Name='TestWebStore', DefaultLanguage='en_US');
        insert testWebStore;
        
        Account account = [SELECT Id FROM Account WHERE Name='TestAccount' LIMIT 1];
        WebStore webStore = [SELECT Id FROM WebStore WHERE Name='TestWebStore' LIMIT 1];
        WebCart cart = new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=account.Id);
        insert cart;
        
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery 1');
        insert cartDeliveryGroup;

        CartItem cartItem = new CartItem(CartId=cart.Id, Type='Product', Name='TestProduct', CartDeliveryGroupId=cartDeliveryGroup.Id);
        insert cartItem;

    }

    @isTest static void testIntegrationRunsSuccessfully() {
        // Because test methods don't support Web service callouts, we create a mock response based on a static resource.
        // To create the static resource from the Developer Console, select File | New | Static Resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetDeliveryRatesResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response.
        Test.setMock(HttpCalloutMock.class, mock);
        
        List<ID> cartIds = new List<ID>();
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        cartIds.add(webCart.Id);
        
        Test.startTest();

        // Test: execute the integration for the test cart ID.
        B2BPrepareDeliveryMethodSelections.prepDeliveryMethods(cartIds);
        List<CartDeliveryGroupMethod> methods = [SELECT ShippingFee FROM CartDeliveryGroupMethod WHERE WebCartId=:webCart.Id AND ShippingFee=15.99];
        System.assertEquals(1, methods.size());
        methods = [SELECT ShippingFee FROM CartDeliveryGroupMethod WHERE WebCartId=:webCart.Id AND ShippingFee=11.99];
        System.assertEquals(1, methods.size());

        Test.stopTest();
    }
    
/*
    @isTest static void testWhenExternalServiceCallFailsAFailedStatusIsReturnedAndACartValidationOutputEntryIsCreated() {
        // Because test methods do not support Web service callouts, we create a mock response based on a static resource.
        // To create the static resource from the the Developer Console, select File | New | Static Resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetDeliveryRatesResource');
        // The web service call returns an error code.
        mock.setStatusCode(404);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.startTest();
        // Associate the callout with a mock response.
        Test.setMock(HttpCalloutMock.class, mock);
        
        // Test: execute the integration for the test cart ID and integration info.
        B2BDeliverySample apexSample = new B2BDeliverySample();
        sfdc_checkout.IntegrationInfo integInfo = new sfdc_checkout.IntegrationInfo();
        integInfo.jobId = null;
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        sfdc_checkout.IntegrationStatus integrationResult = apexSample.startCartProcessAsync(integInfo, webCart.Id);
        
        // Validate: IntegrationStatus.Status is FAILED
        // and a new CartValidationOutput record with level 'Error' was created.
        System.assertEquals(sfdc_checkout.IntegrationStatus.Status.FAILED, integrationResult.status);
        List<CartValidationOutput> cartValidationOutputs = [SELECT Id FROM CartValidationOutput WHERE Level = 'Error'];
        System.assertEquals(1, cartValidationOutputs.size());
        Test.stopTest();
    }*/
}