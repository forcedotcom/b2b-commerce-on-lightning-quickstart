import { resolve } from 'c/cmsResourceResolver';

/**
 * Transform product search API response data into display-data.
 *
 * @param {ConnectApi.ProductSummaryPage} data
 * @param {string} cardContentMapping
 */
export function transformData(data, cardContentMapping) {
    const DEFAULT_PAGE_SIZE = 20;
    const { productsPage = {}, categories = {}, facets = [], locale = '' } =
        data || {};
    const {
        currencyIsoCode = '',
        total = 0,
        products = [],
        pageSize = DEFAULT_PAGE_SIZE
    } = productsPage;

    return {
        locale,
        total,
        pageSize,
        categoriesData: categories,
        facetsData: facets.map(
            ({
                nameOrId,
                attributeType,
                facetType: type,
                displayType,
                displayName,
                displayRank,
                values
            }) => {
                return {
                    // include a unique identifier to avoid the collision
                    // between Product2 and variant custom fields
                    id: `${nameOrId}:${attributeType}`,
                    nameOrId,
                    attributeType,
                    type,
                    displayType,
                    displayName,
                    displayRank,
                    values: values.map((v) => ({ ...v, checked: false }))
                };
            }
        ),
        /* Product list normalization */
        layoutData: products.map(
            ({ id, name, defaultImage, fields, prices }) => {
                defaultImage = defaultImage || {};
                const { unitPrice: negotiatedPrice, listPrice: listingPrice } =
                    prices || {};

                return {
                    id,
                    name,
                    fields: normalizedCardContentMapping(cardContentMapping)
                        .map((mapFieldName) => ({
                            name: mapFieldName,
                            value:
                                (fields[mapFieldName] &&
                                    fields[mapFieldName].value) ||
                                ''
                        }))
                        .filter(({ value }) => !!value),
                    image: {
                        url: resolve(defaultImage.url),
                        title: defaultImage.title || '',
                        alternateText: defaultImage.alternateText || ''
                    },
                    prices: {
                        listingPrice,
                        negotiatedPrice,
                        currencyIsoCode
                    }
                };
            }
        )
    };
}

/**
 * Gets the normalized card content mapping fields.
 * @param {string} cardContentMapping comma separated fields
 * @returns {string[]}
 */
export function normalizedCardContentMapping(cardContentMapping) {
    return (cardContentMapping || 'Name').split(',');
}
