import { LightningElement, wire, api } from 'lwc';

import communityId from '@salesforce/community/Id';
import getProduct from '@salesforce/apex/B2BGetInfo.getProduct';
import getCartSummary from '@salesforce/apex/B2BGetInfo.getCartSummary';
import checkProductIsInStock from '@salesforce/apex/B2BGetInfo.checkProductIsInStock';
import addToCart from '@salesforce/apex/B2BGetInfo.addToCart';
import createAndAddToList from '@salesforce/apex/B2BGetInfo.createAndAddToList';
import getProductPrice from '@salesforce/apex/B2BGetInfo.getProductPrice';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { resolve } from 'c/cmsResourceResolver';

/**
 * A detailed display of a product.
 * This outer component layer handles data retrieval and management, as well as projection for internal display components.
 */
export default class ProductDetails extends LightningElement {
    /**
     * Gets the effective account - if any - of the user viewing the product.
     *
     * @type {string}
     */
    @api
    get effectiveAccountId() {
        return this._effectiveAccountId;
    }

    /**
     * Sets the effective account - if any - of the user viewing the product
     * and fetches updated cart information
     */
    set effectiveAccountId(newId) {
        this._effectiveAccountId = newId;
        this.updateCartInformation();
    }

    /**
     * Gets or sets the unique identifier of a product.
     *
     * @type {string}
     */
    @api
    recordId;

    /**
     * Gets or sets the custom fields to display on the product
     * in a comma-separated list of field names
     *
     * @type {string}
     */
    @api
    customDisplayFields;

    /**
     * The cart summary information
     *
     * @type {ConnectApi.CartSummary}
     * @private
     */
    cartSummary;

    /**
     * The stock status of the product, i.e. whether it is "in stock."
     *
     * @type {Boolean}
     * @private
     */
    @wire(checkProductIsInStock, {
        productId: '$recordId'
    })
    inStock;

    /**
     * The full product information retrieved.
     *
     * @type {ConnectApi.ProductDetail}
     * @private
     */
    @wire(getProduct, {
        communityId: communityId,
        productId: '$recordId',
        effectiveAccountId: '$resolvedEffectiveAccountId'
    })
    product;

    /**
     * The price of the product for the user, if any.
     *
     * @type {ConnectApi.ProductPrice}
     * @private
     */
    @wire(getProductPrice, {
        communityId: communityId,
        productId: '$recordId',
        effectiveAccountId: '$resolvedEffectiveAccountId'
    })
    productPrice;

    /**
     * The connectedCallback() lifecycle hook fires when a component is inserted into the DOM.
     */
    connectedCallback() {
        this.updateCartInformation();
    }

    /**
     * Gets the normalized effective account of the user.
     *
     * @type {string}
     * @readonly
     * @private
     */
    get resolvedEffectiveAccountId() {
        const effectiveAccountId = this.effectiveAccountId || '';
        let resolved = null;

        if (
            effectiveAccountId.length > 0 &&
            effectiveAccountId !== '000000000000000'
        ) {
            resolved = effectiveAccountId;
        }
        return resolved;
    }

    /**
     * Gets whether product information has been retrieved for display.
     *
     * @type {Boolean}
     * @readonly
     * @private
     */
    get hasProduct() {
        return this.product.data !== undefined;
    }

    /**
     * Gets the normalized, displayable product information for use by the display components.
     *
     * @readonly
     */
    get displayableProduct() {
        return {
            categoryPath: this.product.data.primaryProductCategoryPath.path.map(
                (category) => ({
                    id: category.id,
                    name: category.name
                })
            ),
            description: this.product.data.fields.Description,
            image: {
                alternativeText: this.product.data.defaultImage.alternativeText,
                url: resolve(this.product.data.defaultImage.url)
            },
            inStock: this.inStock.data === true,
            name: this.product.data.fields.Name,
            price: {
                currency: ((this.productPrice || {}).data || {})
                    .currencyIsoCode,
                negotiated: ((this.productPrice || {}).data || {}).unitPrice
            },
            sku: this.product.data.fields.StockKeepingUnit,
            customFields: Object.entries(
                this.product.data.fields || Object.create(null)
            )
                .filter(([key]) =>
                    (this.customDisplayFields || '').includes(key)
                )
                .map(([key, value]) => ({ name: key, value }))
        };
    }

    /**
     * Gets whether the cart is currently locked
     *
     * Returns true if the cart status is set to either processing or checkout (the two locked states)
     *
     * @readonly
     */
    get _isCartLocked() {
        const cartStatus = (this.cartSummary || {}).status;
        return cartStatus === 'Processing' || cartStatus === 'Checkout';
    }

    /**
     * Handles a user request to add the product to their active cart.
     * On success, a success toast is shown to let the user know the product was added to their cart
     * If there is an error, an error toast is shown with a message explaining that the product could not be added to the cart
     *
     * Toast documentation: https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.use_toast
     *
     * @private
     */
    addToCart(event) {
        addToCart({
            communityId: communityId,
            productId: this.recordId,
            quantity: event.detail.quantity,
            effectiveAccountId: this.resolvedEffectiveAccountId
        })
            .then(() => {
                this.dispatchEvent(
                    new CustomEvent('cartchanged', {
                        bubbles: true,
                        composed: true
                    })
                );
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Your cart has been updated.',
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            })
            .catch(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message:
                            '{0} could not be added to your cart at this time. Please try again later.',
                        messageData: [this.displayableProduct.name],
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            });
    }

    /**
     * Handles a user request to add the product to a newly created wishlist.
     * On success, a success toast is shown to let the user know the product was added to a new list
     * If there is an error, an error toast is shown with a message explaining that the product could not be added to a new list
     *
     * Toast documentation: https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.use_toast
     *
     * @private
     */
    createAndAddToList() {
        let listname = this.product.data.primaryProductCategoryPath.path[0]
            .name;
        createAndAddToList({
            communityId: communityId,
            productId: this.recordId,
            wishlistName: listname,
            effectiveAccountId: this.resolvedEffectiveAccountId
        })
            .then(() => {
                this.dispatchEvent(new CustomEvent('createandaddtolist'));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: '{0} was added to a new list called "{1}"',
                        messageData: [this.displayableProduct.name, listname],
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            })
            .catch(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message:
                            '{0} could not be added to a new list. Please make sure you have fewer than 10 lists or try again later',
                        messageData: [this.displayableProduct.name],
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            });
    }

    /**
     * Ensures cart information is up to date
     */
    updateCartInformation() {
        getCartSummary({
            communityId: communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId
        })
            .then((result) => {
                this.cartSummary = result;
            })
            .catch((e) => {
                // Handle cart summary error properly
                // For this sample, we can just log the error
                console.log(e);
            });
    }
}
