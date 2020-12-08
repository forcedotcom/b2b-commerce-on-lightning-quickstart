/**
 * This class is the adapter for Payeezy payment gateway
 * 
 * The adapter forms the Http request, makes the gateway call 
 * and parse the response into the correct type of gatewayResponse
 * 
 * The adapter has only read access to database
 * 
 * The class needs to implement processRequest which gets called from the core service
 */
public class PayeezyAdapter implements commercepayments.PaymentGatewayAdapter {
    
    /**
     * Function to process transaction requests
     * This is the entry point for the Payeezy adapter class
     */
    public commercepayments.GatewayResponse processRequest(commercepayments.paymentGatewayContext gatewayContext){
        commercepayments.RequestType requestType;
        if(gatewayContext==null) {
           return new commercepayments.GatewayErrorResponse('400','Gateway context cannot be null');
        }
        //Get the instance of service based on the request type
        AbstractTransactionService service = TransactionServiceAdapter.getServiceInstance(gatewayContext);
        if(service!=null){
            return service.execute();
        } else {
            return new commercepayments.GatewayErrorResponse('400','Service not found');
        }
            
    }
}