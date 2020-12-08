/**
 * @description Demonstrates how to make Apex calls to ConnectApi.CommerceCart class
 * to perform Cart Operations for B2B Commerce on Lightning.
 *
 * @see B2BUtils
 */
public with sharing class B2BCartControllerSample {
  /**
   * @description Demonstrates how to call ConnectApi.CommerceCart.getCartItems
   * @param  communityId The Id of the community from which the call originated
   * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
   * @param activeCartOrId ID of the cart, active, or current.
   * @param pageParam Specifies the page token to be used to view a page of information.
   * @param sortParam Sort order for items in a cart.
   * @return CartItemCollection A collection of cart items
   */
  @AuraEnabled
  public static ConnectApi.CartItemCollection getCartItems(
    String communityId,
    String effectiveAccountId,
    String activeCartOrId,
    String pageParam,
    String sortParam
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    // Get the ConnectApi.CartItemSortOrder enum value from string.
    // For the list of possible values, see:
    // see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/connectAPI_enums.htm#cartItemSortOrderEnum
    ConnectApi.CartItemSortOrder resolvedSortParam = B2BUtils.resolveSortParam(
      sortParam
    );

    // For more details, see:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    return ConnectApi.CommerceCart.getCartItems(
      webstoreId,
      effectiveAccountId,
      activeCartOrId,
      pageParam,
      resolvedSortParam
    );
  }

  /**
   * @description Demonstrates how to call ConnectApi.CommerceCart.updateCartItem
   * @param  communityId The Id of the community from which the call originated
   * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
   * @param activeCartOrId ID of the cart, active, or current.
   * @param cartItemId ID of the cart item to be updated.
   * @return CartItem The updated cart item
   */
  @AuraEnabled
  public static ConnectApi.CartItem updateCartItem(
    String communityId,
    String effectiveAccountId,
    String activeCartOrId,
    String cartItemId,
    ConnectApi.CartItemInput cartItem
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    // For more details, see:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    return ConnectApi.CommerceCart.updateCartItem(
      webstoreId,
      effectiveAccountId,
      activeCartOrId,
      cartItemId,
      cartItem
    );
  }

  /**
   * @description Demonstrates how to call ConnectApi.CommerceCart.deleteCartItem
   * @param  communityId The Id of the community from which the call originated
   * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
   * @param activeCartOrId ID of the cart, active, or current.
   * @param cartItemId ID of the cart item to be deleted.
   */
  @AuraEnabled
  public static void deleteCartItem(
    String communityId,
    String effectiveAccountId,
    String activeCartOrId,
    String cartItemId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    // For more details, see:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    ConnectApi.CommerceCart.deleteCartItem(
      webstoreId,
      effectiveAccountId,
      activeCartOrId,
      cartItemId
    );
  }

  /**
   * @description Demonstrates how to call ConnectApi.CommerceCart.getCartSummary
   * @param  communityId The Id of the community from which the call originated
   * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
   * @param activeCartOrId ID of the cart, active, or current.
   */
  @AuraEnabled
  public static ConnectApi.CartSummary getCartSummary(
    String communityId,
    String effectiveAccountId,
    String activeCartOrId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    // For more details, see:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    return ConnectApi.CommerceCart.getCartSummary(
      webstoreId,
      effectiveAccountId,
      activeCartOrId
    );
  }

  /**
   * @description Demonstrates how to call ConnectApi.CommerceCart.createCart
   * @param  communityId The Id of the community from which the call originated
   * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
   */
  @AuraEnabled
  public static ConnectApi.CartSummary createCart(
    String communityId,
    String effectiveAccountId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);
    ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
    cartInput.effectiveAccountId = effectiveAccountId;
    // For more details, see:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    return ConnectApi.CommerceCart.createCart(webstoreId, cartInput);
  }

  /**
   * @description Demonstrates how to call ConnectApi.CommerceCart.deleteCart
   * @param  communityId The Id of the community from which the call originated
   * @param effectiveAccountId ID of the account for which the request is made. If null, defaults to the account ID for the context user.
   * @param activeCartOrId ID of the cart, active, or current.
   */
  @AuraEnabled
  public static void deleteCart(
    String communityId,
    String effectiveAccountId,
    String activeCartOrId
  ) {
    // Lookup the webstore ID associated with the community
    String webstoreId = B2BUtils.resolveCommunityIdToWebstoreId(communityId);

    // For more details, see:
    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCart_static_methods.htm
    ConnectApi.CommerceCart.deleteCart(
      webstoreId,
      effectiveAccountId,
      activeCartOrId
    );
  }
}
