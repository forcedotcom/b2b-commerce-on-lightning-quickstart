@isTest
public class B2BPaymentControllerTest {
    @testSetup static void setup() {
        // Account and Contact are related
        Account account = new Account(Name='TestAccount');
        insert account;
        Contact contact = new Contact(LastName='TestContact', AccountId=account.Id);
        insert contact;

        WebStore webStore = new WebStore(Name='TestWebStore', DefaultLanguage='en_US');
        insert webStore;

        WebCart cart = new WebCart(Name='Cart', WebStoreId=webStore.Id, AccountId=account.Id);
        insert cart;

        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery');
        insert cartDeliveryGroup;

        // The cpas are related to the account (and through it to the contact)
        ContactPointAddress cpa1 = new ContactPointAddress(Name='CPA1', Street='Street1', City='city1', State='state1',
                Country='country1', PostalCode='12345', IsDefault=true, AddressType='Billing', ParentId=account.Id);
        ContactPointAddress cpa2 = new ContactPointAddress(Name='CPA2', Street='Street2', City='city2', State='state2',
                Country='country2', PostalCode='12345', IsDefault=false, AddressType='Billing', ParentId=account.Id);

        // This contact point address should not show up because it's set to AddressType Shipping
        ContactPointAddress cpaShipping = new ContactPointAddress(Name='CPAS', Street='StreetS', City='cityS',
                Country='countryS', PostalCode='12345', IsDefault=false, AddressType='Shipping', ParentId=account.Id);

        insert cpa1;
        insert cpa2;
        insert cpaShipping;
        
        // This profile name is the name of the buyer profile. The name specified here is what is installed using
        // SFDX and may be different for you.
        Profile profile = [SELECT Id FROM Profile WHERE Name='Buyer_User_Profile_From_QuickStart' LIMIT 1];
        User user = new User(Alias='buyer', Email='buyer@example.com', LastName='Buyer',
                TimeZoneSidKey='GMT', LocaleSidKey='en_US', Username='buyer@example.com',
                EmailEncodingKey='UTF-8', ProfileId=profile.Id, LanguageLocaleKey='en_US',
                ContactId=contact.Id);
        insert user;
        
        insertCartItem(cart.Id, cartDeliveryGroup.Id);
    }

    // This basic test has no selected address and just returns the two contact point addresses, neither of which are selected.
    // This emulates when a user first enters the payment screen without a pre-selected address
    @isTest static void testNoSelectedAddress() {
        // Get the data we'll need to use for running the test or for verification
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        User buyer = [SELECT Id FROM User WHERE Username='buyer@example.com'];
        ContactPointAddress cpa1 = [SELECT Id, Name, Street, City, State, Country, PostalCode, IsDefault, ParentId
                                    FROM ContactPointAddress WHERE Name='CPA1'];
        ContactPointAddress cpa2 = [SELECT Id, Name, Street, City, State, Country, PostalCode, IsDefault, ParentId
                                    FROM ContactPointAddress WHERE Name='CPA2'];

        Test.startTest();
        
        // Get the payment info as a buyer so that the buyer's account is used in the method call
        Map<String, Object> paymentInfo;
        System.runAs(buyer) {
            paymentInfo = B2BPaymentController.getPaymentInfo(WebCart.Id);
        }

        // No purchase order was specified
        System.assertEquals(null, paymentInfo.get('purchaseOrderNumber'));

        // Verify the addresses returned were correct
        List<Map<String, Object>> addresses = (List<Map<String, Object>>) paymentInfo.get('addresses');
        System.assertEquals(2, addresses.size());
        
        Map<String, Object> address1 = addresses.get(0);
        Map<String, Object> address2 = addresses.get(1);
        
        testAddressMatches(address1, cpa1.Id, cpa1.Name, cpa1.Street, cpa1.City, cpa1.State, cpa1.Country, cpa1.PostalCode, cpa1.IsDefault, false);
        testAddressMatches(address2, cpa2.Id, cpa2.Name, cpa2.Street, cpa2.City, cpa2.State, cpa2.Country, cpa2.PostalCode, cpa2.IsDefault, false);
        
        Test.stopTest();
    }
    
