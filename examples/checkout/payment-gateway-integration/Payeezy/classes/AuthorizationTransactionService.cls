/**
 * Authorization Service class 
 */ 
public class AuthorizationTransactionService extends AbstractTransactionService{

    /**
     * Constructor that sets the gatewayContext for the service
     * The gateway context contains the input request and request type
     */ 
    public AuthorizationTransactionService(commercepayments.paymentGatewayContext gatewayContext){
        super(gatewayContext);
    }
    
    /**
     * Function to build request for Authorization Transaction
     * Creates a new request and set request body, authorization parameters and other related fields
     */ 
    public override HttpRequest buildRequest(){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('/v1/transactions');
        req.setMethod('POST');
        req.setBody(buildAuthRequestBody((commercepayments.AuthorizationRequest)gatewayContext.getPaymentRequest()));
        setAuthorizationHeaders(req);
        return req;
    }
    
    /**
     * Function to build gateway response for Authorization Transaction
     * The input is the response from gateway
     * It creates and returns AuthGatewayResponse from the HttpResponse
     */
    public override commercepayments.GatewayResponse buildResponse(HttpResponse response){
        String statusCode = String.valueOf(response.getStatusCode());
        //Get the map of key and values from the gateway response using parseResponse()
        Map <String, String> mapOfResponseValues = parseResponse(response.getBody());
        commercepayments.AuthorizationResponse authResponse = new commercepayments.AuthorizationResponse();
        String res_code = null;
        String TRANSACTION_STATUS = mapOfResponseValues.get(TRANSACTION_STATUS);
        String salesforceResultCode = null;
        if(TRANSACTION_STATUS != null){
            if(TRANSACTION_STATUS == APPROVED){
                //Successful gateway response
                res_code = mapOfResponseValues.get(GATEWAY_RESPONSE_CODE);
                salesforceResultCode = SUCCESS_SALESFORCE_RESULT_CODE.name();
                Map<String, Object> refDetails = new Map<String, Object>();
                refDetails.put('transaction_id', mapOfResponseValues.get(TRANSACTION_ID));
                refDetails.put('method', mapOfResponseValues.get(PAYMENT_METHOD));
                String refDetailString = JSON.Serialize(refDetails);
                //Populating successful auth response
                authResponse.setGatewayResultCode(res_code);
                authResponse.setGatewayResultCodeDescription(mapOfResponseValues.get(GATEWAY_MESSAGE));
                authResponse.setGatewayReferenceDetails(refDetailString);
                authResponse.setGatewayReferenceNumber(mapOfResponseValues.get(TRANSACTION_TAG));
            }else{
                //Failed gateway response
                salesforceResultCode = DECLINE_SALESFORCE_RESULT_CODE.name();
                res_code = mapOfResponseValues.get('code');
                String description = mapOfResponseValues.get('description');
                //Populating failed auth response
                if(res_code != null){
                    authResponse.setGatewayResultCode(res_code);
                }else if(mapOfResponseValues.get(VALIDATION_STATUS) != null){
                    authResponse.setGatewayResultCode('Validation Status - failed');
                }else{
                    authResponse.setGatewayResultCode('failed');
                }
                if(description != null){
                    authResponse.setGatewayResultCodeDescription(description);  
                }else{
                    authResponse.setGatewayResultCodeDescription(TRANSACTION_STATUS);
                }
            }
            
            //Gateway Result code mappings provided as custom metadata for the gateway
            if (useCustomMetadata) {
                // If customMetadata is used, fetch the salesforce result code info from the gateway result code mappings
                authResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(res_code));
            } else {
                // Else fetch the salesforce result code info from the salesforce result code set in the method
                authResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(salesforceResultCode));
            }
        }else {
                String message = mapOfResponseValues.get('message') == null? mapOfResponseValues.get('description') :mapOfResponseValues.get('message');
                commercepayments.GatewayErrorResponse error = new commercepayments.GatewayErrorResponse(statusCode, message);
                return error;
        }
        String amountStr = mapOfResponseValues.get('amount');
        if(amountStr != null){
            Double amountDbl = double.valueOf(amountStr);
            //amount is divided by 100 to convert cents to dollars
            authResponse.setAmount(double.valueOf(amountDbl/100.0));
        }
        //Gateway does not send date, assigning the current date for recording purpose
        authResponse.setGatewayDate(system.now());    
        
        commercepayments.PaymentMethodTokenizationResponse paymentMethodTokenizationResponse = new commercepayments.PaymentMethodTokenizationResponse();
        paymentMethodTokenizationResponse.setGatewayToken(mapOfResponseValues.get('value'));
        authResponse.setPaymentMethodTokenizationResponse(paymentMethodTokenizationResponse);
        return authResponse;
    }
    
    /**
     * Function to build request body for Authorization Transaction
     */
    private String buildAuthRequestBody(commercepayments.AuthorizationRequest authRequest) {
        
        String currencyIso = authRequest.currencyIsoCode;
        commercepayments.AuthApiPaymentMethodRequest paymentMethod = authRequest.paymentMethod;
        JSONGenerator jsonGeneratorInstance = JSON.createGenerator(true);
        commercepayments.GatewayErrorResponse error;
        // Write data to the JSON string
        jsonGeneratorInstance.writeStartObject();
        jsonGeneratorInstance.writeStringField('merchant_ref', '');
        jsonGeneratorInstance.writeStringField('transaction_type', 'authorize');
        if(authRequest.amount!=null)
            //Amount is multiplied by 100 as gateway accepts input in cents
            jsonGeneratorInstance.writeStringField('amount', String.ValueOf((authRequest.amount*100.0).intValue()));
        if(currencyIso == null) {
            currencyIso = UserInfo.getDefaultCurrency();
        }
        jsonGeneratorInstance.writeStringField('currency_code', currencyIso);
        if(paymentMethod !=null) {
            if(paymentMethod.id!=null){
                jsonGeneratorInstance.writeStringField('method', 'token');
                Id idToProccess = paymentMethod.id;              
                jsonGeneratorInstance.writeFieldName('token');
                jsonGeneratorInstance.writeStartObject();
                jsonGeneratorInstance.writeStringField('token_type', 'FDToken');
                jsonGeneratorInstance.writeFieldName('token_data');
                jsonGeneratorInstance.writeStartObject();
                if(idToProccess.getSObjectType() == CardPaymentMethod.SObjectType)
                { 
                    CardPaymentMethod cardObject = getCardObjectUsingId(idToProccess);
                    jsonGeneratorInstance.writeObjectField('type', cardObject.CardTypeCategory);
                    jsonGeneratorInstance.writeObjectField('cardholder_name', cardObject.CardHolderName);
                    jsonGeneratorInstance.writeObjectField('value', cardObject.GatewayToken);
                    String expMonth = ((String.ValueOf(cardObject.ExpiryMonth)).length()==1?'0':'') + String.ValueOf(cardObject.ExpiryMonth);
                    jsonGeneratorInstance.writeStringField('exp_date', expMonth+(String.ValueOf(cardObject.ExpiryYear)).substring(2));
                    jsonGeneratorInstance.writeObjectField('special_payment', 'B');
                }
                jsonGeneratorInstance.writeEndObject();
                jsonGeneratorInstance.writeEndObject();
                
            }
            else if(paymentMethod.cardPaymentMethod!=null){
                //get the payment method part of request using buildCardPaymentMethodBody
                String cardRequestBody = buildCardPaymentMethodBody(paymentMethod.cardPaymentMethod);
                Map<String, Object> mapOfJson = (Map<String, Object>) JSON.deserializeUntyped(cardRequestBody);
                String cardCategory = String.ValueOf(mapOfJson.get('method'));
                jsonGeneratorInstance.writeStringField('method', cardCategory);
                jsonGeneratorInstance.writeObjectField(cardCategory, mapOfJson.get(cardCategory));
            }
            else {
                //Add new payment Method here
                throw new PayeezyValidationException('Required Field Missing : CardPaymentMethod');
            }
        } else {
            throw new PayeezyValidationException('Required Field Missing : PaymentMethod');
        }
        jsonGeneratorInstance.writeEndObject();
        return jsonGeneratorInstance.getAsString();
    }

}