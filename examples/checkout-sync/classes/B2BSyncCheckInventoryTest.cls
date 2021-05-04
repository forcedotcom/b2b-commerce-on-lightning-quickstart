@isTest
public class B2BSyncCheckInventoryTest {
    @testSetup static void setup() {
        Account account = new Account(Name='TestAccount');
        insert account;
        WebStore webStore = new WebStore(Name='TestWebStore', DefaultLanguage='en_US');
        insert webStore;
        WebCart cart = new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=account.Id);
        insert cart;
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery');
        insert cartDeliveryGroup;
        
        insertCartItem(cart.Id, cartDeliveryGroup.Id);
    }
    
    @isTest static void testWhenExternalServiceQuantityIsLargerThanTheCartItemQuantityASuccessStatusIsReturned() {
        // Because test methods do not support Web service callouts, we create a mock response based on a static resource.
        // To create the static resource from the Developer Console, select File | New | Static Resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetInventoryResource');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.startTest();
        // Associate the callout with a mock response.
        Test.setMock(HttpCalloutMock.class, mock);
        
        // Test: execute the integration for the test cart ID.
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        List<Id> webCarts = new List<Id>{webCart.Id};
        B2BSyncCheckInventory.syncCheckInventory(webCarts);
        
        // No status is returned from the syncCheckInventory check, but if no exception is thrown, the test passes
        
        Test.stopTest();
    }
    
    @isTest static void testWhenExternalServiceCallFailsAFailedStatusIsReturnedAndACartValidationOutputEntryIsCreated() {
        // Because test methods do not support Web service callouts, we create a mock response based on a static resource.
        // To create the static resource from the Developer Console, select File | New | Static Resource
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('GetInventoryResource');
        // The web service call returns an error code.
        mock.setStatusCode(404);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        Test.startTest();
        // Associate the callout with a mock response.
        Test.setMock(HttpCalloutMock.class, mock);
        
        // Test: execute the integration for the test cart ID.
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        List<Id> webCarts = new List<Id>{webCart.Id};

        String expectedErrorMessage = 'There was a problem with the request. Error: 404';
        executeAndEnsureFailure(expectedErrorMessage, webCarts);

        Test.stopTest();
    }
    
    // This test ensures that when the cart is empty that check inventory returns an error
    @isTest static void testEmptyCartHasError() {
        // Empty the cart before the test
        deleteCartItem();
        Test.startTest();
        System.assertEquals(0, [SELECT Id, Message FROM CartValidationOutput WHERE Level = 'Error'].size());

        // Test: Execute the integration for the test cart ID.
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        List<Id> webCarts = new List<Id>{webCart.Id};

        String expectedErrorMessage = 'Looks like your cart is empty.';
        executeAndEnsureFailure(expectedErrorMessage, webCarts);

        Test.stopTest();

        // Undo the emptying of the cart we did at the start of the test
        insertCartItem(webCart.Id);
    }

    @isTest static void testProductsWithNoSkuHasError() {
        Test.startTest();

        WebCart webCart = [SELECT Id FROM WebCart WHERE Name = 'Cart' LIMIT 1];
        List<CartDeliveryGroup> cartDeliveryGroups = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :webCart.Id LIMIT 1];
        List<Id> webCarts = new List<Id>{webCart.Id};

        // Insert a cart item without a SKU
        CartItem cartItemWithNoSku = new CartItem(
            CartId=webCart.Id,
            Quantity=1.0,
            Type='Product',
            Name='TestProductNoSku',
            CartDeliveryGroupId=cartDeliveryGroups.get(0).Id
        );
        insert cartItemWithNoSku;

        String expectedErrorMessage = 'The SKUs for all products in your cart must be defined.';
        executeAndEnsureFailure(expectedErrorMessage, webCarts);

        Test.stopTest();

        // Remove the invalid cart item
        delete cartItemWithNoSku;
    }
    
    // Executes the check inventory check and ensures an error is correctly triggered
    static void executeAndEnsureFailure(String expectedErrorMessage, List<Id> webCarts) {
        try {
            B2BSyncCheckInventory.syncCheckInventory(webCarts);
            
            // An exception should have been thrown before getting to this point:
            System.assert(false);
        } catch (CalloutException e) {
            System.assertEquals(expectedErrorMessage, e.getMessage());
        }
        
        // A new CartValidationOutput record with level 'Error' was created.
        List<CartValidationOutput> cartValidationOutputs = [SELECT Id, Message FROM CartValidationOutput WHERE Level = 'Error'];
        System.assertEquals(1, cartValidationOutputs.size());
        System.assertEquals(expectedErrorMessage, cartValidationOutputs.get(0).Message);
    }
    
    // Inserts a cart item when we only know the cart id
    static void insertCartItem(String cartId) {
        List<CartDeliveryGroup> cartDeliveryGroups = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cartId LIMIT 1];

        insertCartItem(cartId, cartDeliveryGroups.get(0).Id);
    }
    
    // Inserts a cart item that matches the cart and cart delivery group
    static void insertCartItem(String cartId, String cartDeliveryGroupId) {
        CartItem cartItem = new CartItem(
            CartId=cartId, 
            Sku='SKU_Test1', 
            Quantity=3.0, 
            Type='Product', 
            Name='TestProduct', 
            CartDeliveryGroupId=cartDeliveryGroupId
        );
        insert cartItem;
    }

    // Deletes the single cart item    
    static void deleteCartItem() {
        CartItem cartItem = [SELECT Id FROM CartItem WHERE Name = 'TestProduct' LIMIT 1];
        delete cartItem;
    }
}
