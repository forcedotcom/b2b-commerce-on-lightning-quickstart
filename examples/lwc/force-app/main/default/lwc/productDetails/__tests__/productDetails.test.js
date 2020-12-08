import { createElement } from 'lwc';
import getProduct from '@salesforce/apex/B2BGetInfo.getProduct';
import getCartSummary from '@salesforce/apex/B2BGetInfo.getCartSummary';
import checkProductIsInStock from '@salesforce/apex/B2BGetInfo.checkProductIsInStock';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

import ProductDetails from 'c/productDetails';

/**
 * This test class provides specific examples of how to test @wire adapters.
 * For other testing examples, see cartContents.test.js
 * or visit https://github.com/trailheadapps/lwc-recipes/tree/master/force-app/main/default/lwc
 */

// Import test data from files
const GET_PRODUCT_SUCCESS_RESPONSE = require('./data/getproduct-response.json');
const GET_CART_SUMMARY_SUCCESS_RESPONSE = require('./data/getcartsummary-response.json');
const CHECK_PRODUCT_IS_IN_STOCK_SUCCESS_RESPONSE = require('./data/checkproductisinstock-response.json');

// Register as Apex wire adapters. Some tests verify that provisioned values trigger desired behavior.
const getProductAdapter = registerApexTestWireAdapter(getProduct);
const checkProductIsInStockAdapter = registerApexTestWireAdapter(
    checkProductIsInStock
);

const PRODUCT_ID = '01tRM000000QQdOYAW';
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
    '@salesforce/apex/B2BGetInfo.getCartSummary',
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
    const element = createElement('c-product-details', {
        is: ProductDetails
    });
    document.body.appendChild(element);
    return element;
}

describe('Product Details', () => {
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
                getCartSummary.mockResolvedValue(
                    GET_CART_SUMMARY_SUCCESS_RESPONSE
                );

                // Emit data from @wire
                getProductAdapter.emit(GET_PRODUCT_SUCCESS_RESPONSE);

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

    describe('getProduct @wire', () => {
        beforeEach(() => {
            //set up all the data besides getProduct that is used by the Product Details component
            getCartSummary.mockResolvedValue(GET_CART_SUMMARY_SUCCESS_RESPONSE);
            checkProductIsInStockAdapter.emit(
                CHECK_PRODUCT_IS_IN_STOCK_SUCCESS_RESPONSE
            );
            element = createComponentUnderTest();
            element.effectiveAccountId = EFFECTIVE_ACCOUNT_ID;
            element.recordId = PRODUCT_ID;
        });

        it('success displays the product details display component instead of the spinner', () => {
            // Emit data from @wire
            getProductAdapter.emit(GET_PRODUCT_SUCCESS_RESPONSE);

            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                const spinner = element.shadowRoot.querySelector(
                    'lightning-spinner'
                );
                const productDetailsDisplay = element.shadowRoot.querySelector(
                    'c-product-details-display'
                );

                expect(spinner).toBeNull();
                expect(productDetailsDisplay).toBeTruthy();
            });
        });

        it('error displays a spinner instead of the product details display component', () => {
            // Emit error from @wire
            getProductAdapter.error();

            // Return an immediate flushed promise (after the Apex call) to then
            // wait for any asynchronous DOM updates. Jest will automatically wait
            // for the Promise chain to complete before ending the test and fail
            // the test if the promise ends in the rejected state.
            return flushPromises().then(() => {
                const spinner = element.shadowRoot.querySelector(
                    'lightning-spinner'
                );
                const productDetailsDisplay = element.shadowRoot.querySelector(
                    'c-product-details-display'
                );

                expect(spinner).toBeTruthy();
                expect(productDetailsDisplay).toBeNull();
            });
        });
    });
});