    // Here, the user has previously selected an address and so we should show that address as having been selected
    @isTest static void testSelectedAddressMatchesAnAddress() {
        // Get the data we'll need to use for running the test or for verification
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        User buyer = [SELECT Id FROM User WHERE Username='buyer@example.com'];
        ContactPointAddress cpa1 = [SELECT Id, Name, Street, City, State, Country, PostalCode, IsDefault, ParentId, Address
                                    FROM ContactPointAddress WHERE Name='CPA1'];
        ContactPointAddress cpa2 = [SELECT Id, Name, Street, City, State, Country, PostalCode, IsDefault, ParentId
                                    FROM ContactPointAddress WHERE Name='CPA2'];

        // This change could affect other tests, so make sure to undo this at the end of the test
        Address selectedAddress = cpa1.Address;
        setAddressInCart(webCart, selectedAddress);

        // try/finally ensures the test data is always removed even if there is a failure in the test
        try {
            Test.startTest();
        
            // Get the payment info as a buyer so that the buyer's account is used in the method call
            Map<String, Object> paymentInfo;
            System.runAs(buyer) {
                paymentInfo = B2BPaymentController.getPaymentInfo(WebCart.Id);
            }

            // No purchase order was specified
            System.assertEquals(null, paymentInfo.get('purchaseOrderNumber'));

            // Verify the addresses returned were correct
            List<Map<String, Object>> addresses = (List<Map<String, Object>>) paymentInfo.get('addresses');
            System.assertEquals(2, addresses.size());
        
            Map<String, Object> address1 = addresses.get(0);
            Map<String, Object> address2 = addresses.get(1);
        
            testAddressMatches(address1, cpa1.Id, cpa1.Name, cpa1.Street, cpa1.City, cpa1.State, cpa1.Country, cpa1.PostalCode, cpa1.IsDefault, true);
            testAddressMatches(address2, cpa2.Id, cpa2.Name, cpa2.Street, cpa2.City, cpa2.State, cpa2.Country, cpa2.PostalCode, cpa2.IsDefault, false);
    
            Test.stopTest();
        } finally {
            // Revert the change made at the beginning of the test where we set the selected address into the cart
            setAddressInCart(webCart, new Address());
        }
    }

    // Here, the user has previously selected an address, however that address does not match a Contact Point Address (maybe the
    // buyer changed the CPA since starting the checkout). This means we should now have 3 addresses. Two contact point addresses,
    // and the selected address on the cart
    @isTest static void testSelectedAddressMatchesNoAddress() {
        // Get the data we'll need to use for running the test or for verification
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        User buyer = [SELECT Id FROM User WHERE Username='buyer@example.com'];
        ContactPointAddress cpa1 = [SELECT Id, Name, Street, City, State, Country, PostalCode, IsDefault, ParentId, Address
                                    FROM ContactPointAddress WHERE Name='CPA1'];
        ContactPointAddress cpa2 = [SELECT Id, Name, Street, City, State, Country, PostalCode, IsDefault, ParentId
                                    FROM ContactPointAddress WHERE Name='CPA2'];

        // This change could affect other tests, so make sure to undo this at the end of the test
        // We can use the shipping address as our selected address, since we know it won't match any of the billing addresses
        Address webCartBillingAddress = [Select Address FROM ContactPointAddress WHERE Name='CPAS'].Address;
        setAddressInCart(webCart, webCartBillingAddress);

        // try/finally ensures the test data is always removed even if there is a failure in the test
        try {
            Test.startTest();
        
            // Get the payment info as a buyer so that the buyer's account is used in the method call
            Map<String, Object> paymentInfo;
            System.runAs(buyer) {
                paymentInfo = B2BPaymentController.getPaymentInfo(WebCart.Id);
            }

            // No purchase order was specified
            System.assertEquals(null, paymentInfo.get('purchaseOrderNumber'));

            // Verify the addresses returned were correct
            List<Map<String, Object>> addresses = (List<Map<String, Object>>) paymentInfo.get('addresses');
            System.assertEquals(3, addresses.size());

            Map<String, Object> selectedAddress = addresses.get(0);        
            Map<String, Object> address1 = addresses.get(1);
            Map<String, Object> address2 = addresses.get(2);

            final String noName = null;
            testAddressMatches(selectedAddress, webCart.Id, noName, webCartBillingAddress.Street, webCartBillingAddress.City,
                   webCartBillingAddress.State, webCartBillingAddress.Country, webCartBillingAddress.PostalCode, false, true);
            testAddressMatches(address1, cpa1.Id, cpa1.Name, cpa1.Street, cpa1.City, cpa1.State, cpa1.Country, cpa1.PostalCode, cpa1.IsDefault, false);
            testAddressMatches(address2, cpa2.Id, cpa2.Name, cpa2.Street, cpa2.City, cpa2.State, cpa2.Country, cpa2.PostalCode, cpa2.IsDefault, false);
    
            Test.stopTest();
        } finally {
            // Revert the change made at the beginning of the test where we set the selected address into the cart
            setAddressInCart(webCart, new Address());
        }
    }

