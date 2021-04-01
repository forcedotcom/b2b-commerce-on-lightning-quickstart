import { LightningElement, api, track } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';
import * as Constants from './constants';

import communityId from '@salesforce/community/Id';
import getPaymentInfo from '@salesforce/apex/B2BPaymentController.getPaymentInfo';
import setPayment from '@salesforce/apex/B2BPaymentController.setPayment';

/**
 * Allows users to choose the type of payment (eg. Purchase Order, Credit Card)
 * and to fill out the required information for the chosen type.
 *
 * @fires FlowNavigationNextEvent
 * @fires PaymentMethod#submitpayment
 */
export default class PaymentMethod extends LightningElement {
    // Private attributes
    _addresses;
    _creditCardErrorMessage;
    _purchaseOrderErrorMessage = '';
    _cartId;
    _purchaseOrderNumber;
    _selectedBillingAddress;
    _selectedPaymentType = Constants.PaymentTypeEnum.PONUMBER;

    /**
     * Determines if Purchase Order is a required field.
     * @type {Boolean}
     */
    @api poRequired = false;

    /**
     * Determines if Card Holder Name is a required field.
     * @type {Boolean}
     */
    @api cardHolderNameRequired = false;

    /**
     * Determines if Card Type is a required field.
     * @type {Boolean}
     */
    @api cardTypeRequired = false;

    /**
     * Determines if Expiry Month is a required field.
     * @type {Boolean}
     */
    @api expiryMonthRequired = false;

    /**
     * Determines if Expiry Year is a required field.
     * @type {Boolean}
     */
    @api expiryYearRequired = false;

    /**
     * Determines if CVV is a required field.
     * @type {Boolean}
     */
    @api cvvRequired = false;

    /**
     * Determines if Card Holder Name is a hidden field.
     * @type {Boolean}
     */
    @api hideCardHolderName = false;

    /**
     * Determines if Card Type is a hidden field.
     * @type {Boolean}
     */
    @api hideCardType = false;

    /**
     * Determines if CVV is a hidden field.
     * @type {Boolean}
     */
    @api hideCvv = false;

    /**
     * Determines if Expiry Month is a hidden field.
     * @type {Boolean}
     */
    @api hideExpiryMonth = false;

    /**
     * Determines if Expiry Year is a hidden field.
     * @type {Boolean}
     */
    @api hideExpiryYear = false;

    /**
     * Determines if Purchase Order is a hidden option.
     * @type {Boolean}
     */
    @api hidePurchaseOrder = false;

    /**
     * Determines if Credit Card is a hidden option.
     * @type {Boolean}
     */
    @api hideCreditCard = false;

    /**
     * The list of labels used in the cmp. 
     * @type {String}
     */
    get labels() {
        return Constants.labels;
    }

    /**
     * Gets or sets the currently selected payment type.
     *
     * The value of this property is updated in response to user interactions with the control.
     *
     * @type {String}
     */
    @api
    get selectedPaymentType() {
        return this._selectedPaymentType;
    }

    set selectedPaymentType(newPaymentType) {
        this._selectedPaymentType = newPaymentType;
    }

    /**
     * The purchase order number. Used to pass the purchase order to the server and to
     * display the existing purchase order when the component loads.
     *
     * The value of this property is updated in response to user interactions with the control.
     *
     * @type {string}
     */
    @api
    get purchaseOrderNumber() {
        return this._purchaseOrderNumber;
    }

    set purchaseOrderNumber(newNumber) {
        this._purchaseOrderNumber = newNumber;
    }

    /**
     * The address data. Used to pass the user's addresses to the child billing address components.
     * @type {Address[]}
     */
    @api
    get addresses() {
        return this._addresses;
    }

    set addresses(billingAddresses) {
        this._addresses = billingAddresses;
    }

    /**
     * Gets or sets the selected billing address.
     * @type {String}
     */
    @api
    get selectedBillingAddress() {
        return this._selectedBillingAddress;
    }

    set selectedBillingAddress(address) {
        this._selectedBillingAddress = address;
    }

    /**
     * Determines if Billing Address is a hidden field.
     * @type {Boolean}
     */
    @api hideBillingAddress = false;

    /**
     * Determines if the billing address field should be marked required.
     * @type {Boolean}
     */
    @api billingAddressRequired = false;

    /**
     * The error message string if there is an error with displaying billing addresses.
     * Errors that are possible are no access to web cart/ no access to CPA/ or no billing addresses in the list.
     *
     * @type {String}
     */
    @api billingAddressErrorMessage;

    /**
     * The cartId for the current webCart.
     * @return {String} the webCartID
     */
    @api
    get cartId() {
        return this._cartId;
    }

    /**
     * Sets the cartId of the current webCart.
     * @param {String} cartId
     */
    set cartId(cartId) {
        this._cartId = cartId;
        if (cartId) {
            this.initializePaymentData(cartId);
        }
    }

    /**
     * Gets the payment types
     * PO Number or Card Payment
     */
    get paymentTypes() {
        return {
            poNumber: Constants.PaymentTypeEnum.PONUMBER,
            cardPayment: Constants.PaymentTypeEnum.CARDPAYMENT
        };
    }

