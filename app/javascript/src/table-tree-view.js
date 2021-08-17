
/*
  TableTreeView

  This allows a rows of a table to be collapsed and expanded based on a parent
  to child relationship. When you expand a parent row you see all the related
  children rows.

  The state of each section is saved to the DOM via the `aria-expanded`
  attribute, which also provides accessibility.

  This is a modified version of the GOV.UK Accordion component:
  https://github.com/alphagov/govuk-frontend/blob/master/src/govuk/components/accordion/accordion.js

*/

function TableTreeView ($module) {
    this.$module = $module
    this.moduleId = $module.getAttribute('id')
    this.$parents = $module.querySelectorAll('[data-parent]')

    this.browserSupportsSessionStorage = helper.checkForSessionStorage()

    this.iconClass = 'table-tree-view__icon'

    this.parentTitleFocusedClass = 'table-tree-view__section-title--focused'
    this.parentTitleClass = 'table-tree-view__parent-title'
    this.parentButtonClass = 'table-tree-view__parent-button'
    this.parentExpandedClass = 'table-tree-view__parent--expanded'
    this.childExpandedClass = 'table-tree-view__child--expanded'
}

initTableTreeView = function () {
    var $treeViewTables = document.querySelectorAll('[data-module="table-tree-view"]');
    for (var i = 0; i < $treeViewTables.length; i++) {
        new TableTreeView($treeViewTables[i]).init();
    }
}

// Initialize component
TableTreeView.prototype.init = function () {
    // Check for module
    if (!this.$module) {
        return
    }

    this.initSectionHeaders()
}

// Initialise section headers
TableTreeView.prototype.initSectionHeaders = function () {
    // Loop through section headers
    for (var i = 0; i < this.$parents.length; i++) {
        var $parent = this.$parents[i];
        // Set header attributes
        this.initHeaderAttributes($parent, i)

        this.setExpanded(this.isExpanded($parent), $parent)

        // Handle events
        $parent.addEventListener('click', this.onSectionToggle.bind(this, $parent))

        // See if there is any state stored in sessionStorage and set the sections to
        // open or closed.
        this.setInitialState($parent)
    }
}

// Set individual header attributes
TableTreeView.prototype.initHeaderAttributes = function ($parent, index) {
    var $module = this
    var $span = $parent.querySelector('.' + this.parentButtonClass)
    var $title = $parent.querySelector('.' + this.parentTitleClass)
    var parentId = $parent.getAttribute('id');

    // Copy existing span element to an actual button element, for improved accessibility.
    var $button = document.createElement('button')
    $button.setAttribute('type', 'button')
    $button.setAttribute('id', parentId + '-heading-' + (index + 1))

    var children = this.$module.querySelectorAll('[data-child-of="'+$parent.getAttribute('id')+'"]');
    var childIds = []
    for (var i = 0; i < children.length; i++) {
        childIds.push(children[i].id)
    }

    $button.setAttribute('aria-controls', childIds.join(" "))

    // Copy all attributes (https://developer.mozilla.org/en-US/docs/Web/API/Element/attributes) from $span to $button
    for (var i = 0; i < $span.attributes.length; i++) {
        var attr = $span.attributes.item(i)
        $button.setAttribute(attr.nodeName, attr.nodeValue)
    }

    $button.addEventListener('focusin', function (e) {
        if (!$parent.classList.contains($module.parentTitleFocusedClass)) {
            $parent.className += ' ' + $module.parentTitleFocusedClass
        }
    })

    $button.addEventListener('blur', function (e) {
        $parent.classList.remove($module.parentTitleFocusedClass)
    })

    // $span could contain HTML elements (see https://www.w3.org/TR/2011/WD-html5-20110525/content-models.html#phrasing-content)
    $button.innerHTML = $span.innerHTML

    $title.removeChild($span)
    $title.appendChild($button)

    // Add "+/-" icon
    var icon = document.createElement('span')
    icon.className = this.iconClass
    icon.setAttribute('aria-hidden', 'true')

    $button.appendChild(icon)
}

// When section toggled, set and store state
TableTreeView.prototype.onSectionToggle = function ($element) {
    var expanded = this.isExpanded($element)
    this.setExpanded(!expanded, $element)

    // Store the state in sessionStorage when a change is triggered
    this.storeState($element)
}

// Set section attributes when opened/closed
TableTreeView.prototype.setExpanded = function (expanded, $element) {
    var $button = $element.querySelector('.' + this.parentButtonClass)
    $button.setAttribute('aria-expanded', expanded)
    var $children = this.$module.querySelectorAll('[data-child-of="'+$element.getAttribute('id')+'"]');

    if (expanded) {
        $element.classList.add(this.parentExpandedClass);
    } else {
        $element.classList.remove(this.parentExpandedClass);
    }

    for (var i = 0; i < $children.length; i++) {
        if (expanded) {
            $children[i].classList.add(this.childExpandedClass);
        } else {
            $children[i].classList.remove(this.childExpandedClass);
            this.hideChildren($children[i]);
        }
    }

}

TableTreeView.prototype.hideChildren = function($element) {
    if (!$element.hasAttribute('data-parent')) {
        return;
    }
    this.setExpanded(false, $element);
    this.storeState($element)
}

// Get state of section
TableTreeView.prototype.isExpanded = function ($element) {
    return $element.classList.contains(this.parentExpandedClass)
}

// Check for `window.sessionStorage`, and that it actually works.
var helper = {
    checkForSessionStorage: function () {
        var testString = 'this is the test string'
        var result
        try {
            window.sessionStorage.setItem(testString, testString)
            result = window.sessionStorage.getItem(testString) === testString.toString()
            window.sessionStorage.removeItem(testString)
            return result
        } catch (exception) {
            if ((typeof console === 'undefined' || typeof console.log === 'undefined')) {
                console.log('Notice: sessionStorage not available.')
            }
        }
    }
}

// Set the state of the accordions in sessionStorage
TableTreeView.prototype.storeState = function ($element) {
    if (this.browserSupportsSessionStorage) {
        // We need a unique way of identifying each content in the accordion. Since
        // an `#id` should be unique and an `id` is required for `aria-` attributes
        // `id` can be safely used.
        var $button = $element.querySelector('.' + this.parentButtonClass)

        if ($button) {
            var contentId = $button.getAttribute('aria-controls')
            var contentState = $button.getAttribute('aria-expanded')

            if (typeof contentId === 'undefined' && (typeof console === 'undefined' || typeof console.log === 'undefined')) {
                console.error(new Error('No aria controls present in accordion section heading.'))
            }

            if (typeof contentState === 'undefined' && (typeof console === 'undefined' || typeof console.log === 'undefined')) {
                console.error(new Error('No aria expanded present in accordion section heading.'))
            }

            // Only set the state when both `contentId` and `contentState` are taken from the DOM.
            if (contentId && contentState) {
                window.sessionStorage.setItem(contentId, contentState)
            }
        }
    }
}

// Read the state of the accordions from sessionStorage
TableTreeView.prototype.setInitialState = function ($element) {
    if (this.browserSupportsSessionStorage) {
        var $button = $element.querySelector('.' + this.parentButtonClass)

        if ($button) {
            var contentId = $button.getAttribute('aria-controls')
            var contentState = contentId ? window.sessionStorage.getItem(contentId) : null

            if (contentState !== null) {
                this.setExpanded(contentState === 'true', $element)
            }
        }
    }
}

module.exports = initTableTreeView
