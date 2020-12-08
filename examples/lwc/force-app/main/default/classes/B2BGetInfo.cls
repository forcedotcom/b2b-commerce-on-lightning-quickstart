public with sharing class B2BGetInfo {
  @AuraEnabled(cacheable=true)
  public static ConnectApi.ProductDetail getProduct(
    String communityId,
    String productId,
    String effectiveAccountId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCatalog_static_methods.htm#apex_ConnectAPI_CommerceCatalog_static_methods
    return ConnectApi.CommerceCatalog.getProduct(
      webstoreId,
      productId,
      effectiveAccountID,
      null,
      false,
      null,
      false,
      true,
      false
    );
  }

  @AuraEnabled(cacheable=true)
  public static Boolean checkProductIsInStock(String productId) {
    /*
     * The following is an example of calling an external API.
     * The example API provided is extremely simple: It takes in a product id
     * and returns a true or false value for inStock based on whether the 15th char is odd or even.
     *
     * To access this endpoint on your org, go to Remote Site Settings in Setup as an admin user
     * click "New Remote Site" and provide "https://inventorymanagerdemo.herokuapp.com" for the "Remote Site URL" field
     */
    Http http = new Http();
    HttpRequest request = new HttpRequest();
    String endpoint =
      'https://inventorymanagerdemo.herokuapp.com/api/inventory/' + productId;
    request.setEndpoint(endpoint);
    request.setMethod('GET');
    HttpResponse response = http.send(request);
    // If the request is successful, parse the JSON response.
    if (response.getStatusCode() == 200) {
      // Deserialize the JSON string into collections of primitive data types.
      Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(
        response.getBody()
      );
      return (boolean) results.get('inStock');
    } else {
      return false;
    }
  }

  @AuraEnabled
  public static ConnectApi.CartSummary getCartSummary(
    String communityId,
    String effectiveAccountId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    //'current' is available in version 50.0 and later and indicates a cart with a status that isn’t Closed or PendingDelete
    //This is important for the product detail page since we are using the cart summary to check if the status is "Processing" or "Checkout"
    String activeCartOrId = 'current';

    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    return ConnectApi.CommerceCart.getCartSummary(
      webstoreId,
      effectiveAccountId,
      activeCartOrId
    );
  }

  @AuraEnabled
  public static ConnectApi.CartItem addToCart(
    String communityId,
    String productId,
    String quantity,
    String effectiveAccountId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    ConnectApi.CartItemInput cartInput = new ConnectApi.CartItemInput();
    cartInput.productId = productId;
    cartInput.quantity = quantity;
    cartInput.type = ConnectApi.CartItemType.PRODUCT;

    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm#apex_ConnectAPI_CommerceCart_static_methods
    return ConnectApi.CommerceCart.addItemToCart(
      webstoreId,
      effectiveAccountId,
      'active',
      cartInput
    );
  }

  @AuraEnabled
  public static ConnectApi.Wishlist createAndAddToList(
    String communityId,
    String productId,
    String wishlistName,
    String effectiveAccountId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    // Store the product in a WishlistItemInput to pass to the Wishlist
    ConnectApi.WishlistItemInput wishlistItemInput = new ConnectApi.WishlistItemInput();
    wishlistItemInput.productId = productId;

    //Create a wishlistInput to be created
    ConnectApi.WishlistInput wishlistInput = new ConnectApi.WishlistInput();
    wishlistInput.name = wishlistName;
    wishlistInput.products = new List<ConnectApi.WishlistItemInput>{
      wishlistItemInput
    };

    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceWishlist_static_methods.htm#apex_ConnectAPI_CommerceWishlist_static_methods
    return ConnectApi.CommerceWishlist.createWishlist(
      webstoreId,
      effectiveAccountId,
      wishlistInput
    );
  }

  @AuraEnabled(cacheable=true)
  public static ConnectApi.ProductPrice getProductPrice(
    String communityId,
    String productId,
    String effectiveAccountId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceStorePricing_static_methods.htm#apex_ConnectAPI_CommerceStorePricing_static_methods
    return ConnectApi.CommerceStorePricing.getProductPrice(
      webstoreId,
      productId,
      effectiveAccountId
    );
  }
}
