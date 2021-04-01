import { api, LightningElement } from 'lwc';
import * as Constants from './constants.js';

// Card types to label map
const cardTypesObj = {
    Visa: Constants.cardLabels.Visa,
    'Master Card': Constants.cardLabels.MasterCard,
    'American Express': Constants.cardLabels.AmericanExpress,
    'Diners Club': Constants.cardLabels.DinersClub,
    Jcb: Constants.cardLabels.JCB
};

export default class CardPaymentMethod extends LightningElement {
    // Private attributes
    _creditCardErrorMessage;
    _cardHolderName;
    _cardNumber;
    _cardType;
    _cvv;
    _expiryMonth;
    _expiryYear;
    _isConnected = false;

    /**
     * Gets or sets the name of the card holder.
     *
     * The value of this property is updated in response to user interactions with the control.
     *
     * @type {String}
     */
    @api
    get cardHolderName() {
        return this._cardHolderName;
    }

    /**
     * Gets or sets the card type.
     *
     * The value of this property is updated in response to user interactions with the control.
     *
     * @type {String}
     */
    @api
    get cardType() {
        return this._cardType;
    }

    /**
     * Gets or sets the card number.
     *
     * The value of this property is updated in response to user interactions with the control.
     *
     * @type {String}
     */
    @api
    get cardNumber() {
        return this._cardNumber;
    }

    /**
     * Gets or sets the card verification value.
     *
     * The value of this property is updated in response to user interactions with the control.
     *
     * @type {String}
     */
    @api
    get cvv() {
        return this._cvv;
    }

    /**
     * Gets or sets the expiry month of the card.
     *
     * The value of this property is updated in response to user interactions with the control.
     *
     * @type {String}
     */
    @api
    get expiryMonth() {
        return this._expiryMonth;
    }

    /**
     * Gets or sets the expiry year of the card.
     *
     * The value of this property is updated in response to user interactions with the control.
     *
     * @type {String}
     */
    @api
    get expiryYear() {
        return this._expiryYear;
    }

    /**
     * Determines if the card holder name field is required.
     * @type {Boolean}
     */
    @api cardHolderNameRequired = false;

    /**
     * Determines if the card type field is required.
     * @type {Boolean}
     */
    @api cardTypeRequired = false;

    /**
     * Determines if the expiry month field is required.
     * @type {Boolean}
     */
    @api expiryMonthRequired = false;

    /**
     * Determines if the expiry year field is required.
     * @type {Boolean}
     */
    @api expiryYearRequired = false;

    /**
     * Determines if the cvv field is required.
     * @type {Boolean}
     */
    @api cvvRequired = false;

    /**
     * Determines if the card holder name field should be hidden.
     * @type {Boolean}
     */
    @api hideCardHolderName = false;

    /**
     * Determines if the card type field should be hidden.
     * @type {Boolean}
     */
    @api hideCardType = false;

    /**
     * Determines if the cvv field should be hidden.
     * @type {Boolean}
     */
    @api hideCvv = false;

    /**
     * Determines if the expiry month field should be hidden.
     * @type {Boolean}
     */
    @api hideExpiryMonth = false;

    /**
     * Determines if the expiry year field should be hidden.
     * @type {Boolean}
     */
    @api hideExpiryYear = false;

    /**
     * Error message which will be displayed in the error section
     * @type {String}
     */
    @api
    get creditCardErrorMessage() {
        return this._creditCardErrorMessage;
    }

    set creditCardErrorMessage(newMessage) {
        this._creditCardErrorMessage = newMessage;
    }

    /**
     * Shows or clears validation errors on inputs that comprise the component, returns true if required
     * fields have been filled.
     *
     * @returns {Boolean}
     *  True if required fields have been filled, false otherwise.
     */
    @api
    reportValidity() {
        if (!this._isConnected) {
            return true;
        }

        const incompleteFields = this.hasIncompleteCardPaymentFields();

        const componentsToValidate = this.template.querySelectorAll(
            '[data-validate]'
        );

        // Need to run .reportValidity on all components to ensure that all errors are shown/cleared at once
        const validateFields = [...componentsToValidate].reduce(
            (result, component) => component.reportValidity() && result,
            true
        );

        return !incompleteFields && validateFields;
    }

