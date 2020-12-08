/**
 * The class to get the instance of a service based on the request type
 * 
 * The class stores the instance of each service statically to implement singleton pattern
 */ 
public class TransactionServiceAdapter {
    //private Attribute to implement singleton pattern for all service classes
    private static  AuthorizationTransactionService  authTxnService;
    private static  CaptureTransactionService  captureTxnService;
    private static  ReferencedRefundTransactionService  refRefundTxnService;
    private static  TokenizeTransactionService tokenizeTxnService;
    private static  SaleTransactionService saleTxnService;
    
    /**
     * Static method that returns the instance of a service based on the request type
     */ 
    public static AbstractTransactionService getServiceInstance(commercepayments.paymentGatewayContext gatewayContext){
        commercepayments.RequestType requestType;
        requestType= gatewayContext.getPaymentRequestType();
        //Authorization Service
        if (requestType == commercepayments.RequestType.Authorize) {
            if(authTxnService ==null )
            {
                 authTxnService = new AuthorizationTransactionService(gatewayContext);
            }
            return  authTxnService;
        }
        //Capture Service
        else if ( requestType == commercepayments.RequestType.Capture) {
            if(captureTxnService ==null )
            {
                 captureTxnService = new CaptureTransactionService(gatewayContext);
            }
            return  captureTxnService;
        }
        //Referenced Refund Service
        else if ( requestType == commercepayments.RequestType.ReferencedRefund) {
            if(refRefundTxnService ==null )
            {
                 refRefundTxnService = new ReferencedRefundTransactionService(gatewayContext);
            }
            return  refRefundTxnService;
        }
        //Tokenize Service
        else if ( requestType == commercepayments.RequestType.Tokenize) {
            if(tokenizeTxnService ==null )
            {
                 tokenizeTxnService = new TokenizeTransactionService(gatewayContext);
            }
            return  tokenizeTxnService;
        }
        //Sale Service
        else if (requestType == commercepayments.RequestType.Sale){
            if(saleTxnService ==null )
             {
                  saleTxnService = new SaleTransactionService(gatewayContext);
             }
             return  saleTxnService;
        }
        // Add new transaction services here
        else {
            return null;
        }
    }
}