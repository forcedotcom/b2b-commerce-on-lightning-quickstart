/**
 * @description Util methods for B2B commerce on Lightning Samples
 *
 * @see B2BUtils
 */
public with sharing class B2BUtils {
  // A cache which maps community Ids to WebStore Ids
  private static Map<String, String> communityIdToWebStoreIdCache = new Map<String, String>();

  // A cache to map a string to ConnectApi.CartItemSortOrder
  private static Map<String, ConnectApi.CartItemSortOrder> sortOrderCache = new Map<String, ConnectApi.CartItemSortOrder>();

  /**
   * @description Given a community ID, returns the relavent webstore ID for use in B2B Commerce on lightning
   * @param  communityId The Id of the community from which the call originated
   * @return weStoreId The webStoreId corresponding to the community Id.
   * @example
   * String webStoreId = B2BUtils.resolveCommunityIdToWebstoreId('0DB2D0000004Xz7');
   */
  public static String resolveCommunityIdToWebstoreId(String communityId) {
    if (communityIdToWebStoreIdCache.containsKey(communityId)) {
      return communityIdToWebStoreIdCache.get(communityId);
    } else {
      String webStoreId = [
        SELECT WebStoreId
        FROM WebStoreNetwork
        WHERE NetworkId = :communityId
        WITH SECURITY_ENFORCED
        LIMIT 1
      ]
      .WebStoreId;
      communityIdToWebStoreIdCache.put(communityId, webStoreId);
      return webStoreId;
    }
  }

  /**
   * @description Given a sortParam string, return null or the relavent ConnectApi.CartItemSortOrder enum value
   * See https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/connectAPI_enums.htm#cartItemSortOrderEnum for the enum values
   * @param  sortParam A string representing a sort Param.
   * @return resolvedSortParam A ConnectApi.CartItemSortOrder enum value or null
   * @example
   * ConnectApi.CartItemSortOrder sortParam = B2BUtils.resolveSortParam('CreatedDateAsc');
   */
  public static ConnectApi.CartItemSortOrder resolveSortParam(
    String sortParam
  ) {
      if (sortOrderCache.isEmpty()) {
        for (
          ConnectApi.CartItemSortOrder sortOrder : ConnectApi.CartItemSortOrder.values()
        ) {
            sortOrderCache.put(sortOrder.name(), sortOrder);
          }
      }
      return sortOrderCache.get(sortParam);
  }
    
  public static String getUserAccountID() {
      String userId = UserInfo.getUserId();
      String contactId = [SELECT ContactId FROM User WHERE Id = :userId].ContactId;
      return [SELECT AccountId FROM Contact WHERE Id = :contactId].AccountId; 
  }
}