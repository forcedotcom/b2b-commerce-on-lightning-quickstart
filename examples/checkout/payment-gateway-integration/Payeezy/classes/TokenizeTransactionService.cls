/**
 * Tokenize Service class
 */
public class TokenizeTransactionService extends AbstractTransactionService{

    private static final String STATUS = 'status';
    private static final String TYPE = 'type';
    private static final String TOKEN = 'token';
    /**
     * Constructor that sets the gatewayContext for the service
     */
    public TokenizeTransactionService(commercepayments.paymentGatewayContext gatewayContext){
        super(gatewayContext);
    }

    /**
     * Function to build request for Tokenize Transaction
     * Creates a new request and set request body, authorization parameters and other related fields
     */
    public override HttpRequest buildRequest(){
        HttpRequest req = new HttpRequest();
        //The rest of the endpoint is set in the buildRequestBody
        req.setEndpoint('/v1/transactions/tokens');
        req.setMethod('POST');
        req.setBody(buildRequestBody((commercepayments.PaymentMethodTokenizationRequest)gatewayContext.getPaymentRequest(),req));
        setAuthorizationHeaders(req);
        return req;
    }

    /**
     * Function to build gateway response for Tokenize Transaction
     * The input is the response from gateway
     * It creates and returns CptureGatewayResponse from the HttpResponse
     */
    public override commercepayments.GatewayResponse buildResponse(HttpResponse response){
        String statusCode = String.valueOf(response.getStatusCode());
        Map <String, String> mapOfResponseValues = parseResponse(response.getBody());
        commercepayments.PaymentMethodTokenizationResponse tokenizeResponse = new commercepayments.PaymentMethodTokenizationResponse();
        String res_code = mapOfResponseValues.get(GATEWAY_RESPONSE_CODE);
        String transactionStatus = mapOfResponseValues.get(STATUS);
        if(transactionStatus != null){
            if(transactionStatus == 'success'){
                system.debug('Response - success');
                tokenizeResponse.setGatewayResultCode(res_code);
                tokenizeResponse.setGatewayResultCodeDescription(mapOfResponseValues.get(GATEWAY_MESSAGE));
                String gatewayToken = mapOfResponseValues.get('value');
                tokenizeResponse.setGatewayToken(gatewayToken);
                Map<String, Object> tokenDetails = new Map<String, Object>();
                tokenDetails.put('type', mapOfResponseValues.get('gatewayTokenDetails'));
                String tokenDetailsString = JSON.Serialize(tokenDetails);
                tokenizeResponse.setGatewayTokenDetails(tokenDetailsString);
                tokenizeResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(commercepayments.SalesforceResultCode.SUCCESS.name()));
            }else{
                system.debug('Response - failed');
                tokenizeResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(commercepayments.SalesforceResultCode.DECLINE.name()));
                String description = mapOfResponseValues.get('status');
                tokenizeResponse.setGatewayResultCode(transactionStatus);
                if(description != null){
                    tokenizeResponse.setGatewayResultCodeDescription(description);
                }else{
                    tokenizeResponse.setGatewayResultCodeDescription(transactionStatus);
                }
            }
        }else {
                String message = mapOfResponseValues.get('message') == null? mapOfResponseValues.get('description') :mapOfResponseValues.get('message');
                commercepayments.GatewayErrorResponse error = new commercepayments.GatewayErrorResponse(statusCode, message);
                return error;
        }
        tokenizeResponse.setGatewayDate(system.now());    //Gateway does not send date, assigning for test
        return tokenizeResponse;
    }

    /**
     * Function to build request body for Tokenize Transaction
     */
    private String buildRequestBody(commercepayments.PaymentMethodTokenizationRequest tokenizeRequest,HttpRequest req) {
        //String requestBody = createRequestBody('tokenize', tokenizeRequest.cardpaymentMethod);
        JSONGenerator jsonGeneratorInstance = JSON.createGenerator(true);
        jsonGeneratorInstance.writeStartObject();
        jsonGeneratorInstance.writeStringField('type', 'FDToken');
        jsonGeneratorInstance.writeStringField('auth', 'false');
        jsonGeneratorInstance.writeStringField('ta_token', 'NOIW');
        commercepayments.CardPaymentMethodRequest cardPaymentMethod = tokenizeRequest.cardpaymentMethod;
        checkForRequiredFields(cardPaymentMethod);
        jsonGeneratorInstance.writeFieldName('credit_card');
        jsonGeneratorInstance.writeStartObject();
        if(cardPaymentMethod.cardType!=null)
            jsonGeneratorInstance.writeStringField('type',cardPaymentMethod.cardType.name());
        if(cardPaymentMethod.cvv!=null)
            jsonGeneratorInstance.writeStringField('cvv', String.ValueOf(cardPaymentMethod.cvv));
        if(cardPaymentMethod.cardholdername!=null)
            jsonGeneratorInstance.writeStringField('cardholder_name', cardPaymentMethod.cardholdername);
        if(cardPaymentMethod.cardnumber!=null)
            jsonGeneratorInstance.writeStringField('card_number', cardPaymentMethod.cardnumber);
         if(cardPaymentMethod.expiryMonth!=null && cardPaymentMethod.expiryYear!=null ) {
            String expMonth = ((String.ValueOf(cardPaymentMethod.expiryMonth)).length()==1?'0':'') + String.ValueOf(cardPaymentMethod.expiryMonth);
            jsonGeneratorInstance.writeStringField('exp_date', expMonth+(String.ValueOf(cardPaymentMethod.expiryYear)).substring(2));
         }
        jsonGeneratorInstance.writeEndObject();
        jsonGeneratorInstance.writeEndObject();
        return jsonGeneratorInstance.getAsString();
    }
    
    private void checkForRequiredFields(commercepayments.CardPaymentMethodRequest cardPaymentMethod){
        if(cardPaymentMethod == null){
            throw new PayeezyValidationException('Invalid Request parameters: Missing Card Details');
        }
        if(cardPaymentMethod.cardnumber == null){
            throw new PayeezyValidationException('Invalid Request parameters: Missing Card Number');
        }
        if(cardPaymentMethod.cvv == null){
            throw new PayeezyValidationException('Invalid Request parameters: Missing Card CVV');
        }
        if(cardPaymentMethod.expiryYear == null || cardPaymentMethod.expiryMonth == null){
            throw new PayeezyValidationException('Invalid Request parameters: Missing Card Expiry date');
        }
        if( cardPaymentMethod.cardholdername == null){
            throw new PayeezyValidationException('Invalid Request parameters: Missing Card Holder Name');
        }
    }
}