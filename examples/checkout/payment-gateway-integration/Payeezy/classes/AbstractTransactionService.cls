/**
 * Abstract class for all transaction service classes,
 * contains common methods for all service classes
 *
 * Every service class should extend the AbstractTransactionService
 */
public abstract class AbstractTransactionService {

    private static final String STATUS = 'status';
    private static final String TYPE = 'type';
	protected final String BANK_MESSAGE = 'bank_message';
    protected final String VALIDATION_STATUS = 'validation_status';
    protected final String TRANSACTION_STATUS = 'transaction_status';
    protected final String BANK_RESPONSE_CODE = 'bank_resp_code';
    protected final String TRANSACTION_ID = 'transaction_id';
    protected final String TRANSACTION_TAG = 'transaction_tag';
    protected final String GATEWAY_RESPONSE_CODE = 'gateway_resp_code';
    protected final String GATEWAY_MESSAGE = 'gateway_message';
    protected final String PAYMENT_METHOD = 'method';
    protected final String AMOUNT = 'amount';
    protected final String CURRENCY_KEY = 'currency';
    protected final String APPROVED = 'approved';
    protected final commercepayments.SalesforceResultCode SUCCESS_SALESFORCE_RESULT_CODE =
             commercepayments.SalesforceResultCode.SUCCESS;
    protected final commercepayments.SalesforceResultCode DECLINE_SALESFORCE_RESULT_CODE =
             commercepayments.SalesforceResultCode.DECLINE;
    //See getSalesforceResultCodeInfo() for explanation
    protected boolean useCustomMetadata = false;

    protected commercepayments.paymentGatewayContext gatewayContext;

    /**
     * Constructor that sets the gatewayContext for all the services
     */
    public AbstractTransactionService(commercepayments.paymentGatewayContext gatewayContext){
            this.gatewayContext= gatewayContext;
    }

    /**
     * Abstract function to build request for a Transaction
     * Creates a new request and set request body, authorization parameters and other related fields
     */
    public abstract HttpRequest buildRequest();

    /**
     * Abstract function to build gateway response for a Transaction
     * The input is the response from gateway
     * It creates and returns GatewayResponse from the HttpResponse
     */
    public abstract commercepayments.GatewayResponse buildResponse(HttpResponse response);

    /**
     * Function to process transaction requests
     * Steps involved are:
     * 1. Build HttpRequest with the input Request from gateway context
     * 2. Send request and get the response from gateway
     * 3. Parse the response from gateway and return GatewayResponse
     */
    public commercepayments.GatewayResponse execute(){
                HttpRequest req;
        try{
            //Building a new request
            req = buildRequest();
        } catch(PayeezyValidationException e) {
            return getValidationExceptionError(e);
        }
        commercepayments.PaymentsHttp http = new commercepayments.PaymentsHttp();
        HttpResponse res = null;
        try{
            //Sending the request
            res = http.send(req);
        } catch(CalloutException ce) {
            return getCalloutExceptionError(ce);
        }
        try{
            //Parsing the response from gateway
            return buildResponse(res);
        } catch(Exception e) {
            return getParseExceptionError(e);
        }
    }

    /**
     * Function to set authorization headers in a request
     * Use this to add authorization parameters required for the request
     */
    protected void setAuthorizationHeaders(HttpRequest req){
        req.setHeader('Content-Type', 'application/json');
        //Username and password stored in the named credential that is linked with the payment gateway record
        req.setHeader('apikey', '{!$Credential.Username}');
        req.setHeader('token', '{!$Credential.Password}');
    }

