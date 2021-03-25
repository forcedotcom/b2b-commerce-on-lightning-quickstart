import { LightningElement, api, track } from 'lwc';

/**
 * An event fired when the user's selected address has changed. This can occur even without user
 * interaction, since it defaults to the first result, meaning the user has essentially picked
 * that address unless they select another one.
 *
 * @event setbillingaddress
 * @type {CustomEvent}
 *
 * @property {Address} detail.address
 *   The address being changed to.
 *
 * @export
 */
const SET_BILLING_ADDRESS = 'setbillingaddress';

/**
 * This class is responsible for displaying a list of addresses and allowing a user to select from among them.
 *
 * @fires setbillingaddress
 */
export default class AddressSelector extends LightningElement {
    /**
     * The initial selected billing address when first rendering the component
     * @type {String}
     * @private
     */
    _initialSelectedBillingAddressId;

    /**
     * Don't try to trigger events until this variable is set true.
     *
     * @type {Boolean}
     * @private
     */
    isConnected = false;

    /**
     * The list of addresses.
     * @type {Array}
     * @private
     */
    @track addressList;

    /**
     * Error messages that need to be displayed for the billing address selector.  Note, that once this
     * error message set, there is currently no way to unset this from this component.
     */
    errorMessage;

    /**
     * The title of the billing address selector.
     * @type {String}
     */
    title = 'Billing Address';

    /**
     * Determines if the billing address selector field should be required.
     * @type {Boolean}
     */
    @api billingAddressRequired = false;

    /**
     * Properties supported by the Addresses type.
     *
     * @typedef {object} Address
     *
     * @property {string} [id]
     *  A unique identifier of the address.
     *
     * @property {string} [street]
     *  The number and street of the address. Example: 1 Market St #300
     *
     * @property {string} [city]
     *  The name of the city. Example: San Francisco
     *
     * @property {string} [state]
     *  The name of the state or province. Example: California
     *
     * @property {string} [postalCode]
     *  The postal code or zip code. Example: 94105
     *
     * @property {string} [country]
     *  The name the of the country. Example: USA
     *
     * @property {string} [name]
     *  The name associated with this address.
     *
     * @property {Boolean} [selected]
     *  Address currently selected.
     *
     * @property {Boolean} [default]
     *  Default address for the buyer's account.
     *
     */

    /**
     * Gets the list of addresses.
     * @return {Address[]} The list of addresses.
     */
    @api
    get addresses() {
        return this.addressList;
    }

    /**
     * Sets the list of addresses.
     * This also sets the initial selected address.
     * @param {Address[]} addressList - The list of Addresses
     */
    set addresses(addressList) {
        this.addressList = addressList;

        if (addressList) {
            this.setInitialSelectedAddress(addressList);
        }
    }

    /**
     * Gets the billing address error message.
     * @return {String} The error message.
     */
    @api
    get billingAddressErrorMessage() {
        return this.errorMessage;
    }

    /**
     * Sets the billing address error message and renders it under the combobox.
     *
     * @param {String} errorMessage - The error message.
     */
    set billingAddressErrorMessage(errorMessage) {
        this.errorMessage = errorMessage;
        if (this.errorMessage) {
            this.showBillingAddressError();
        }
    }

    /**
     * Returns the unique identifier (id) of the initially selected address. This is used to tell
     * the combobox group which address to select by default.
     *
     * @return {String} The id of the currently selected address or undefined.
     */
    get initialSelectedAddressId() {
        return this._initialSelectedBillingAddressId;
    }

    /**
     * Returns all the available addresses in a format that the radio group can understand.
     *
     * @return {Address[]} An array with all the lists or undefined if the list doesn't exist.
     */
    get selectableAddresses() {
        return (this.addressList || []).map((address) =>
            this.assembleAddress(address)
        );
    }

    /**
     * Displays billing address error underneath/inline with the combobox.
     *
     */
    showBillingAddressError() {
        const element = this.template.querySelector('lightning-combobox');
        if (element) {
            element.setCustomValidity(this.errorMessage);
            element.reportValidity();
        }
    }

    renderedCallback() {
        // Display error message on billing address.  This is needed when we
        // toggle selected radio options for the payment types.
        if (this.errorMessage) {
            this.showBillingAddressError();
        }
    }

    /**
     * Sets the initial selected address.
     */
    setInitialSelectedAddress(addresses) {
        let address;

        const selectedAddress = addresses.find((addr) => addr.selected);
        const defaultAddress = addresses.find((addr) => addr.default);

        address = selectedAddress || defaultAddress || addresses[0];

        if (address) {
            this._initialSelectedBillingAddressId = address.id;
            this.triggerAddressSelected(address);
        }
    }

    /**
     * Creates an "option" variable that contains a label and a value. The label is the address but
     * scrunched together for displaying on one or two lines. The value is simply the id of the address.
     *
     * TODO: @W-6339389 This is very US centric. There is follow-up work for address formatting.
     *
     * @param {Object} address The address to join into one or two lines.
     */
    assembleAddress(address) {
        // These fields should have commas between them (USA only)
        // const assembledAddress;

        let assembledAddress = [address.street, address.city, address.state]
            .filter((str) => (str || '').length > 0)
            .join(', ');

        assembledAddress = [
            assembledAddress,
            address.postalCode,
            address.country
        ]
            .filter((str) => (str || '').length > 0)
            .join(' ');

        return { label: assembledAddress, value: address.id };
    }

    /**
     * Handles the event where the user selects a new address.
     *
     * @param {Object} event The event that triggered this handler. Contains the id of the address that was selected.
     */
    handleChangeAddress(event) {
        const address = this.findAddress(event.detail.value);

        if (address) {
            this.triggerAddressSelected(address);
        }
    }

    /**
     * Triggers the event that notifies the parent of this object that a change occurred.
     *
     * @param {Object} address The newly selected address.
     * @fires setbillingaddress
     */
    triggerAddressSelected(address) {
        this.dispatchEvent(
            new CustomEvent(SET_BILLING_ADDRESS, {
                detail: {
                    address: Object.assign({}, address) // Make a copy so those that capture this event don't modify this
                }
            })
        );
    }

    /**
     * This finds the address in the list of addresses. Assuming there is a relatively small number of addresses
     * (like <1000) this will complete quickly and a large number of addresses is unlikely.
     *
     * @param {String} addressId The unique identifier of the address
     * @return {Address} The discovered address or undefined if it was not discovered.
     */
    findAddress(addressId) {
        return this.addressList.find((address) => address.id === addressId);
    }
}
