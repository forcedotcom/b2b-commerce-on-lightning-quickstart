// This is a minimal test for this class that verifies some of the handling of B2BAuthorizeTokenizedPayment
// without completing the authorization
@isTest
public class B2BAuthorizeTokenizedPaymentTest {
    @testSetup static void setup() {
        // Account and Contact are related
        Account account = new Account(Name='TestAccount');
        insert account;
        Contact contact = new Contact(LastName='TestContact', AccountId=account.Id);
        insert contact;

        WebStore webStore = new WebStore(Name='TestWebStore', DefaultLanguage='en_US');
        insert webStore;

        CardPaymentMethod cardPaymentMethod = new CardPaymentMethod(AccountId=account.Id, ProcessingMode='External', Status='Active');
        insert cardPaymentMethod;

        WebCart cart = new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=account.Id, PaymentMethodId=cardPaymentMethod.Id);
        insert cart;

        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery');
        insert cartDeliveryGroup;
        
        insertCartItem(cart.Id, cartDeliveryGroup.Id);
        
        addStoreIntegratedService(webStore);
        
        
    }
    
    // Setup code that creates a non-functional store integrated service
    static void addStoreIntegratedService(WebStore webStore) {
        // Any named credential should do for the purposes of tests that don't 100% complete
        NamedCredential namedCredential = [SELECT Id FROM NamedCredential LIMIT 1];

        // This provider should be installed while running the SFDX installation that this test is associated with
        PaymentGatewayProvider paymentGatewayProvider = [SELECT Id FROM PaymentGatewayProvider WHERE DeveloperName='SalesforcePGP' LIMIT 1];
        
        PaymentGateway paymentGateway = new PaymentGateway(PaymentGatewayName='PGN', MerchantCredentialId=namedCredential.Id,
                                                           PaymentGatewayProviderId=paymentGatewayProvider.Id, Status='Active');
        insert paymentGateway;

        StoreIntegratedService newStoreIntegratedService = new StoreIntegratedService(Integration=paymentGateway.Id,
                                                                                      ServiceProviderType='Payment', StoreId=webStore.Id);
        insert newStoreIntegratedService;
    }

    // Starter test. Doesn't bother setting up an order, so errors are expected
    // To create more tests, consider setting up an order associated with a session and a cart to get past the failure
    // this test verifies.
    @isTest static void testNoOrderYetCreated() {
        // Get the data we'll need to use for running the test or for verification
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];

        Test.startTest();
        List<B2BAuthorizeTokenizedPayment.B2BAuthorizeTokenizedPaymentRequest> requests = new List<B2BAuthorizeTokenizedPayment.B2BAuthorizeTokenizedPaymentRequest>();
        B2BAuthorizeTokenizedPayment.B2BAuthorizeTokenizedPaymentRequest request = new B2BAuthorizeTokenizedPayment.B2BAuthorizeTokenizedPaymentRequest();
        request.cartId = webCart.Id;
        requests.add(request);

        List<String> errors = B2BAuthorizeTokenizedPayment.authorizePaymentInfo(requests);

        // No order was specified, so an error should be returned
        System.assertEquals(1, errors.size());
        System.assertEquals('No order is associated with this cart', errors[0]);
        
        Test.stopTest();
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
}