    /**
     * Function to build request body for Card Payment Method
     * The string returned contains
     * 1. Payment method name under the key 'method'
     * 2. Payment method details as JSON object under the key 'payment method name', eg: 'credit_card'
     */
    protected String buildCardPaymentMethodBody(commercepayments.CardPaymentMethodRequest cardPaymentMethod) {
        JSONGenerator jsonGeneratorInstance = JSON.createGenerator(true);
        jsonGeneratorInstance.writeStartObject();
        if (cardPaymentMethod!=null){
                if (cardPaymentMethod.CardCategory!=null){
                    if (commercepayments.CardCategory.CreditCard == cardPaymentMethod.CardCategory) {
                        jsonGeneratorInstance.writeStringField('method', 'credit_card');
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
                    } else{
                    //Support for other card type
                    throw new PayeezyValidationException('Unsupported category of Card');
                    }
                } else{
                    throw new PayeezyValidationException('Required Field Missing : CardCategory');
                }
            } else {
                throw new PayeezyValidationException('Required Field Missing : CardPaymentMethod');
            }
        jsonGeneratorInstance.writeEndObject();
        return jsonGeneratorInstance.getAsString();
    }

    /**
     * Function to parse the gateway response
     * The input is the response from gateway
     * It returns map of all the key and values for all successful and error responses
     */
    protected Map<String, String> parseResponse(String jsonResponse) {
        Map<String, String> mapOfResponseValuesByKey = new Map<String, String>();
        if (NULL != jsonresponse) {
            Map<String, Object> mapOfjsonResponseByKey = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            // Amount key added to the map irrespective of the response received
            if(mapOfjsonResponseByKey.get(AMOUNT) != null)
                mapOfResponseValuesByKey.put(AMOUNT, String.ValueOf(mapOfjsonResponseByKey.get(AMOUNT)));
            if (mapOfjsonResponseByKey.KeySet().contains(BANK_MESSAGE) || mapOfjsonResponseByKey.KeySet().contains(GATEWAY_MESSAGE)
               || mapOfjsonResponseByKey.KeySet().contains(STATUS)) {
                //Successful transaction with the gateway
                for (String resultKey : mapOfjsonResponseByKey.KeySet()) {
                    if (resultKey == BANK_MESSAGE
                        || resultKey == TRANSACTION_ID
                        || resultKey == BANK_RESPONSE_CODE
                        || resultKey == TRANSACTION_TAG
                        || resultKey == GATEWAY_RESPONSE_CODE
                        || resultKey == GATEWAY_MESSAGE
                        || resultKey == CURRENCY_KEY
                        || resultKey == TRANSACTION_STATUS
                        || resultKey == VALIDATION_STATUS
                        || resultKey == PAYMENT_METHOD
                        || resultKey == STATUS
                        || resultKey == TYPE
                       ) {
                           mapOfResponseValuesByKey.put(resultKey, String.ValueOf(mapOfjsonResponseByKey.get(resultKey)));
                       }
                }
                mapOfResponseValuesByKey.put('gatewayTokenDetails', String.ValueOf(mapOfjsonResponseByKey.get(TYPE)));
                //Token values stored for the payment method used
                if (mapOfjsonResponseByKey.containsKey('token')) {
                    Map<String, Object> mapOfTokenByChild = (Map
                                                             <String, Object>) mapOfjsonResponseByKey.get('token');
                    mapOfResponseValuesByKey.put('type', String.ValueOf(mapOfTokenByChild.get('type')));
                    mapOfResponseValuesByKey.put('cardholder_name', String.ValueOf(mapOfTokenByChild.get('cardholder_name')));
                    mapOfResponseValuesByKey.put('exp_date', String.ValueOf(mapOfTokenByChild.get('exp_date')));
                    mapOfResponseValuesByKey.put('value', String.ValueOf(mapOfTokenByChild.get('value')));
                    Map<String, Object> mapOfTokenData = (Map<String, Object>) mapOfTokenByChild.get('token_data');
                    if(mapOfTokenData != null){
                        for (String tokenData : mapOfTokenData.KeySet()) {
                        mapOfResponseValuesByKey.put(tokenData, String.ValueOf(mapOfTokenData.get(tokenData)));
                    }
                    }
                }
            }  
            if (jsonresponse.contains('Error')) {
                // Failed transaction with the gateway
                for (String resultKey : mapOfjsonResponseByKey.KeySet()) {
                    if (resultKey != 'Error') {
                        mapOfResponseValuesByKey.put(resultKey, String.ValueOf(mapOfjsonResponseByKey.get(resultKey)));
                    }
                }
                Map<String, Object> mapOfErrors = (Map
                                                   <String, Object>) mapOfjsonResponseByKey.get('Error');
                for (String resultErrorKey : mapOfErrors.KeySet()) {
                    mapOfResponseValuesByKey.put(resultErrorKey, String.ValueOf(mapOfErrors.get(resultErrorKey)));
                }

                list<Object> listofError = (list<object>) mapOfErrors.get('messages');

                for (Object objectRef : listofError) {
                    Map<String, Object> mapOfErrorsByChild = (Map<String, Object>) objectRef;
                    for (String errorResult : mapOfErrorsByChild.KeySet()) {
                        mapOfResponseValuesByKey.put(errorResult, String.ValueOf(mapOfErrorsByChild.get(errorResult)));
                    }
                }
            } else if (jsonresponse.contains('error')) {
                // Failed transaction with the gateway
                mapOfResponseValuesByKey.put('failed', String.ValueOf(mapOfjsonResponseByKey.get('error')));
            } else if (jsonresponse.contains('code')) {
                // The error code and error response received in the output
                String code = (string)mapOfjsonResponseByKey.get('code');
                String message = (string)mapOfjsonResponseByKey.get('message');
                mapOfResponseValuesByKey.put('code',code);
                mapOfResponseValuesByKey.put('message',message);
            }
        }
        return mapOfResponseValuesByKey;
    }

