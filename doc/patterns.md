# Pattern Library

## Accessible action link

Provide a screen reader more context for an action link.

Parameters:

- text
- href
- context (optional)

```ruby
a11y_action_link("Show", "https://example.com/", "this quarter's budgets")
```

### Output

```html
<a href="https://example.com/" class="govuk-link">
  Show <span class="govuk-visually-hidden">this quarter's budgets</span>
</a>
```

## Link that opens in a new tab

Parameters:

- text
- href

```ruby
link_to_new_tab("Example", "https://example.com")
```

### Output

```html
<a href="https://example.com/" class="govuk-link" target="_blank" rel="noreferrer
noopener">
  Example (opens in new tab)
</a>
```

