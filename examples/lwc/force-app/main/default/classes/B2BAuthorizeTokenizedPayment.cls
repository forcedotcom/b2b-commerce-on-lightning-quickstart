public class B2BAuthorizeTokenizedPayment {

    public class B2BAuthorizeTokenizedPaymentRequest {
        @InvocableVariable(required=true)
        public ID cartId;
    }
    
    /**
     * @description Authorizes payment for credit information that was previously tokenized. 
     * @param request The cart id.
     * @return Any errors that occurred.
     */
    @InvocableMethod(callout=true label='Authorize Tokenized Payment' description='Authorizes payment for credit information that was previously tokenized' category='B2B Commerce')
    public static List<String> authorizePaymentInfo(List<B2BAuthorizeTokenizedPaymentRequest> request) {
        String cartId = request[0].cartId;
        List<String> errors = new List<String>();

        try {
            WebCart cart = [SELECT WebStoreId, GrandTotalAmount, AccountId, PaymentMethodId
                            FROM WebCart WHERE Id=:cartId];

            ConnectApi.AuthorizationRequest authRequest = new ConnectApi.AuthorizationRequest();
            
            // Set the tokenized ID
            ConnectApi.AuthApiPaymentMethodRequest authApiPaymentMethodRequest = new ConnectApi.AuthApiPaymentMethodRequest();
            authApiPaymentMethodRequest.Id = cart.PaymentMethodId;

            authRequest.accountId = cart.AccountId;
            authRequest.amount = cart.GrandTotalAmount;
            authRequest.comments = 'Authorizing $' + cart.GrandTotalAmount;
            authRequest.effectiveDate = Datetime.now();
            authRequest.currencyIsoCode = UserInfo.getDefaultCurrency();
            
            // Cannot proceed if paymentGatewayId does not exist
            String paymentGatewayId = getPaymentGatewayId(cart.WebStoreId);
            if (paymentGatewayId == null || paymentGatewayId.equals('')) {
               throw new AuraHandledException('This store is not authorized to process payments.');
            }

            authRequest.paymentGatewayId = paymentGatewayId;
            authRequest.paymentMethod = authApiPaymentMethodRequest;
            authRequest.paymentGroup = getPaymentGroup(cartId);

            // Authorize Payment with Payments API
            ConnectApi.AuthorizationResponse authResponse = ConnectApi.Payments.authorize(authRequest);

            if (authResponse.error != null) {
                String errorMessage = 'AuthResponseError: ' + authResponse.error.message;
                System.debug(errorMessage);
                errors.add(errorMessage);
            }
        } catch (ConnectApi.ConnectApiException e) {
            System.debug('A Connect Api exception occurred authorizing tokenized payment: ' + e.getMessage());
            errors.add(e.getMessage());
        } catch (Exception e) {
            System.debug('An error occurred authorizing tokenized payment: ' + e.getMessage());
            errors.add(e.getMessage());
        }

        return errors;
    }

    private static ConnectApi.PaymentGroupRequest getPaymentGroup(String cartId) {
        try {
            ConnectApi.PaymentGroupRequest paymentGroup = new ConnectApi.PaymentGroupRequest();
        
            paymentGroup.createPaymentGroup = true;
            paymentGroup.currencyIsoCode = UserInfo.getDefaultCurrency();
        
            String orderId = getOrderId(cartId);
            if (orderId != null && !orderId.equals('')) {
                paymentGroup.sourceObjectId = getOrderId(cartId);            
            } else {
                NoDataFoundException e = new NoDataFoundException();
                e.setMessage('No order is associated with this cart');
                throw e;
            }

            return paymentGroup;
        } catch (Exception e) {
            NoDataFoundException ndfe = new NoDataFoundException();
            ndfe.setMessage('No order is associated with this cart');
            throw ndfe;
        }
    }
    
    private static String getOrderId(String cartId) {
            return [SELECT OrderId FROM CartCheckoutSession WHERE WebCartId=:cartId AND IsArchived=false].OrderId;
    }
    
    private static String getPaymentGatewayId(String webStoreId) {
        String paymentGatewayId = null;
        try {
            paymentGatewayId = [SELECT Integration FROM StoreIntegratedService WHERE ServiceProviderType='Payment' AND StoreId=:webStoreId].Integration;
        } catch (Exception e) {
            // For debug logs
            System.debug('Error querying the payment integration from StoreIntegratedService: ' + e.getMessage());
        }
        return paymentGatewayId;
    }
}