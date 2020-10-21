public class B2BCartToOrderDraft {

    public class B2BCartToOrderDraftRequest {
		
        @InvocableVariable(required=true)
        public ID checkoutSessionId;
        
        @InvocableVariable(required=true)
        public ID cartId;
    }
    
    /**
     * @description Maps a cart to an order. Activates it, and closes the cart. Returns the resulting order summary id.
     * @param request The checkout session and cart id.
     * @return The OrderId that resulted from this class.
     */
    @InvocableMethod(label='Map Cart to Order Draft' description='Maps the cart and related data to an order' category='B2B Commerce')
    public static List<ID> cartToOrder(List<B2BCartToOrderDraftRequest> request) {
        
        // screen flows do not run in bulk
        Id cartId = request[0].cartId;
        Id checkoutSessionId = request[0].checkoutSessionId;
        
        // load the primary delivery group (only one supported at this time)
        Id cartDeliveryGroupId = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cartId][0].Id;

        Id orderId = mapAndInsertCartToOrder(cartId);
        updateCheckoutSession(checkoutSessionId, orderId);
        
        Id orderDeliveryGroupId = mapAndInsertCartDeliveryGroupToOrderDeliveryGroup(cartDeliveryGroupId, orderId);
        mapAndInsertCartItems(cartDeliveryGroupId, orderId, orderDeliveryGroupId);
                
        List<ID> orderIds = new List<ID>();
        orderIds.add(orderId);
        return orderIds;
    }
    
    /**
     * @description Satisfy the preconditions required to use the following call to Activate the Order
     */
    private static void updateCheckoutSession(Id checkoutSessionId, Id orderId) {
        try {
            CartCheckoutSession checkoutSession = [SELECT OrderId, NextState FROM CartCheckoutSession WHERE Id = :checkoutSessionId LIMIT 1];
        	checkoutSession.OrderId = orderId;
            checkoutSession.NextState = 'Complete';
        	update checkoutSession;
        } catch (Exception e) {
            System.debug('An error occurred updating checkout session with the draft order Id');
        }
    }
    
    /**
     * @description Maps the cart entity to an order entity and returns the id of the order entity that was created.
     * @param cartId The cart id to map to an order.
     * @return The id of the order that was created.
     */
    private static Id mapAndInsertCartToOrder(Id cartId) {
        // Get the cart data needed to populate the order
        List<WebCart> carts = [SELECT Id,
                               AccountId,
                               OwnerId,
                               WebStoreId,
                               PoNumber,
                               BillingStreet,
                               BillingCity,
                               BillingState,
                               BillingPostalCode,
                               BillingCountry,
                               BillingLatitude,
                               BillingLongitude,
                               CurrencyIsoCode
                               FROM WebCart WHERE Id = :cartId];
        WebCart cart = carts[0];
        
        // Create the order
        Date now = Date.today();    
        Order order = new Order(
            AccountId = cart.AccountId,
            OwnerId = cart.OwnerId,
            SalesStoreId = cart.WebStoreId,
            PoNumber = cart.PoNumber,
            BillingStreet = cart.BillingStreet,
            BillingCity = cart.BillingCity,
            BillingState = cart.BillingState,
            BillingPostalCode = cart.BillingPostalCode,
            BillingCountry = cart.BillingCountry,
            BillingLatitude = cart.BillingLatitude,
            BillingLongitude = cart.BillingLongitude,
            CurrencyIsoCode = cart.CurrencyIsoCode,
            EffectiveDate = now,
            OrderedDate = now,
            Status = 'Draft'
        );
        
        insert(order);
        return order.Id;
    }
    
    /**
     * @description Maps the cart delivery group entity to an order delivery group entity and returns the id of the
     *              order delivery group entity that was created.
     * @param cartDeliveryGroupId The cartDeliveryGroup id to map.
     * @param orderId The orderDeliveryGroup is linked to the original order.
     * @return The id of the order delivery group that was created.
     */
    private static Id mapAndInsertCartDeliveryGroupToOrderDeliveryGroup(Id cartDeliveryGroupId, Id orderId) {
        // Get the cart delivery group data needed to populate the order delivery group
        List<CartDeliveryGroup> cartDeliveryGroups = [SELECT
                                                      DesiredDeliveryDate,
                                                      DeliverToName,
                                                      ShippingInstructions,
                                                      DeliverToStreet,
                                                      DeliverToCity,
                                                      DeliverToState,
                                                      DeliverToPostalCode,
                                                      DeliverToCountry,
                                                      DeliverToLatitude,
                                                      DeliverToLongitude,
                                                      DeliveryMethodId
                                                      FROM CartDeliveryGroup WHERE Id = :cartDeliveryGroupId];
        CartDeliveryGroup cartDeliveryGroup = cartDeliveryGroups[0];
        
        // Create the order delivery group
        Date desiredDeliveryDate = toDate(cartDeliveryGroup.DesiredDeliveryDate);
        OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
            DesiredDeliveryDate = desiredDeliveryDate,
            DeliverToName = cartDeliveryGroup.DeliverToName,
            DeliveryInstructions = cartDeliveryGroup.ShippingInstructions,
            DeliverToStreet = cartDeliveryGroup.DeliverToStreet,
            DeliverToCity = cartDeliveryGroup.DeliverToCity,
            DeliverToState = cartDeliveryGroup.DeliverToState,
            DeliverToPostalCode = cartDeliveryGroup.DeliverToPostalCode,
            DeliverToCountry = cartDeliveryGroup.DeliverToCountry,
            DeliverToLatitude = cartDeliveryGroup.DeliverToLatitude,
            DeliverToLongitude = cartDeliveryGroup.DeliverToLongitude,
            OrderDeliveryMethodId = cartDeliveryGroup.DeliveryMethodId,
            OrderId = orderId
        );

        insert(orderDeliveryGroup);
        return orderDeliveryGroup.Id;
    }
    
    /**
     * @description Maps the cart items to a set of order items. This also creates order item adjustments.
     *              Tax adjustments could probably also be done here, but are not part of the example.
     * @param cartDeliveryGroupId the cartDeliveryGroup id for this set of cart items.
     * @param orderId The items are linked to the original order.
     * @param orderDeliveryGroupId The items are linked to the order delivery group.
     */
    private static void mapAndInsertCartItems(Id cartDeliveryGroupId, Id orderId, Id orderDeliveryGroupId) {
        // Get the cart items needed to populate the order items and adjustments
        List<CartItem> cartItems = [SELECT
                                    AdjustmentAmount,
                                    Product2Id,
                                    Type,
                                    Quantity,
                                    ListPrice,
                                    SalesPrice,
                                    TotalLineAmount
                                    FROM CartItem WHERE CartDeliveryGroupId = :cartDeliveryGroupId];
        
        List<OrderItem> orderItems = new List<OrderItem>();
        // For each item, map it to an order, then add adjustments
        for (CartItem cartItem : cartItems) {
            orderItems.add(mapCartItemToOrderItem(cartItem, orderId, orderDeliveryGroupId));
        }
        
        // If there are no items to insert, we can't do anything
        if (orderItems.size() == 0 || cartItems.size() != orderItems.size()) {
            return;
        }
        
        insert(orderItems);

		List<OrderItemAdjustmentLineItem> lineItemAdjustments = new List<OrderItemAdjustmentLineItem>();
        for (Integer index = 0; index < cartItems.size(); index++) {
            OrderItemAdjustmentLineItem lineItemAdjustment = mapOrderItemAdjustmentLineItemTo(cartItems.get(index), orderItems.get(index).Id);
            if (lineItemAdjustment != null) {
                lineItemAdjustments.add(lineItemAdjustment);
            }
        }
        if (lineItemAdjustments.size() > 0) {
            insert(lineItemAdjustments);
        }
    }
    
    /**
     * @description Maps the cart item to an order item.
     * @param cartItem The cartItem to map to an order item.
     * @param orderId The item is linked to the original order.
     * @param orderDeliveryGroupId The item is linked to the order delivery group.
     * @return The order item to be inserted.
     */
    private static OrderItem mapCartItemToOrderItem(CartItem cartItem, Id orderId, Id orderDeliveryGroupId) {
        String orderItemType = getOrderItemType(cartItem.Type);
        Decimal unitPrice = getUnitPrice(cartItem);
        
        OrderItem orderItem = new OrderItem(
            Product2Id = cartItem.Product2Id,
            Type = orderItemType,
            Quantity = cartItem.Quantity,
            ListPrice = cartItem.ListPrice,
            UnitPrice = unitPrice,
            OrderId = orderId,
            OrderDeliveryGroupId = orderDeliveryGroupId,
            TotalLineAmount = cartItem.TotalLineAmount
        );
        
        return orderItem;
    }
    


    /**
     * @description Maps the cart item to create an adjustment line item. If the item would normally cost
     *              $100, but costs $80, this is where that adjustment is recorded.
     * @param cartItem The cartItem to map to an order adjustment line item.
     * @param orderItemId The adjustment is mapped to an order item.
     * @return The order item adjustment to be inserted.
     */
    private static OrderItemAdjustmentLineItem mapOrderItemAdjustmentLineItemTo(CartItem cartItem, Id orderItemId) {
        Decimal adjustmentAmount = getAdjustmentAmount(cartItem);
        if (adjustmentAmount == null || adjustmentAmount == 0.0) {
            return null;
        }
        
        OrderItemAdjustmentLineItem orderItemAdjustmentLineItem = new OrderItemAdjustmentLineItem(
            Amount = adjustmentAmount,
            OrderItemId = orderItemId,
            Name = 'Price Adjustment'
        );
        
        return orderItemAdjustmentLineItem;
    }    


    /**
     * @description Gets the adjustment amount from the cart item. If none exists, returns zero.
     * @param cartItem Where to get the adjustment amount from.
     * @return The adjustment amount (0, if there is no adjustment).
     */
    private static Decimal getAdjustmentAmount(CartItem cartItem) {
        if (cartItem.AdjustmentAmount == null) {
            return 0;
        }
        
        return cartItem.AdjustmentAmount;
    }
    
    /**
     * @description Gets the order item type from the sales item type. This maps the cart item type to the order item type.
     * @param salesItemType The cart item's type.
     * @return The order Item Type or null if the type doesn't map.
     */
    private static String getOrderItemType(String cartItemType) {
        if (cartItemType == 'Product') {
            return 'Order Product';
        }
        if (cartItemType == 'Charge') {
            return 'Delivery Charge';
        }
        
        return null;
    }

    /**
     * @description Gets the unit price from the cart item. This tries to use the sales price but will default to the list price
     *              if there is no sales price.
     * @param cartItem The item that has the prices.
     * @return The unit price.
     */
    private static Decimal getUnitPrice(CartItem cartItem) {
        if (cartItem.SalesPrice != null) {
            return cartItem.SalesPrice;
        }

        return cartItem.ListPrice;
    }
    
    /**
     * @description Converts a DateTime object to a Date object.
     * @param dt The datetime to convert.
     * @return The new Date.
     */
    private static Date toDate(DateTime dt) {
        if (dt != null) {
            return Date.newinstance(dt.year(), dt.month(), dt.day());
        }
        
        return null;
    }
}