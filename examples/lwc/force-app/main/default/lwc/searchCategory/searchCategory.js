import { LightningElement, api } from 'lwc';

/**
 * An organized display of the given category and it's children.
 *
 * @fires SearchCategory#categoryupdate
 */
export default class SearchCategory extends LightningElement {
    /**
     * An event fired when the user has selected a category.
     *
     * Properties:
     *   - Bubbles: true
     *   - Composed: true
     *
     * @event SearchCategory#categoryupdate
     * @type {CustomEvent}
     *
     * @property {string} categoryId
     *   The unique identifier of the category.
     *
     * @export
     */

    /**
     * Gets or sets the display data for categories.
     *
     * @type {ConnectApi.SearchCategory}
     * @private
     */
    @api
    displayData;

    /**
     * Gets the current category data.
     *
     * @type {ConnectApi.ProductCategoryData}
     * @readonly
     * @private
     */
    get category() {
        return (this.displayData || {}).category || {};
    }

    /**
     * Gets the children of the current category.
     *
     * @type {object}
     * @readonly
     * @private
     */
    get children() {
        return ((this.displayData || {}).children || []).map(
            ({ category, productCount }) => ({
                id: category.id,
                displayName: `${category.name} (${productCount})`
            })
        );
    }

    get activeSections() {
        return this._sections ? this._sections : ['category'];
    }

    handleSectionToggle(event) {
        this._sections = event.detail.openSections;
    }

    /**
     * Emits a notification that the user has selected a category.
     *
     * @fires SearchCategory#categoryupdate
     * @private
     */
    notifyCategorySelection(evt) {
        const { categoryId } = evt.target.dataset;

        this.dispatchEvent(
            new CustomEvent('categoryupdate', {
                bubbles: true,
                composed: true,
                detail: { categoryId }
            })
        );
    }

    _sections;
}
