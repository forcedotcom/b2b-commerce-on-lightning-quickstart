global virtual class PayeezyAdapter implements commercepayments.PaymentGatewayAdapter {
    private static final String BANK_MESSAGE = 'bank_message';
    private static final String VALIDATION_STATUS = 'validation_status';
    private static final String TRANSACTION_STATUS = 'transaction_status';
    private static final String STATUS = 'status';
    private static final String BANK_RESPONSE_CODE = 'bank_resp_code';
    private static final String TRANSACTION_ID = 'transaction_id';
    private static final String TRANSACTION_TAG = 'transaction_tag';
    private static final String GATEWAY_RESPONSE_CODE = 'gateway_resp_code';
    private static final String GATEWAY_MESSAGE = 'gateway_message';
    private static final String AMOUNT = 'amount';
    private static final String CURRENCY_KEY = 'currency';
    protected final String PAYMENT_METHOD = 'method';
    private static final String APPROVED = 'approved';
    private static final String TYPE = 'type';
    private static final String TOKEN = 'token';
    private static final commercepayments.SalesforceResultCodeInfo SUCCESS_SALESFORCE_RESULT_CODE_INFO =
            new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Success);
    private static final commercepayments.SalesforceResultCodeInfo DECLINE_SALESFORCE_RESULT_CODE_INFO =
            new commercepayments.SalesforceResultCodeInfo(commercepayments.SalesforceResultCode.Decline);
    protected boolean useCustomMetadata = false;

    global PayeezyAdapter() {}


    global commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext) {
        commercepayments.RequestType requestType = gatewayContext.getPaymentRequestType();
        Boolean isDone = false;
        commercepayments.GatewayResponse response;
        String body = null;

        HttpRequest req = new HttpRequest();

        req.setHeader('Content-Type', 'application/json');
        req.setHeader('apikey', '{!$Credential.Username}');
        req.setHeader('token', '{!$Credential.Password}');

        try
        {
            if (requestType == commercepayments.RequestType.Authorize) {
                body = buildAuthRequest((commercepayments.AuthorizationRequest)gatewayContext.getPaymentRequest());
                req.setEndpoint('/v1/transactions');
            } else if ( requestType == commercepayments.RequestType.Capture) {
                    body = buildCaptureRequest((commercepayments.CaptureRequest)gatewayContext.getPaymentRequest(),req);
            } else if ( requestType == commercepayments.RequestType.ReferencedRefund) {
                    body = buildReferencedRefundRequest((commercepayments.ReferencedRefundRequest)gatewayContext.getPaymentRequest(),req);
            } else if ( requestType == commercepayments.RequestType.Tokenize) {
                    req.setEndpoint('/v1/transactions/tokens');
                    body = buildTokenizeRequest((commercepayments.PaymentMethodTokenizationRequest)gatewayContext.getPaymentRequest());
            } else if ( requestType == commercepayments.RequestType.Sale){
                    req.setEndpoint('/v1/transactions');
                    body = buildSaleRequest((commercepayments.SaleRequest)gatewayContext.getPaymentRequest());
            }
            else {
                    commercepayments.GatewayErrorResponse error = new commercepayments.GatewayErrorResponse('501','Unsupported Operation');
                    return error;
            }

        } catch(PayeezyValidationException e) {
            commercepayments.GatewayErrorResponse error = new commercepayments.GatewayErrorResponse('400', e.getMessage());
            return error;
        }
        req.setBody(body);
            req.setMethod('POST');

        commercepayments.PaymentsHttp http = new commercepayments.PaymentsHttp();
        HttpResponse res = null;

        try{
            res = http.send(req);
        } catch(CalloutException ce) {
            commercepayments.GatewayErrorResponse error = new commercepayments.GatewayErrorResponse('500', ce.getMessage());
            return error;
        }

        //handle isDone
        if (requestType == commercepayments.RequestType.Authorize) {
            response = createAuthResponse(res);
        } else if ( requestType == commercepayments.RequestType.Capture) {
            response =  createCaptureResponse(res) ;
        } else if ( requestType == commercepayments.RequestType.ReferencedRefund) {
            response =  createReferencedRefundResponse(res) ;
        }else if ( requestType == commercepayments.RequestType.Tokenize) {
            response =  createTokenizeResponse(res) ;
        } else if( requestType == commercepayments.RequestType.Sale){
           response = createSaleResponse(res);
        }
        return response;
    }

    public commercepayments.GatewayResponse createTokenizeResponse(HttpResponse response) {
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
                system.debug('Ravi -> ' + mapOfResponseValues);
                tokenizeResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(commercepayments.SalesforceResultCode.DECLINE.name()));
                String description = mapOfResponseValues.get('description');
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

    private String buildTokenizeRequest(commercepayments.PaymentMethodTokenizationRequest tokenizeRequest) {
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

    public String buildCaptureRequest(commercepayments.CaptureRequest captureRequest,HttpRequest req) {
        Boolean IS_MULTICURRENCY_ORG = UserInfo.isMultiCurrencyOrganization();
        QueryUtils qBuilderForAuth = new QueryUtils(PaymentAuthorization.SObjectType);
        // Add required fields
        qBuilderForAuth.getSelectClause().addField('GatewayAuthCode', false);
        qBuilderForAuth.getSelectClause().addField('GatewayRefNumber', false);
        qBuilderForAuth.getSelectClause().addField('GatewayRefDetails', false);
        if (IS_MULTICURRENCY_ORG) {
            // addField also takes a boolean to enable translation (uses label instead of actual value)
            qBuilderForAuth.getSelectClause().addField('CurrencyIsoCode', false);
        }
        qBuilderForAuth.setWhereClause(' WHERE Id =' + '\'' + captureRequest.paymentAuthorizationId + '\'');
        PaymentAuthorization authObject = (PaymentAuthorization)Database.query(qBuilderForAuth.buildSOQL())[0];

        String refDetails = authObject.GatewayRefDetails;
        try {
            Map<String, Object> refDetailsMap = (Map<String, Object>) JSON.deserializeUntyped(refDetails);
            refDetails = (String)refDetailsMap.get('transaction_id');
        } catch(Exception e) {}

        req.setEndpoint('/v1/transactions/' + refDetails);

        JSONGenerator jsonGeneratorInstance = JSON.createGenerator(true);
        jsonGeneratorInstance.writeStartObject();
        jsonGeneratorInstance.writeStringField('merchant_ref', 'Astonishing-Sale');
        jsonGeneratorInstance.writeStringField('transaction_type', 'capture');
        jsonGeneratorInstance.writeStringField('transaction_tag', authObject.GatewayRefNumber);
        if (captureRequest.amount != null)
            jsonGeneratorInstance.writeStringField('amount', String.ValueOf((captureRequest.amount*100.0).intValue()));
        if (IS_MULTICURRENCY_ORG) {
            jsonGeneratorInstance.writeStringField('currency_code', authObject.get('CurrencyIsoCode').toString());
        } else {
            jsonGeneratorInstance.writeStringField('currency_code', UserInfo.getDefaultCurrency());
        }
        jsonGeneratorInstance.writeStringField('method', 'credit_card');
        jsonGeneratorInstance.writeEndObject();
        return jsonGeneratorInstance.getAsString();
    }

    private String buildAuthRequest(commercepayments.AuthorizationRequest authRequest) {
        JSONGenerator jsonGeneratorInstance = JSON.createGenerator(true);
        commercepayments.GatewayErrorResponse error;
        // Write data to the JSON string.
        String amount = String.ValueOf((authRequest.amount*100.0).intValue());
        String currencyIso = authRequest.currencyIsoCode;
        jsonGeneratorInstance.writeStartObject();
        jsonGeneratorInstance.writeStringField('merchant_ref', '');
        jsonGeneratorInstance.writeStringField('transaction_type', 'authorize');
            jsonGeneratorInstance.writeStringField('amount', amount);
        if(currencyIso == null) {
            currencyIso = UserInfo.getDefaultCurrency();
        }
        jsonGeneratorInstance.writeStringField('currency_code',currencyIso);
        commercepayments.AuthApiPaymentMethodRequest paymentMethod = authRequest.paymentMethod;
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
                        QueryUtils qBuilder = new QueryUtils(CardPaymentMethod.SObjectType);
                        // Add required fields
                        qBuilder.getSelectClause().addField('CardTypeCategory', false);
                        qBuilder.getSelectClause().addField('CardHolderName', false);
                        qBuilder.getSelectClause().addField('GatewayToken', false);
                        qBuilder.getSelectClause().addField('ExpiryMonth', false);
                        qBuilder.getSelectClause().addField('ExpiryYear', false);
                        qBuilder.setWhereClause(' WHERE Id =' + '\'' + paymentMethod.id + '\'');
                        CardPaymentMethod cardObject = (CardPaymentMethod)Database.query(qBuilder.buildSOQL())[0];

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
                   commercepayments.CardPaymentMethodRequest cardPaymentMethod = paymentMethod.cardPaymentMethod;
                    if(cardPaymentMethod != null){
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
                               }
                          }
                         else{
                              throw new PayeezyValidationException('Required Field Missing : CardCategory');
                         }
                    } else{
                        //Add new payment Method here
                        throw new PayeezyValidationException('Required Field Missing : CardPaymentMethod');
                    }
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

    public String buildReferencedRefundRequest(commercepayments.ReferencedRefundRequest refundRequest,HttpRequest req) {

        Boolean IS_MULTICURRENCY_ORG = UserInfo.isMultiCurrencyOrganization();
        QueryUtils qBuilderForPayment = new QueryUtils(Payment.SObjectType);
        // Add required fields
        qBuilderForPayment.getSelectClause().addField('GatewayRefNumber', false);
        qBuilderForPayment.getSelectClause().addField('GatewayRefDetails', false);
        if (IS_MULTICURRENCY_ORG) {
            // addField also takes a boolean to enable translation (uses label instead of actual value)
                qBuilderForPayment.getSelectClause().addField('CurrencyIsoCode', false);
            }
        qBuilderForPayment.setWhereClause(' WHERE Id =' + '\'' + refundRequest.paymentId + '\'');
        Payment paymentObject = (Payment)Database.query(qBuilderForPayment.buildSOQL())[0];

        String refDetails = paymentObject.GatewayRefDetails;
        try {
                Map<String, Object> refDetailsMap = (Map<String, Object>) JSON.deserializeUntyped(refDetails);
                refDetails = (String)refDetailsMap.get('transaction_id');
            } catch(Exception e) {
            }

        req.setEndpoint('/v1/transactions/' + refDetails);

        JSONGenerator jsonGeneratorInstance = JSON.createGenerator(true);
        jsonGeneratorInstance.writeStartObject();
        jsonGeneratorInstance.writeStringField('merchant_ref', 'Astonishing-Sale');
        jsonGeneratorInstance.writeStringField('transaction_type', 'refund');
        jsonGeneratorInstance.writeStringField('transaction_tag', paymentObject.GatewayRefNumber);
        if (refundRequest.amount != null)
            jsonGeneratorInstance.writeStringField('amount', String.ValueOf((refundRequest.amount*100.0).intValue()));
        if (IS_MULTICURRENCY_ORG) {
            jsonGeneratorInstance.writeStringField('currency_code', paymentObject.get('CurrencyIsoCode').toString());
        } else {
            jsonGeneratorInstance.writeStringField('currency_code', UserInfo.getDefaultCurrency());
        }
        jsonGeneratorInstance.writeStringField('method', 'credit_card');
        jsonGeneratorInstance.writeEndObject();
        return jsonGeneratorInstance.getAsString();
    }

    public String buildSaleRequest(commercepayments.SaleRequest saleRequest){
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
                        QueryUtils qBuilder = new QueryUtils(CardPaymentMethod.SObjectType);
                        // Add required fields
                        qBuilder.getSelectClause().addField('CardTypeCategory', false);
                        qBuilder.getSelectClause().addField('CardHolderName', false);
                        qBuilder.getSelectClause().addField('GatewayToken', false);
                        qBuilder.getSelectClause().addField('ExpiryMonth', false);
                        qBuilder.getSelectClause().addField('ExpiryYear', false);
                        qBuilder.setWhereClause(' WHERE Id =' + '\'' + saleRequest.paymentMethod.id + '\'');
                        CardPaymentMethod cardObject = (CardPaymentMethod)Database.query(qBuilder.buildSOQL())[0];

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
                   commercepayments.CardPaymentMethodRequest cardPaymentMethod = paymentMethod.cardPaymentMethod;
                    if(cardPaymentMethod != null){
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
                               }
                          }
                         else{
                              throw new PayeezyValidationException('Required Field Missing : CardCategory');
                         }
                    } else{
                        //Add new payment Method here
                        throw new PayeezyValidationException('Required Field Missing : CardPaymentMethod');
                    }
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

    public commercepayments.GatewayResponse createAuthResponse(HttpResponse response) {
        String statusCode = String.valueOf(response.getStatusCode());
        Map <String, String> mapOfResponseValues = parseResponse(response.getBody());
        commercepayments.AuthorizationResponse authResponse = new commercepayments.AuthorizationResponse();
        String res_code = null;
        String TRANSACTION_STATUS = mapOfResponseValues.get(TRANSACTION_STATUS);
        String STATUS = mapOfResponseValues.get(STATUS);
        String salesforceResultCode = null;
        if(TRANSACTION_STATUS != null){
            if(TRANSACTION_STATUS == APPROVED){
                system.debug('Response - success');
                res_code = mapOfResponseValues.get(GATEWAY_RESPONSE_CODE);
                salesforceResultCode = commercepayments.SalesforceResultCode.SUCCESS.name();
                authResponse.setGatewayResultCode(res_code);
                authResponse.setGatewayResultCodeDescription(mapOfResponseValues.get(GATEWAY_MESSAGE));

                Map<String, Object> refDetails = new Map<String, Object>();
                refDetails.put('transaction_id', mapOfResponseValues.get(TRANSACTION_ID));
                String refDetailString = JSON.Serialize(refDetails);
                authResponse.setGatewayReferenceDetails(refDetailString);
                authResponse.setGatewayReferenceNumber(mapOfResponseValues.get(TRANSACTION_TAG));
                setAuthExpirationDate(authResponse);
                system.debug('transaction details '+ refDetailString);
                system.debug('transaction tag '+  mapOfResponseValues.get(TRANSACTION_TAG));
            }else{
                system.debug('Response - failed');
                salesforceResultCode = commercepayments.SalesforceResultCode.DECLINE.name();
                res_code = mapOfResponseValues.get('code');
                String description = mapOfResponseValues.get('description');
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
            // As custom metadata ftests are relying only on authorization requests we have this conditional code only here
            if (useCustomMetadata) {
                authResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(res_code));
            } else {
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
            authResponse.setAmount(double.valueOf(amountDbl/100.0));
        }
        authResponse.setGatewayDate(system.now());    //Gateway does not send date, assigning for test

        commercepayments.PaymentMethodTokenizationResponse paymentMethodTokenizationResponse = new commercepayments.PaymentMethodTokenizationResponse();
        paymentMethodTokenizationResponse.setGatewayToken(mapOfResponseValues.get('value'));
        authResponse.setPaymentMethodTokenizationResponse(paymentMethodTokenizationResponse);
        return authResponse;
    }

    public commercepayments.GatewayResponse createCaptureResponse(HttpResponse response) {
        String statusCode = String.valueOf(response.getStatusCode());
        Map <String, String> mapOfResponseValues = parseResponse(response.getBody());
        commercepayments.CaptureResponse captureResponse = new commercepayments.CaptureResponse();
        String res_code = mapOfResponseValues.get(GATEWAY_RESPONSE_CODE);
        String TRANSACTION_STATUS = mapOfResponseValues.get(TRANSACTION_STATUS);
        if(TRANSACTION_STATUS != null){
            if(TRANSACTION_STATUS == APPROVED){
                system.debug('Response - success - '+ TRANSACTION_STATUS);
                captureResponse.setGatewayResultCode(res_code);
                captureResponse.setGatewayResultCodeDescription(mapOfResponseValues.get(GATEWAY_MESSAGE));
                captureResponse.setGatewayReferenceNumber(mapOfResponseValues.get(TRANSACTION_TAG));
                captureResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(commercepayments.SalesforceResultCode.SUCCESS.name()));
                Map<String, Object> refDetails = new Map<String, Object>();
                refDetails.put('transaction_id', mapOfResponseValues.get(TRANSACTION_ID));
                String refDetailString = JSON.Serialize(refDetails);
                captureResponse.setGatewayReferenceDetails(refDetailString);
            }else{
                system.debug('Response - failed '+ TRANSACTION_STATUS);
                captureResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(commercepayments.SalesforceResultCode.DECLINE.name()));
                String code = mapOfResponseValues.get('code');
                String description = mapOfResponseValues.get('description');
                if(code != null){
                    captureResponse.setGatewayResultCode(code);
                }else if(mapOfResponseValues.get(VALIDATION_STATUS) != null){
                    captureResponse.setGatewayResultCode('Validation Status - failed');
                }else{
                    captureResponse.setGatewayResultCode('failed');
                }
                if(description != null){
                    captureResponse.setGatewayResultCodeDescription(description);
                }else{
                    captureResponse.setGatewayResultCodeDescription(TRANSACTION_STATUS);
                }
            }
        }else {
                String message = mapOfResponseValues.get('message') == null? mapOfResponseValues.get('description') :mapOfResponseValues.get('message');
                commercepayments.GatewayErrorResponse error = new commercepayments.GatewayErrorResponse(statusCode, message);
                return error;
        }
        String amountStr = mapOfResponseValues.get('amount');
        if(amountStr != null){
            Double amountDbl = double.valueOf(amountStr);
            captureResponse.setAmount(double.valueOf(amountDbl/100.0));
        }
        captureResponse.setGatewayDate(system.now());    //Gateway does not send date, assigning for test
        return captureResponse;
    }

    public commercepayments.GatewayResponse createReferencedRefundResponse(HttpResponse response) {
        String statusCode = String.valueOf(response.getStatusCode());
        Map <String, String> mapOfResponseValues = parseResponse(response.getBody());
        commercepayments.ReferencedRefundResponse refundResponse = new commercepayments.ReferencedRefundResponse();
        String res_code = mapOfResponseValues.get(GATEWAY_RESPONSE_CODE);
        String TRANSACTION_STATUS = mapOfResponseValues.get(TRANSACTION_STATUS);
        if(TRANSACTION_STATUS != null){
            if(TRANSACTION_STATUS == APPROVED){
                system.debug('Response - success');
                refundResponse.setGatewayResultCode(res_code);
                refundResponse.setGatewayResultCodeDescription(mapOfResponseValues.get(GATEWAY_MESSAGE));
                Map<String, Object> refDetails = new Map<String, Object>();
                refDetails.put('transaction_id', mapOfResponseValues.get(TRANSACTION_ID));
                String refDetailString = JSON.Serialize(refDetails);
                refundResponse.setGatewayReferenceDetails(refDetailString);
                refundResponse.setGatewayReferenceNumber(mapOfResponseValues.get(TRANSACTION_TAG));
                refundResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(commercepayments.SalesforceResultCode.SUCCESS.name()));
            }else{
                system.debug('Response - failed');
                refundResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(commercepayments.SalesforceResultCode.DECLINE.name()));
                String code = mapOfResponseValues.get('code');
                String description = mapOfResponseValues.get('description');
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
        refundResponse.setGatewayDate(system.now());    //Gateway does not send date, assigning for test
        return refundResponse;
    }

    public commercepayments.GatewayResponse createSaleResponse(HttpResponse response)  {
        String statusCode = String.valueOf(response.getStatusCode());

        //Get the map of key and values from the gateway response using parseResponse()
        Map <String, String> mapOfResponseValues = parseResponse(response.getBody());
        commercepayments.SaleResponse saleResponse = new commercepayments.SaleResponse();
        String res_code = null;
        String TRANSACTION_STATUS = mapOfResponseValues.get(TRANSACTION_STATUS);
               if(TRANSACTION_STATUS != null){
                    if(TRANSACTION_STATUS == APPROVED){
                         //Successful gateway response
                          res_code = mapOfResponseValues.get(GATEWAY_RESPONSE_CODE);
                          Map<String, Object> refDetails = new Map<String, Object>();
                          refDetails.put('transaction_id', mapOfResponseValues.get(TRANSACTION_ID));
                          refDetails.put('method', mapOfResponseValues.get(PAYMENT_METHOD));
                          String refDetailString = JSON.Serialize(refDetails);
                          //Populating successful Sale response
                          saleResponse.setGatewayReferenceDetails(refDetailString);
                          saleResponse.setGatewayResultCode(res_code);
                          saleResponse.setGatewayResultCodeDescription(mapOfResponseValues.get(GATEWAY_MESSAGE));
                          saleResponse.setGatewayReferenceNumber(mapOfResponseValues.get(TRANSACTION_TAG));
                          saleResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(commercepayments.SalesforceResultCode.SUCCESS.name()));
                    }else{
                          //Failed gateway response
                           res_code = mapOfResponseValues.get('code');
                           saleResponse.setSalesforceResultCodeInfo(getSalesforceResultCodeInfo(commercepayments.SalesforceResultCode.DECLINE.name()));
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


    public Map<String, String> parseResponse(String jsonResponse) {
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
                    Map<String, Object> mapOfTokenByChild = (Map<String, Object>) mapOfjsonResponseByKey.get('token');
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
            }  else if (jsonresponse.contains('error')) {
                // Failed transaction with the gateway
                mapOfResponseValuesByKey.put('failed', String.ValueOf(mapOfjsonResponseByKey.get('error')));
            }  
            
            if (jsonresponse.contains('code')) {
                // The error code and error response received in the output
                String code = (string)mapOfjsonResponseByKey.get('code');
                String message = (string)mapOfjsonResponseByKey.get('message');
                mapOfResponseValuesByKey.put('code',code);
                mapOfResponseValuesByKey.put('message',message);
            }
        }
        return mapOfResponseValuesByKey;
    }

    protected virtual commercepayments.SalesforceResultCodeInfo getSalesforceResultCodeInfo(String resultCode) {
        if (resultCode == commercepayments.SalesforceResultCode.SUCCESS.name()) {
            return SUCCESS_SALESFORCE_RESULT_CODE_INFO;
        } else {
            return DECLINE_SALESFORCE_RESULT_CODE_INFO;
        }
    }

    protected virtual void setAuthExpirationDate(commercepayments.AuthorizationResponse authResponse) {
        // Payeezy does not send any expiration date. This is a dummy implementation for testing
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