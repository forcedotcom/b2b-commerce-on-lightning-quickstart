# B2B-Checkout-Notifications

The Notification Reference implementation provided here contains metadata that can be deployed to any B2B Commerce enabled org. Use these files to set up an end-to-end notification strategy that the order summary owner, or buyer user, receives when checkout is complete. Notification types include bell and email notifications.

# Setup

## Use Metadata API to deploy this using Workbench:
 1. From this folder as your current location, create a .zip file: 
	```zip -r -X <your-zip-file>.zip *```
 2. Open Workbench and go to migration -> deploy.
 3. Select the file you created ( ```<your-zip-file>.zip``` ).
 4. Check the "Single Package" checkbox on that page.
 5. Click "Next".
 6. Click "Deploy".


## Email Template

Email templates contain information about order summary fields, owner names, and email recipients. The email that the order summary owner receives after they complete checkout contains metadata and content from the email template.

**email/unfiled$public:**
1. sfdc_Checkout_Order_Summary_Email_Template.email : (ApiName: *sfdc_Checkout_Order_Summary_Email_Template*)
2. sfdc_Checkout_Order_Summary_Email_Template.email-meta.xml : (ApiName: *sfdc_Checkout_Order_Summary_Email_Template*)


## Custom Notification

To send the order summary owner bell notifications when they complete a checkout, a custom notification type is required. You can decide where to display the bell notification by choosing the channel. For this example, we select mobile and desktop.

**notificationtypes**
1. sfdc_Checkout_Order_Summary_Notification_Type.notiftype (ApiName: *sfdc_Checkout_Order_Summary_Notification_Type*)


## Email Alert

An email alert is a workflow that can be triggered by flows to send an email notification. This example creates an email alert for the order summary object and maps it to the email template created previously.

**workflows**
1. OrderSummary.workflow : Email Alert (ApiName: *sfdc_Checkout_Order_Summary_Email_Alert*)


## Flow & Process Builder

Flows are necessary to trigger email alert actions and custom notification actions. We listen to the Order Summary Created Event using process builder and filter on events related to B2B commerce and calling flow action.

**flows**
1. sfdc_Checkout_Notify_On_Order_Summary_Created_Event.flow : (ApiName: *sfdc_Checkout_Notify_On_Order_Summary_Created_Event*)
2. sfdc_Checkout_Order_Summary_Notification_Flow.flow : (ApiName: *sfdc_Checkout_Order_Summary_Notification_Flow*)


## Notes

1. The package.xml file must be included in your zip file because it provides information about notification metadata.
2. For your email notification, change the From Address in your email alert. You can use your organization-wide address to create the from address. For more information, see https://help.salesforce.com/articleView?id=orgwide_email.htm&type=5
3. Public reference document link for notification: https://developer.salesforce.com/docs/atlas.en-us.b2b_comm_lex_dev_guide.meta/b2b_comm_lex_dev_guide/b2b_comm_lex_notifications.htm

## Output

The order summary owner receives email and bell notifications after a successful checkout.
