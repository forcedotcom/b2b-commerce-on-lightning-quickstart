/**
 * Sale Service class
 */
public class SaleTransactionService extends AbstractTransactionService{

    /**
     * Constructor that sets the gatewayContext for the service
     * The gateway context contains the input request and request type
     */
    public SaleTransactionService(commercepayments.paymentGatewayContext gatewayContext){
        super(gatewayContext);
    }

     /**
      * Build HTTP request for Sale Transaction
     */
    public override HttpRequest buildRequest(){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('/v1/transactions');
        req.setMethod('POST');
        req.setBody(buildSaleRequestBody((commercepayments.SaleRequest)gatewayContext.getPaymentRequest()));
        setAuthorizationHeaders(req);
        return req;
    }

    /**
     * Function to build request body for Sale Transaction
     */
    private String buildSaleRequestBody(commercepayments.SaleRequest saleRequest) {
        JSONGenerator jsonGeneratorInstance = JSON.createGenerator(true);
        // Write data to the JSON string
        jsonGeneratorInstance.writeStartObject();
        jsonGeneratorInstance.writeStringField('merchant_ref', '');
        jsonGeneratorInstance.writeStringField('transaction_type', 'purchase');

        if(saleRequest.amount!=null)
        //Amount is multiplied by 100 as gateway accepts input in cents
        jsonGeneratorInstance.writeStringField('amount', String.ValueOf((saleRequest.amount*100.0).intValue()));

        String currencyIso = saleRequest.currencyIsoCode;
        if(currencyIso == null) {
            currencyIso = UserInfo.getDefaultCurrency();
        }
        jsonGeneratorInstance.writeStringField('currency_code', currencyIso);

        jsonGeneratorInstance.writeStringField('partial_redemption', 'false');

        commercepayments.SaleApiPaymentMethodRequest paymentMethod = saleRequest.paymentMethod;
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


    /**
     * Function to build gateway response for Sale Transaction
     * The input is the response from gateway
     * It creates and returns GatewayResponse from the HttpResponse
     */
     public override commercepayments.GatewayResponse buildResponse(HttpResponse response){
        String statusCode = String.valueOf(response.getStatusCode());
        
        //Get the map of key and values from the gateway response using parseResponse()
        Map <String, String> mapOfResponseValues = parseResponse(response.getBody());
        
        commercepayments.SaleResponse saleResponse = new commercepayments.SaleResponse();
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
                     //Populating successful Sale response
                     saleResponse.setGatewayReferenceDetails(refDetailString);
                     saleResponse.setGatewayResultCode(res_code);
                     saleResponse.setGatewayResultCodeDescription(mapOfResponseValues.get(GATEWAY_MESSAGE));
                     saleResponse.setGatewayReferenceNumber(mapOfResponseValues.get(TRANSACTION_TAG));
                 }else{
                     //Failed gateway response
                     salesforceResultCode= DECLINE_SALESFORCE_RESULT_CODE.name();
                     res_code = mapOfResponseValues.get('code');
                     String description = mapOfResponseValues.get('description');
                     //Populating failed Sale response
                     if(res_code != null){
                         saleResponse.setGatewayResultCode(res_code);
                     }else if(mapOfResponseValues.get(VALIDATION_STATUS) != null){
                         saleResponse.setGatewayResultCode('Validation Status - failed');
                     }else{
                         saleResponse.setGatewayResultCode('failed');
                     }
                     if(description != null){
                         saleResponse.setGatewayResultCodeDescription(description);
                     }else{
                         saleResponse.setGatewayResultCodeDescription(TRANSACTION_STATUS);
                     }
                 }

                 //Gateway Result code mappings provided as custom metadata for the gateway
                 if (useCustomMetadata) {
                     // If customMetadata is used, fetch the salesforce result code info from the gateway result code mappings
                     saleResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(res_code));
                 } else {
                     // Else fetch the salesforce result code info from the salesforce result code set in the method
                     saleResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(salesforceResultCode));
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
                 saleResponse.setAmount(double.valueOf(amountDbl/100.0));
             }
             //Gateway does not send date, assigning the current date for recording purpose
             saleResponse.setGatewayDate(system.now());

             commercepayments.PaymentMethodTokenizationResponse paymentMethodTokenizationResponse = new commercepayments.PaymentMethodTokenizationResponse();
             paymentMethodTokenizationResponse.setGatewayToken(mapOfResponseValues.get('value'));
             saleResponse.setPaymentMethodTokenizationResponse(paymentMethodTokenizationResponse);

             return saleResponse;
         }

}