    /**
     * Iterates through the credit card fields and checks if any of the fields that are displayed and are required have
     * an empty value. Sets an error on the cardAuthErrorMessage attribute if there is an empty required field.
     *
     * @returns true if there is an empty required field, false otherwise
     * @private
     */
    hasIncompleteCardPaymentFields() {
        const fieldRequiredValueMap = [
            {
                isHiddenAttr: this.hideCardHolderName,
                isRequiredAttr: this.cardHolderNameRequired,
                value: this.cardHolderName,
                error: this.labels.InvalidName
            },
            {
                isHiddenAttr: this.hideCardType,
                isRequiredAttr: this.cardTypeRequired,
                value: this.cardType,
                error: this.labels.InvalidCardType
            },
            {
                isHiddenAttr: false,
                isRequiredAttr: true,
                value: this.cardNumber,
                error: this.labels.InvalidCreditCardNumber
            },
            {
                isHiddenAttr: this.hideCvv,
                isRequiredAttr: this.cvvRequired,
                value: this.cvv,
                error: this.labels.InvalidCvv
            },
            {
                isHiddenAttr: this.hideExpiryMonth,
                isRequiredAttr: this.expiryMonthRequired,
                value: this.expiryMonth,
                error:  this.labels.InvalidExpiryMonth
            },
            {
                isHiddenAttr: this.hideExpiryYear,
                isRequiredAttr: this.expiryYearRequired,
                value: this.expiryYear,
                error: this.labels.InvalidExpiryYear
            }
        ];

        const isInvalidField = fieldRequiredValueMap.find((field) => {
            if (!field.isHiddenAttr && field.isRequiredAttr && !field.value) {
                this._creditCardErrorMessage = field.error;
                return true;
            }
            return false;
        });

        return isInvalidField;
    }

    /**
     * Gets years to use in the Expiry Years dropdown
     *
     * @returns {Array} Years from current year to current year + 19
     * @private
     */
    get expiryYears() {
        const expiryYears = [],
            noOfYears = 20;
        let year, i;
        for (
            year = new Date().getFullYear(), i = 0;
            i < noOfYears;
            year++, i++
        ) {
            expiryYears.push({ label: year, value: year.toString() });
        }
        return expiryYears;
    }

    /**
     * Gets months (as integers) to use in the Expiry Month dropdown
     *
     * @returns {Array} An array of integers from 1 - 12
     * @private
     */
    get expiryMonths() {
        const expiryMonths = [],
            noOfMonths = 12;
        for (let month = 1; month <= noOfMonths; month++) {
            expiryMonths.push({ label: month, value: month.toString() });
        }
        return expiryMonths;
    }

    /**
     * Gets an array of supported card types to use in Card Type dropdown
     *
     * @returns {Array} An array of card type strings
     * @private
     */
    get cardTypes() {
        return Object.entries(cardTypesObj).map((keyValue) => ({
            label: keyValue[1],
            value: keyValue[0]
        }));
    }

    /**
     * Gets SLDS classes to use for the Card Number field.  Dependent on if CVV field is hidden.
     *
     * @returns {string} SLDS classe ie. 'slds-size_2-of-3' if CVV visible
     * @private
     */
    get cardNumberClass() {
        const sldsColumnSize = this.hideCvv
            ? 'slds-size_1-of-1'
            : 'slds-size_2-of-3';
        return 'slds-form-element ' + sldsColumnSize;
    }

    /**
     * Handler for the when the Card Holder Name input is changed
     * @param {object} event change event
     *
     * @private
     */
    handleCardHolderNameChange(event) {
        this._cardHolderName = event.target.value;
        event.target.reportValidity();
    }

    /**
     * Handler for the when the Card Type input is changed
     * @param {object} event change event
     *
     * @private
     */
    handleCardTypeChange(event) {
        this._cardType = event.target.value;
        event.target.reportValidity();
    }

    /**
     * Handler for the when the Card Number input is changed
     * @param {object} event change event
     *
     * @private
     */
    handleCardNumberChange(event) {
        this._cardNumber = event.target.value;
        event.target.reportValidity();
    }

    /**
     * Handler for the when the CVV input is changed
     * @param {object} event change event
     *
     * @private
     */
    handleCvvChange(event) {
        this._cvv = event.target.value;
        event.target.reportValidity();
    }

    /**
     * Handler for the when the Expiry Month input is changed
     * @param {object} event change event
     *
     * @private
     */
    handleExpiryMonthChange(event) {
        this._expiryMonth = event.target.value;
        event.target.reportValidity();
    }

    /**
     * Handler for the when the Expiry Year input is changed
     * @param {object} event change event
     *
     * @private
     */
    handleExpiryYearChange(event) {
        this._expiryYear = event.target.value;
        event.target.reportValidity();
    }

    /**
     * Stop event bubbling, by attaching this to onkeyup/down/press handler for
     * the lightning-inputs in the card payment cmp.
     *
     * @private
     */
    preventSensitiveInformationPropagation(keyboardEvent) {
        keyboardEvent.stopPropagation();
    }

    get labels() {
        return Constants.labels;
    }

    connectedCallback() {
        this._isConnected = true;
    }

    disconnectedCallback() {
        this._isConnected = false;
    }
}
