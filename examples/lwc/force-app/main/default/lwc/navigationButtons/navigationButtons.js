import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';

/**
 * This class allows for more complicated navigation paths than flows typically allow. Because
 * we can have "Wait" screens between screens, clicking back normally would take the user simply
 * back to the previous wait screen that will then automatically progress them to the next screen.
 * This class allows for a decision node after this component that will be told "NEXT" or "BACK"
 * and can then navigate as desired.
 *
 * @fires FlowNavigationNextEvent
 * @fires FlowNavigationBackEvent
 */
export default class NavigationButtons extends LightningElement {
    // Private attributes
    _actionSelected = '';

    /**
     * Comes from the flow itself and only available in flow. Given this component is only designed
     * for use in flows, this is probably fine. The actions will tell us if "Previous" is available
     * so we can display the "Previous" button only when it's available.
     */
    @api availableActions;

    /**
     * Text to display on the Previous button. Defaults to "Previous".
     * @type {String}
     */
    @api previousButtonLabel = 'Previous';

    /**
     * Text to display on the Next button. Defaults to "Next".
     * @type {String}
     */
    @api nextButtonLabel = 'Next'

    /**
     * Determines if the "Previous" button is available in this flow.
     * @returns {Boolean} True if "BACK" is found, False otherwise
     */
    get canGoPrevious() {
        return (this.availableActions && this.availableActions.some(element => element == 'BACK'));
    }

    /**
     * Gets or sets the action of the button the user pressed. Likely 'NEXT' or 'BACK'.
     * @type {String}
     */
    @api
    get selectedAction() {
        return this._actionSelected;
    }

    /**
     * Sets "BACK" into the _actionSelected variable and then trigger the Next event.
     */
    handlePreviousButton() {
        this._actionSelected = 'BACK';
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    /**
     * Sets "NEXT" into the _actionSelected variable and then trigger the Next event.
     */
    handleNextButton() {
        this._actionSelected = 'NEXT';
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }
}