    /**
     * Get the CardPaymentMethod record with all the required fields
     * Database call from apex done to fetch the record
     */
     protected CardPaymentMethod getCardObjectUsingId(String paymentMethodId){
         List<String> listOfFields = new List<String>();
         listOfFields.add('CardTypeCategory');
         listOfFields.add('CardHolderName');
         listOfFields.add('ExpiryYear');
         listOfFields.add('ExpiryMonth');
         listOfFields.add('GatewayToken');

         //Fetch the card payment method
         return (CardPaymentMethod)DaoService.getSobjectById(paymentMethodId, listOfFields, CardPaymentMethod.SObjectType);
     }

    /**
	* Function to get Salesforce Result Code Info
	*
	* @see https://help.salesforce.com/articleView?id=custommetadatatypes_about.htm
	* @see SalesforceResultCodeInfo
	* @see CustomMetadataTypeInfo
	* @see SalesforceResultCode
	*
	* The managed package must create and maintain a Custom Metadata Type with the mappings of Gateway Result Codes and Salesforce Result Codes.
	* This adapter implementation does not use custom metadata and returns hardcoded salesforceResultCodeInfo
	* see getSalesforceResultCodeInfo(AbstractTransactionAdapter.apex) in PayeezyAdapter_CustomMetadata
	*
	*/
    protected commercepayments.SalesforceResultCodeInfo getSalesforceResultCodeInfo(String resultCode) {
        if (resultCode == SUCCESS_SALESFORCE_RESULT_CODE.name()) {
            return new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Success);
        } else {
            return new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Decline);
        }
    }
    /**
     * Function to get error response for Validation Exception
     */
    private commercepayments.GatewayErrorResponse getValidationExceptionError(Exception e){
        return new commercepayments.GatewayErrorResponse('400', e.getMessage());
    }

    /**
     * Function to get error response for Parse Exception
     */
    private commercepayments.GatewayErrorResponse getParseExceptionError(Exception e){
        return new commercepayments.GatewayErrorResponse('400', 'Something went wrong in the Gateway Adapter : ' + e.getMessage());
    }

     /**
     * Function to get error response for Callout Exception
     */
    private commercepayments.GatewayErrorResponse getCalloutExceptionError(CalloutException ce){
        return new commercepayments.GatewayErrorResponse('500', ce.getMessage());
    }
}