@isTest(SeeAllData=true)
public class QuickStartIntegrationTest {
    // This test assumes you ran Quick Start for just one store.
    // If you have multiple stores you need to specify the store name in the query below:
    public static WebStore webStore = [SELECT Id FROM WebStore WHERE Type = 'B2B' LIMIT 1];
    public static String buyerUsername = 'buyer@scratch.org';
    
    @isTest static void testB2BWebStoreCreated() {
        Integer numberOfB2BStores = [SELECT count() FROM WebStore WHERE Type = 'B2B'];
        System.assert(numberOfB2BStores > 0, 'There are no B2B stores created in this environment.');
    }
    @isTest static void testInventoryIntegrationIsRegistered() {
        Integer numberOfRegisteredExternalServices = [SELECT count() FROM RegisteredExternalService WHERE ExternalServiceProviderType = 'Inventory'];
        System.assert(numberOfRegisteredExternalServices > 0, 'There are no registered integrations for Inventory');
    }
    @isTest static void testShipmentIntegrationIsRegistered() {
        Integer numberOfRegisteredExternalServices = [SELECT count() FROM RegisteredExternalService WHERE ExternalServiceProviderType = 'Shipment'];
        System.assert(numberOfRegisteredExternalServices > 0, 'There are no registered integrations for Shipment');
    }
    @isTest static void testTaxIntegrationIsRegistered() {
        Integer numberOfRegisteredExternalServices = [SELECT count() FROM RegisteredExternalService WHERE ExternalServiceProviderType = 'Tax'];
        System.assert(numberOfRegisteredExternalServices > 0, 'There are no registered integrations for Tax');
    }
    @isTest static void testPricingIntegrationIsNotRegistered() {
        Integer numberOfRegisteredExternalServices = [SELECT count() FROM RegisteredExternalService WHERE ExternalServiceProviderType = 'Price'];
        System.assert(numberOfRegisteredExternalServices == 0, 'There should be no registered integration for Price because by default Quick Start should use the Salesforce internal pricing');
    }
    @isTest static void testPaymentGatewayProviderSalesforcePGPCreated() {
        Integer numberOfPaymentGatewayProviders = [SELECT count() FROM PaymentGatewayProvider WHERE DeveloperName = 'SalesforcePGP'];
        System.assert(numberOfPaymentGatewayProviders > 0, 'There are no Payment Gateway Providers');
    }
    @isTest static void testPaymentGatewayCreated() {
        Integer numberOfPaymentGateways = [SELECT count() FROM PaymentGateway WHERE PaymentGatewayName = 'SalesforcePG'];
        System.assert(numberOfPaymentGateways > 0, 'There are no Payment Gateways');
    }
    @isTest static void testInventoryStoreIntegratedServiceMapping() {
        Integer numberOfMaps = [SELECT count() FROM StoreIntegratedService WHERE (ServiceProviderType = 'Inventory') AND (StoreId = :webStore.Id)];
        System.assert(numberOfMaps > 0, 'There is no mapping between the Inventory integration and the test store');
    }
    @isTest static void testShipmentStoreIntegratedServiceMapping() {
        Integer numberOfMaps = [SELECT count() FROM StoreIntegratedService WHERE (ServiceProviderType = 'Shipment') AND (StoreId = :webStore.Id)];
        System.assert(numberOfMaps > 0, 'There is no mapping between the Shipment integration and the test store');
    }
    @isTest static void testTaxStoreIntegratedServiceMapping() {
        Integer numberOfMaps = [SELECT count() FROM StoreIntegratedService WHERE (ServiceProviderType = 'Tax') AND (StoreId = :webStore.Id)];
        System.assert(numberOfMaps > 0, 'There is no mapping between the Tax integration and the test store');
    }
    @isTest static void testPriceStoreIntegratedServiceMapping() {
        Integer numberOfMaps = [SELECT count() FROM StoreIntegratedService WHERE (ServiceProviderType = 'Price') AND (StoreId = :webStore.Id)];
        System.assert(numberOfMaps > 0, 'There is no mapping between the Price integration and the test store');
    }
    @isTest static void testPaymentStoreIntegratedServiceMapping() {
        Integer numberOfMaps = [SELECT count() FROM StoreIntegratedService WHERE (ServiceProviderType = 'Payment') AND (StoreId = :webStore.Id)];
        System.assert(numberOfMaps > 0, 'There is no mapping between the Payment integration and the test store');
    }
    @isTest static void testBuyerAccountCreated() {
        Integer numberOfBuyerUsers = [SELECT count() FROM User WHERE Username = :buyerUsername];
        System.assert(numberOfBuyerUsers > 0, 'No user with this username could be found: ' + buyerUsername);
        String buyerUserAccountName = buyerUsername + 'JITUserAccount';
        Account buyerUserAccount = [SELECT Id FROM Account WHERE Name = :buyerUserAccountName LIMIT 1];
        System.assertNotEquals(null, buyerUserAccount, 'There is no account associated with your buyer user');
    }
    @isTest static void testContactPointAddressesCreatedForBuyer() {
        String buyerUserAccountName = buyerUsername + 'JITUserAccount';
        Account buyerUserAccount = [SELECT Id FROM Account WHERE Name = :buyerUserAccountName LIMIT 1];
        Integer numberOfContactPointAddressesAssociatedToAccount = [SELECT count() FROM ContactPointAddress WHERE ParentId = :buyerUserAccount.Id];
        System.assert(numberOfContactPointAddressesAssociatedToAccount == 4, 'The number of Contact Point Addresses for the buyer account is not 4');
    }
    @isTest static void testBuyerAccountIsAssociatedToBuyerGroup() {
        String buyerUserAccountName = buyerUsername + 'JITUserAccount';
        Account buyerUserAccount = [SELECT Id FROM Account WHERE Name = :buyerUserAccountName LIMIT 1];
        Integer numberOfBuyerGroupMembersAssociatedToAccount = [SELECT count() FROM BuyerGroupMember WHERE BuyerId = :buyerUserAccount.Id];
        System.assert(numberOfBuyerGroupMembersAssociatedToAccount == 1, 'The number of Buyer Group Members for the buyer account is not 1');
    }
    @isTest static void testProductsInserted() {
        Integer numberOfProducts = [SELECT count() FROM Product2];
        System.assert(numberOfProducts > 0, 'There are no products in the org');
    }
    @isTest static void testCommerceEntitlementProductsCreated() {
        Integer numberOfEntitlementProducts = [SELECT count() FROM CommerceEntitlementProduct];
        System.assert(numberOfEntitlementProducts > 0, 'There are no entitlement products in the org');
    }
    @isTest static void testCatalogsCreatedForStore() {
        Integer numberOfCatalogs = [SELECT count() FROM WebStoreCatalog WHERE SalesStoreId = :webStore.Id];
        System.assert(numberOfCatalogs > 0, 'There are no catalogs for the test store');
    }
    @isTest static void testPricebooksMappedToStore() {
        Integer numberOfPricebooks = [SELECT count() FROM WebStorePricebook  WHERE WebStoreId = :webStore.Id];
        System.assert(numberOfPricebooks > 0, 'There are associations between the pricebooks and the test store');
    }
    @isTest static void testBuyerGroupToPricebookMapping() {
        Integer numberOfBuyerGroupToPricebookMaps = [SELECT count() FROM BuyerGroupPricebook];
        System.assert(numberOfBuyerGroupToPricebookMaps > 0, 'There are associations between the pricebooks and the buyer groups in this org');
    }
}