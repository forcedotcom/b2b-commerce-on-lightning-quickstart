/**
 * Referenced Refund Service class
 */ 
public class ReferencedRefundTransactionService extends AbstractTransactionService{
    
    /**
     * Constructor that sets the gatewayContext for the service
     */ 
    public ReferencedRefundTransactionService(commercepayments.paymentGatewayContext gatewayContext){
        super(gatewayContext);
    }
    
    /**
     * Method to build request for Referenced Refund Transaction
     * Creates a new request and sets request body, authorization parameters and other related fields
     */ 
    public override HttpRequest buildRequest(){
        HttpRequest req = new HttpRequest();
        //The rest of the endpoint is set in the buildRefRefundRequestBody
        req.setEndpoint('/v1/transactions/');
        req.setMethod('POST');
        req.setBody(buildRefRefundRequestBody((commercepayments.ReferencedRefundRequest)gatewayContext.getPaymentRequest(),req));
        setAuthorizationHeaders(req);
        return req; 
    }
    
    /**
     * Function to build gateway response for Referenced Refund Transaction
     * The input is the response from gateway
     * It creates and returns CptureGatewayResponse from the HttpResponse
     */
    public override commercepayments.GatewayResponse buildResponse(HttpResponse response){
        String statusCode = String.valueOf(response.getStatusCode());
        Map <String, String> mapOfResponseValues = parseResponse(response.getBody());
        commercepayments.ReferencedRefundResponse refundResponse = new commercepayments.ReferencedRefundResponse();
        String res_code = mapOfResponseValues.get(GATEWAY_RESPONSE_CODE);
        String salesforceResultCode = null;
        String TRANSACTION_STATUS = mapOfResponseValues.get(TRANSACTION_STATUS);
        if(TRANSACTION_STATUS != null){
            if(TRANSACTION_STATUS == APPROVED){
                //Successful gateway response
                salesforceResultCode = SUCCESS_SALESFORCE_RESULT_CODE.name();
                Map<String, Object> refDetails = new Map<String, Object>();
                refDetails.put('transaction_id', mapOfResponseValues.get(TRANSACTION_ID));
                refDetails.put('method', mapOfResponseValues.get(PAYMENT_METHOD));
                String refDetailString = JSON.Serialize(refDetails);
                //Populating successful refund response
                refundResponse.setGatewayResultCode(res_code);
                refundResponse.setGatewayResultCodeDescription(mapOfResponseValues.get(GATEWAY_MESSAGE));
                refundResponse.setGatewayReferenceDetails(refDetailString);
                refundResponse.setGatewayReferenceNumber(mapOfResponseValues.get(TRANSACTION_TAG)); 
            }else{
                //Failed gateway response
                salesforceResultCode = DECLINE_SALESFORCE_RESULT_CODE.name();
                String code = mapOfResponseValues.get('code');
                String description = mapOfResponseValues.get('description');
                //Populating failed refund response
                if(code != null){
                    refundResponse.setGatewayResultCode(code);
                }else if(mapOfResponseValues.get(VALIDATION_STATUS) != null){
                    refundResponse.setGatewayResultCode('Validation Status - failed');
                }else{
                    refundResponse.setGatewayResultCode('failed');
                }
                if(description != null){
                    refundResponse.setGatewayResultCodeDescription(description);    
                }else{
                    refundResponse.setGatewayResultCodeDescription(TRANSACTION_STATUS);
                }
            }
            
            //Gateway Result code mappings provided as custom metadata for the gateway
            if (useCustomMetadata) {
                // If customMetadata is used, fetch the salesforce result code info from the gateway result code mappings
                refundResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(res_code));
            } else {
                // Else fetch the salesforce result code info from the salesforce result code set in the method
                refundResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(salesforceResultCode));
            }
        }else {
                String message = mapOfResponseValues.get('message') == null? mapOfResponseValues.get('description') :mapOfResponseValues.get('message');
                commercepayments.GatewayErrorResponse error = new commercepayments.GatewayErrorResponse(statusCode, message);
                return error;
        }
        String amountStr = mapOfResponseValues.get('amount');
        if(amountStr != null){
            Double amountDbl = double.valueOf(amountStr);
            refundResponse.setAmount(double.valueOf(amountDbl/100.0));
        }
        //Gateway does not send date, assigning the current date for recording purpose
        refundResponse.setGatewayDate(system.now());
        return refundResponse;
    }
    
    /**
     * Function to build request body for Referenced Refund Transaction
     */
    private String buildRefRefundRequestBody(commercepayments.ReferencedRefundRequest refundRequest,HttpRequest req) {
        Boolean IS_MULTICURRENCY_ORG = UserInfo.isMultiCurrencyOrganization();
        //Get the payment object with all the required fields
        Payment paymentObject = getPaymentObjectForRefund(refundRequest.paymentId,IS_MULTICURRENCY_ORG);
        String transactionId,method;
        try {
                Map<String, Object> refDetailsMap = (Map<String, Object>) JSON.deserializeUntyped(paymentObject.GatewayRefDetails);
                transactionId = (String)refDetailsMap.get('transaction_id');
            		method = (String)refDetailsMap.get('method');
            } catch(Exception e) {}
        req.setEndpoint(req.getEndpoint() + transactionId);
        // Write data to the JSON string.
        JSONGenerator jsonGeneratorInstance = JSON.createGenerator(true);
        jsonGeneratorInstance.writeStartObject();
        jsonGeneratorInstance.writeStringField('merchant_ref', '');
        jsonGeneratorInstance.writeStringField('transaction_type', 'refund');
        jsonGeneratorInstance.writeStringField('transaction_tag', paymentObject.GatewayRefNumber);
        if (refundRequest.amount != null)
            jsonGeneratorInstance.writeStringField('amount', String.ValueOf((refundRequest.amount*100.0).intValue()));
        if (IS_MULTICURRENCY_ORG) {
            jsonGeneratorInstance.writeStringField('currency_code', paymentObject.get('CurrencyIsoCode').toString());
        } else {
            jsonGeneratorInstance.writeStringField('currency_code', UserInfo.getDefaultCurrency());
        }
        jsonGeneratorInstance.writeStringField('method', method);
        jsonGeneratorInstance.writeEndObject();
        return jsonGeneratorInstance.getAsString(); 
    }
    
    /**
     * Get the payment record with all the required fields 
     * Database call from apex done to fetch the record
     */ 
    private Payment getPaymentObjectForRefund(String paymentId, Boolean IS_MULTICURRENCY_ORG){
        List<String> listOfFields = new List<String>();
        listOfFields.add('GatewayRefNumber');
        listOfFields.add('GatewayRefDetails');
        if (IS_MULTICURRENCY_ORG) {
            // currency of payment required if org is multi currency
            listOfFields.add('CurrencyIsoCode');
        }
        //Fetch the payment record using the Payment Id
        Payment paymentObject = (Payment)DaoService.getSobjectById(paymentId, listOfFields, Payment.SObjectType);
        return paymentObject;
    }
}