    /**
     * Get state of selected payment type
     * @return {boolean} true if selected payment type is Card Payment
     */
    get isCardPaymentSelected() {
        return (
            this.actualSelectedPaymentType ===
                Constants.PaymentTypeEnum.CARDPAYMENT && !this.hideCreditCard
        );
    }

    /**
     * Get state of selected payment type
     * @return {boolean} true if selected payment type is PO number
     */
    get isPoNumberSelected() {
        return (
            this.actualSelectedPaymentType ===
            Constants.PaymentTypeEnum.PONUMBER && !this.hidePurchaseOrder
        );
    }

    /**
     * Get the selected payment type.
     * If hidePurchaseOrder is true, default to cardPayment.
     * if hideCreditCard is true, default to PurchaseOrderNumber.
     * @private
     */
    get actualSelectedPaymentType() {
        return this.hidePurchaseOrder
        ? Constants.PaymentTypeEnum.CARDPAYMENT
        : (this.hideCreditCard ? Constants.PaymentTypeEnum.PONUMBER : this._selectedPaymentType);
    }

    /**
     * Handler to initialize the payment component
     * @param {String} cartId - the current webCart ID
     */
    initializePaymentData(cartId) {
        // If we don't have those values yet
        getPaymentInfo({ cartId: cartId, communityId: communityId })
            .then((data) => {
                this._purchaseOrderNumber = data.purchaseOrderNumber;
                this._addresses = data.addresses;
            })
            .catch((error) => {
                //do nothing, continue as normal
                console.log(error.body.message);
            });
    }

    /**
     * Handler for the 'blur' event fired from the purchase order input.
     */
    handleUpdate() {
        const poComponent = this.getComponent('[data-po-number]');
        const poData = (poComponent.value || '').trim();
        this._purchaseOrderNumber = poData;
    }

    /**
     * Handler for the 'click' event fired from the payment type radio buttons.
     * @param {event} event - The selected payment type
     */
    handlePaymentTypeSelected(event) {
        this._selectedPaymentType = event.currentTarget.value;
    }

    /**
     * Handler for the 'click' event fired from the payment button.
     * If PO Number is selected, make an apex call to set the new values.
     * If Credit Card is selected, check to see that all required fields are filled in first,
     * then makes an apex call which in turns makes a call to Payment.tokenize endpoint
     */
    handlePaymentButton() {
        //Get the address selected
        const selectedAddress = this._addresses.filter(add => add.id === this.selectedBillingAddress)[0];

        if (
            this.selectedPaymentType !== Constants.PaymentTypeEnum.CARDPAYMENT
        ) {
            const poInput = this.getComponent('[data-po-number]');            
            // Make sure that PO input is valid first
            if (
                poInput != null &&
                !poInput.reportValidity()
            ) {
                return;
            }

            const paymentInfo = {
                poNumber: this.purchaseOrderNumber
            };

            setPayment({
                paymentType: this.selectedPaymentType,
                cartId: this.cartId,
                billingAddress: selectedAddress,
                paymentInfo: paymentInfo
            }).then(() => {
                // After making the server calls, navigate NEXT in the flow
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            }).catch((error) => {
                this._purchaseOrderErrorMessage = error.body.message;
            });
        } else {
            // First let's get the cc data
            const creditPaymentComponent = this.getComponent(
                '[data-credit-payment-method]'
            );

            // Second let's make sure the required fields are valid
            if (
                creditPaymentComponent != null &&
                !creditPaymentComponent.reportValidity()
            ) {
                return;
            }

            const creditCardData = this.getCreditCardFromComponent(
                creditPaymentComponent
            );
            
            setPayment({
                paymentType: this.selectedPaymentType,
                cartId: this.cartId,
                billingAddress: selectedAddress,
                paymentInfo: creditCardData
            }).then(() => {
                // After making the server calls, navigate NEXT in the flow
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            }).catch((error) => {
                this._creditCardErrorMessage = error.body.message;
            });
        }
    }

    getCreditCardFromComponent(creditPaymentComponent) {
        const cardPaymentData = {};
        [
            'cardHolderName',
            'cardNumber',
            'cvv',
            'expiryYear',
            'expiryMonth',
            'expiryYear',
            'cardType'
        ].forEach((property) => {
            cardPaymentData[property] = creditPaymentComponent[property];
        });
        return cardPaymentData;
    }

    /**
     * Set the address selected
     */
    handleChangeSelectedAddress(event) {
        const address = event.detail.address;
        if (address.id !== null && (address.id).startsWith('8lW')) {
            this._selectedBillingAddress = address.id;
        } else {
            this._selectedBillingAddress = '';
        }
    }

    /**
     * Simple function to query the passed element locator
     * @param {*} locator The HTML element identifier
     * @private
     */
    getComponent(locator) {
        return this.template.querySelector(locator);
    }

    dispatchCustomEvent(eventName, detail) {
        this.dispatchEvent(
            new CustomEvent(eventName, {
                bubbles: false,
                composed: false,
                cancelable: false,
                detail
            })
        );
    }
}
