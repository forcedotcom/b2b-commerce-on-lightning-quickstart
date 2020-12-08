import { transformData } from '../dataNormalizer';

describe('Search Results: Data Normalizer', () => {
    // Empty test
    [null, undefined, {}].forEach((emptyResults) => {
        it(`returns a normalized empty result when provided an empty results representation (${JSON.stringify(
            emptyResults
        )})`, () => {
            // Arrange
            const DEFAULT_PAGE_SIZE = 20;
            const expectedNormalizedResult = {
                categoriesData: expect.any(Object),
                facetsData: expect.any(Array),
                layoutData: [],
                locale: '',
                pageSize: DEFAULT_PAGE_SIZE,
                total: 0
            };

            // Act
            const normalizedResult = transformData(emptyResults);

            // Assert
            expect(normalizedResult).toEqual(expectedNormalizedResult);
        });
    });

    // Overall structure test
    it('returns a normalized result when provided a valid result', () => {
        // Arrange
        const locale = 'en_US';
        const currencyIsoCode = 'USD';
        const pageSize = 20;
        const total = 1;

        const id = '01txx0000006iGyAAI';
        const name = 'Item 1';
        const fields = { StockKeepingUnit: { value: 'SK0001' } };
        const productClass = 'Simple';

        const imageUrl = 'http://image.path';
        const title = 'title of the image';
        const imageAlternateText = 'image alt text';

        const listPrice = '200';
        const unitPrice = '500';

        const results = {
            locale,
            productsPage: {
                currencyIsoCode,
                pageSize,
                total,
                products: [
                    {
                        id,
                        name,
                        fields,
                        productClass,
                        defaultImage: {
                            url: imageUrl,
                            alternateText: imageAlternateText,
                            // values we don't use in UI so far
                            contentVersionId: '5OUxx0000004CCDGA2',
                            id: '2pmxx000000003CAAQ',
                            mediaType: 'Image',
                            sortOrder: 0,
                            thumbnailUrl: 'http://thumbnail.url',
                            title
                        },
                        prices: {
                            listPrice,
                            unitPrice
                        }
                    }
                ]
            },
            categories: {},
            facets: []
        };

        const exptectedResult = {
            locale,
            pageSize,
            total,
            layoutData: [
                {
                    id,
                    name,
                    fields: expect.any(Array),
                    image: {
                        url: imageUrl,
                        title,
                        alternateText: imageAlternateText
                    },
                    prices: {
                        listingPrice: listPrice,
                        negotiatedPrice: unitPrice,
                        currencyIsoCode
                    }
                }
            ],
            categoriesData: expect.any(Object),
            facetsData: expect.any(Array)
        };

        // Act
        const normalizedResult = transformData(results);

        // Assert
        expect(normalizedResult).toEqual(exptectedResult);
    });

    // Sanity test for fields structure
    it('make sure fields are consolidated with the given cardContentMapping', () => {
        const cardContentMapping = 'Name,StockKeepingUnit,ProductCode';

        const results = {
            productsPage: {
                products: [
                    {
                        fields: {
                            Name: { value: 'Pill Jacket' },
                            StockKeepingUnit: { value: 'M0013' },
                            ProductCode: { value: 'PCM0013' }
                        }
                    },
                    {
                        fields: {
                            Name: { value: 'Peak Canyonwall Jacket' },
                            ProductCode: { value: '' }
                        }
                    }
                ]
            }
        };

        const expectedFields = {
            first: [
                {
                    name: 'Name',
                    value: 'Pill Jacket'
                },
                {
                    name: 'StockKeepingUnit',
                    value: 'M0013'
                },
                {
                    name: 'ProductCode',
                    value: 'PCM0013'
                }
            ],
            second: [
                {
                    name: 'Name',
                    value: 'Peak Canyonwall Jacket'
                }
            ]
        };

        // Act
        const normalizedResult = transformData(results, cardContentMapping);

        // Assert
        expect(normalizedResult.layoutData[0].fields).toEqual(
            expectedFields.first
        );
        expect(normalizedResult.layoutData[1].fields).toEqual(
            expectedFields.second
        );
    });

    // Sanity test for facets structure
    it('make sure facetsData are consolidated with the given facets', () => {
        // Arrange
        const results = {
            facets: [
                {
                    attributeType: 'Cust',
                    displayName: 'C Display',
                    displayRank: 4,
                    displayType: 'MultiSelect',
                    facetType: 'Distinct',
                    nameOrId: 'C',
                    values: [
                        {
                            nameOrId: 'R',
                            displayName: 'R',
                            productCount: 3,
                            type: 'Distinct'
                        },
                        {
                            nameOrId: 'G',
                            displayName: 'G',
                            productCount: 7,
                            type: 'Distinct'
                        }
                    ]
                },
                {
                    attributeType: 'Std',
                    displayName: 'F Display',
                    displayRank: 2,
                    displayType: 'MultiSelect',
                    facetType: 'Distinct',
                    nameOrId: 'C',
                    values: [
                        {
                            nameOrId: 'A',
                            displayName: 'A',
                            productCount: 1,
                            type: 'Distinct'
                        }
                    ]
                }
            ]
        };

        const exptectedFacets = [
            {
                attributeType: 'Cust',
                displayName: 'C Display',
                displayRank: 4,
                displayType: 'MultiSelect',
                type: 'Distinct',
                id: 'C:Cust',
                nameOrId: 'C',
                values: [
                    {
                        nameOrId: 'R',
                        displayName: 'R',
                        productCount: 3,
                        type: 'Distinct',
                        checked: false
                    },
                    {
                        nameOrId: 'G',
                        displayName: 'G',
                        productCount: 7,
                        type: 'Distinct',
                        checked: false
                    }
                ]
            },
            {
                attributeType: 'Std',
                displayName: 'F Display',
                displayRank: 2,
                displayType: 'MultiSelect',
                type: 'Distinct',
                id: 'C:Std',
                nameOrId: 'C',
                values: [
                    {
                        nameOrId: 'A',
                        displayName: 'A',
                        productCount: 1,
                        type: 'Distinct',
                        checked: false
                    }
                ]
            }
        ];

        // Act
        const normalizedResult = transformData(results);

        // Assert
        expect(normalizedResult.facetsData).toEqual(exptectedFacets);
    });
});
