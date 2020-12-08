/**
 * Cart Contents Tests
 * These tests demonstrate using Jest to test custom UI components.
 * For more information on testing LWCs please see:
 * https://developer.salesforce.com/docs/component-library/documentation/en/lwc/testing
 */
import { createElement } from 'lwc';
import { getNavigateCalledWith } from 'lightning/navigation';
import getCartItems from '@salesforce/apex/B2BCartControllerSample.getCartItems';
import updateCartItem from '@salesforce/apex/B2BCartControllerSample.updateCartItem';
import deleteCartItem from '@salesforce/apex/B2BCartControllerSample.deleteCartItem';
import deleteCart from '@salesforce/apex/B2BCartControllerSample.deleteCart';
import createCart from '@salesforce/apex/B2BCartControllerSample.createCart';

import CartContents from 'c/cartContents';

// Import test data from files
const GET_CART_ITEMS_SUCCESS_RESPONSE = require('./data/getcartitems-response.json');
const EMPTY_CART_SUCCESS_RESPONSE = require('./data/getcartitems-empty-response.json');
const UPDATED_CART_ITEM_SUCCESS_RESPONSE = require('./data/updatecartitem-response.json');
const NEW_CART_SUCCESS_RESPONSE = require('./data/createcart-response.json');
const CART_CONTENTS_APEX_ERROR_RESPONSE = require('./data/closedcart-error.json');

const CART_ID = '0a6RM0000004GLzYAM';
const EFFECTIVE_ACCOUNT_ID = '0010t00001TSlHlAAL';

// Mocking scoped module
jest.mock(
    '@salesforce/community/Id',
    () => {
        return '3D0DB0t0000006AcU';
    },
    { virtual: true }
);