    // Verifies that the purchase order can be set in the setPayment class
    @isTest static void testSetPurchaseOrderNumber() {
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        ContactPointAddress cpa1 = [SELECT Id, Name, Street, City, State, Country, PostalCode, IsDefault, ParentId, Address
                                    FROM ContactPointAddress WHERE Name='CPA1'];

        String expectedPONumber = 'ImAPoNumber';
        String paymentType = 'PurchaseOrderNumber';
        String cartId = webCart.Id;
        Map<String, Object> billingAddress = createBillingMapFromAddress(cpa1.Address);
        Map<String, Object> paymentInfo = new Map<String, Object>();
        paymentInfo.put('poNumber', expectedPONumber);
        
        Test.startTest();
        
        B2BPaymentController.setPayment(paymentType, cartId, billingAddress, paymentInfo);

        // Get the updated cart
        WebCart updatedCart = [SELECT PaymentMethodId, PONumber FROM WebCart WHERE Name='Cart' LIMIT 1];
        System.assertEquals(null, updatedCart.PaymentMethodId);        
        System.assertEquals(expectedPONumber, updatedCart.PONumber);
        
        Test.stopTest();
    }

    // Tests credit card but without providing a payment gateway
    @isTest static void testCreditNoPaymentGateway() {
        WebCart webCart = [SELECT Id FROM WebCart WHERE Name='Cart' LIMIT 1];
        ContactPointAddress cpa1 = [SELECT Id, Name, Street, City, Country, PostalCode, IsDefault, ParentId, Address
                                    FROM ContactPointAddress WHERE Name='CPA1'];

        String paymentType = 'CreditCard';
        String cartId = webCart.Id;
        Map<String, Object> billingAddress = createBillingMapFromAddress(cpa1.Address);
        Map<String, Object> paymentInfo = new Map<String, Object>();
        
        Test.startTest();
        
        try {
            B2BPaymentController.setPayment(paymentType, cartId, billingAddress, paymentInfo);
            // Exception should have been thrown
            System.assert(false, 'Expected an exception because no Payment Gateway is setup');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
            // The string we'd expect is: 'This store is not authorized to process payments.'
            // However, the way the auraHandledException is thrown, this isn't available unless we call setMessage() prior to
            // throwing the exception. So, we'll make due with a generic exception message for this reference
        }
        
        Test.stopTest();

    }

    // The payment expects a billing map with certain keys, this fills that out given an address
    static Map<String, Object> createBillingMapFromAddress(Address address) {
        Map<String, Object> billingMap = new Map<String, Object>();
        billingMap.put('street', address.Street);
        billingMap.put('city', address.City);
        billingMap.put('state', address.State);
        billingMap.put('country', address.Country);
        billingMap.put('postalCode', address.PostalCode);
        billingMap.put('latitude', address.Latitude);
        billingMap.put('longitude', address.Longitude);
        
        return billingMap;
    }

    // Copies the specified address into the BillingAddress in the cart
    static void setAddressInCart(WebCart webCart, Address address) {
        webCart.BillingStreet = address.Street;
        webCart.BillingCity = address.City;
        webCart.BillingState = address.State;
        webCart.BillingCountry = address.Country;
        webCart.BillingPostalCode = address.PostalCode;
        webCart.BillingLatitude = address.Latitude;
        webCart.BillingLongitude = address.Longitude;
        update(webCart);
    }

    // Verifies that the address matches the expected values
    static void testAddressMatches(Map<String, Object> address, Id id, String name, String street, String city,
            String state, String country, String postalCode, Boolean isDefault, Boolean isSelected) {
        System.assertEquals(id, address.get('id'));
        System.assertEquals(name, address.get('name'));
        System.assertEquals(street, address.get('street'));
        System.assertEquals(city, address.get('city'));
        System.assertEquals(state, address.get('state'));
        System.assertEquals(country, address.get('country'));
        System.assertEquals(postalCode, address.get('postalCode'));
        System.assertEquals(isDefault, address.get('default'));
        System.assertEquals(isSelected, address.get('selected'));
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