// Mocking imperative Apex method call
jest.mock(
    '@salesforce/apex/B2BCartControllerSample.getCartItems',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

// Mocking imperative Apex method call
jest.mock(
    '@salesforce/apex/B2BCartControllerSample.updateCartItem',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

// Mocking imperative Apex method call
jest.mock(
    '@salesforce/apex/B2BCartControllerSample.deleteCartItem',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

// Mocking imperative Apex method call
jest.mock(
    '@salesforce/apex/B2BCartControllerSample.deleteCart',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

// Mocking imperative Apex method call
jest.mock(
    '@salesforce/apex/B2BCartControllerSample.createCart',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

// Helper function to wait until the microtask queue is empty. This is needed for promise
// timing when calling imperative Apex.
function flushPromises() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    return new Promise((resolve) => setTimeout(resolve));
}

// Create the component to test and append it to the jsdom document
function createComponentUnderTest() {
    const element = createElement('c-cart-contents', {
        is: CartContents
    });
    document.body.appendChild(element);
    return element;
}

describe('Cart Contents', () => {
    let element;

    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        document.body.removeChild(element);

        // Prevent data saved on mocks from leaking between tests
        jest.clearAllMocks();
    });

    [
        {
            property: 'recordId',
            defaultValue: undefined,
            changeValue: '0a6S700000000AmIAI'
        },
        {
            property: 'effectiveAccountId',
            defaultValue: undefined,
            changeValue: '001i000001AWbWuGTA'
        }
    ].forEach((propertyTest) => {
        describe(`the '${propertyTest.property}' property`, () => {
            beforeEach(() => {
                getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
                element = createComponentUnderTest();
            });

            it(`defaults to ${propertyTest.defaultValue}`, () => {
                expect(element[propertyTest.property]).toBe(
                    propertyTest.defaultValue
                );
            });

            it('reflects a changed value', () => {
                // Ensure the value isn't already set to the target value.
                expect(element[propertyTest.property]).not.toBe(
                    propertyTest.changeValue
                );

                // Change the value.
                element[propertyTest.property] = propertyTest.changeValue;

                // Ensure we reflect the changed value.
                expect(element[propertyTest.property]).toBe(
                    propertyTest.changeValue
                );
            });
        });
    });

    describe('the cart header', () => {
        it('displays a count of 0 items when the cart is empty', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(EMPTY_CART_SUCCESS_RESPONSE);
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                const cartHeader = element.shadowRoot.querySelector('h1');
                expect(cartHeader.textContent).toEqual('Cart (0)');
            });
        });

        it('displays the non-zero quantity of items in the cart', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
            element.effectiveAccountId = EFFECTIVE_ACCOUNT_ID;
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                const cartHeader = element.shadowRoot.querySelector('h1');
                expect(cartHeader.textContent).toEqual('Cart (2)');
            });
        });

        it(`updates the item count when an item quantity is changed`, () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
            updateCartItem.mockResolvedValue(
                UPDATED_CART_ITEM_SUCCESS_RESPONSE
            );
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises()
                .then(() => {
                    const cartItemsElement = element.shadowRoot.querySelector(
                        'c-cart-items'
                    );
                    cartItemsElement.dispatchEvent(
                        new CustomEvent('quantitychanged', {
                            detail: {
                                cartItemId: '0a9RM00000005cQYAQ',
                                quantity: 5
                            }
                        })
                    );
                })
                .then(() => {
                    // Return an immediate flushed promise (after the Apex call) to then
                    // wait for any asynchronous DOM updates. Jest will automatically wait
                    // for the Promise chain to complete before ending the test and fail
                    // the test if the promise ends in the rejected state.
                    return flushPromises().then(() => {
                        const cartHeader = element.shadowRoot.querySelector(
                            'h1'
                        );
                        // The Cart originally had 2 items.
                        // Updating Quantity for 1 item from 1=>5 makes the total to 6
                        expect(cartHeader.textContent).toEqual('Cart (6)');
                    });
                });
        });

        it('updates the count when an item is removed from the cart', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
            deleteCartItem.mockResolvedValue();
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises()
                .then(() => {
                    const cartHeader = element.shadowRoot.querySelector('h1');
                    expect(cartHeader.textContent).toEqual('Cart (2)');
                })
                .then(() => {
                    const cartItemsElement = element.shadowRoot.querySelector(
                        'c-cart-items'
                    );
                    cartItemsElement.dispatchEvent(
                        new CustomEvent('singlecartitemdelete', {
                            detail: {
                                cartItemId: '0a9RM00000005cQYAQ'
                            }
                        })
                    );
                })
                .then(() => {
                    // Return an immediate flushed promise (after the Apex call) to then
                    // wait for any asynchronous DOM updates. Jest will automatically wait
                    // for the Promise chain to complete before ending the test and fail
                    // the test if the promise ends in the rejected state.
                    return flushPromises().then(() => {
                        const cartHeader = element.shadowRoot.querySelector(
                            'h1'
                        );
                        // The Cart originally had 2 items.
                        // Deleting 1 item makes the total 1
                        expect(cartHeader.textContent).toEqual('Cart (1)');
                    });
                });
        });
    });

    describe('the cart sort combobox', () => {
        it('is not displayed when the cart is empty', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(EMPTY_CART_SUCCESS_RESPONSE);
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                const cartSortCombobox = element.shadowRoot.querySelector(
                    'lightning-combobox'
                );
                expect(cartSortCombobox).toBeNull();
            });
        });

        it('is displayed when the cart has items', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                const cartSortCombobox = element.shadowRoot.querySelector(
                    'lightning-combobox'
                );
                expect(cartSortCombobox).toBeTruthy();
            });
        });

        it('updates the cart data when the sort selection is changed', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises()
                .then(() => {
                    getCartItems.mockClear();
                    const comboboxEl = element.shadowRoot.querySelector(
                        'lightning-combobox'
                    );
                    comboboxEl.value = 'NameAsc';
                    comboboxEl.dispatchEvent(new CustomEvent('change'));
                })
                .then(() => {
                    // Return an immediate flushed promise (after the Apex call) to then
                    // wait for any asynchronous DOM updates. Jest will automatically wait
                    // for the Promise chain to complete before ending the test and fail
                    // the test if the promise ends in the rejected state.
                    return flushPromises().then(() => {
                        // Validate parameters of mocked Apex call
                        expect(getCartItems).toHaveBeenCalledWith(
                            expect.objectContaining({ sortParam: 'NameAsc' })
                        );
                    });
                });
        });
    });

    describe('the empty cart indicator', () => {
        it('is not displayed when there are items in the cart', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                const emptyCartPlaceholder = element.shadowRoot.querySelector(
                    'div.slds-text-align_center'
                );
                expect(emptyCartPlaceholder).toBeNull();
            });
        });

        it('is not displayed when the cart contents are indeterminate', () => {
            element = createComponentUnderTest();

            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                const emptyCartPlaceholder = element.shadowRoot.querySelector(
                    'div.slds-text-align_center'
                );
                expect(emptyCartPlaceholder).toBeNull();
            });
        });

        it('indicates the cart is empty when there are no items in the cart', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(EMPTY_CART_SUCCESS_RESPONSE);
            element = createComponentUnderTest();

            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                const emptyCartPlaceholderHeader = element.shadowRoot.querySelector(
                    '.slds-text-align_center h3'
                );
                expect(emptyCartPlaceholderHeader.textContent).toEqual(
                    'Your cart’s empty'
                );
            });
        });
    });

    describe('the clear cart button', () => {
        it('updates the cart when clicked', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
            deleteCart.mockResolvedValue();
            createCart.mockResolvedValue(NEW_CART_SUCCESS_RESPONSE);
            element = createComponentUnderTest();
            element.recordId = CART_ID;
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises()
                .then(() => {
                    const clearCartBtn = element.shadowRoot.querySelector(
                        'lightning-button'
                    );
                    clearCartBtn.click();
                })
                .then(() => {
                    // Return an immediate flushed promise (after the Apex call) to then
                    // wait for any asynchronous DOM updates. Jest will automatically wait
                    // for the Promise chain to complete before ending the test and fail
                    // the test if the promise ends in the rejected state.
                    return flushPromises().then(() => {
                        // Validate parameters of mocked Apex call
                        expect(deleteCart).toHaveBeenCalledWith(
                            expect.objectContaining({ activeCartOrId: CART_ID })
                        );
                    });
                });
        });

        it('resets the cart count when a new cart is created', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
            deleteCart.mockResolvedValue();
            createCart.mockResolvedValue(NEW_CART_SUCCESS_RESPONSE);
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises()
                .then(() => {
                    const clearCartBtn = element.shadowRoot.querySelector(
                        'lightning-button'
                    );
                    clearCartBtn.click();
                })
                .then(() => {
                    // Return an immediate flushed promise (after the Apex call) to then
                    // wait for any asynchronous DOM updates. Jest will automatically wait
                    // for the Promise chain to complete before ending the test and fail
                    // the test if the promise ends in the rejected state.
                    return flushPromises().then(() => {
                        const cartHeader = element.shadowRoot.querySelector(
                            'h1'
                        );
                        expect(cartHeader.textContent).toEqual('Cart (0)');
                    });
                });
        });

        it('navigates to the newly created cart', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
            deleteCart.mockResolvedValue();
            createCart.mockResolvedValue(NEW_CART_SUCCESS_RESPONSE);
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises()
                .then(() => {
                    const clearCartBtn = element.shadowRoot.querySelector(
                        'lightning-button'
                    );
                    clearCartBtn.click();
                })
                .then(() => {
                    // Return an immediate flushed promise (after the Apex call) to then
                    // wait for any asynchronous DOM updates. Jest will automatically wait
                    // for the Promise chain to complete before ending the test and fail
                    // the test if the promise ends in the rejected state.
                    return flushPromises().then(() => {
                        // This test uses a mocked navigation plugin.
                        // See force-app/test/jest-mocks/navigation.js for the mock
                        // and see jest.config.js for jest config to use the mock
                        const { pageReference } = getNavigateCalledWith();
                        const expectedPageReferenceObject = expect.objectContaining(
                            {
                                type: 'standard__recordPage',
                                attributes: expect.objectContaining({
                                    recordId: NEW_CART_SUCCESS_RESPONSE.cartId
                                })
                            }
                        );
                        // Verify component was called with correct event type and params
                        expect(pageReference).toEqual(
                            expectedPageReferenceObject
                        );
                    });
                });
        });
    });

    describe('Closed Cart Message', () => {
        it('is not displayed when there are items in the cart', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                const closedCartMessageSection = element.shadowRoot.querySelector(
                    'div.slds-p-top_xx-large'
                );
                expect(closedCartMessageSection).toBeNull();
            });
        });

        it('is displayed when the cart is closed', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockRejectedValue(CART_CONTENTS_APEX_ERROR_RESPONSE);
            element = createComponentUnderTest();
            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                const closedCartMessageSection = element.shadowRoot.querySelector(
                    '.slds-p-top_xx-large'
                );
                expect(closedCartMessageSection.textContent).toBe(
                    `The cart that you requested isn't available.`
                );
            });
        });
    });

    // The following tests demonstrate accessibilty (a11y) testing
    // Please see the [sa11y documentation](https://github.com/salesforce/sa11y)
    // for more information on writing these tests
    describe('sa11y accessibility tests', () => {
        it('is accessible when cart data is returned', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockResolvedValue(GET_CART_ITEMS_SUCCESS_RESPONSE);
            element = createComponentUnderTest();

            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                expect(element).toBeAccessible();
            });
        });

        it('is accessible when error is returned', () => {
            // Assign mock value for resolved Apex promise
            getCartItems.mockRejectedValue(CART_CONTENTS_APEX_ERROR_RESPONSE);
            element = createComponentUnderTest();

            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                expect(element).toBeAccessible();
            });
        });
    });
});
