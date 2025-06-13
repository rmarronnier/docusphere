# ActionDropdownComponent

A flexible and reusable dropdown component for displaying action menus throughout the application. This component standardizes dropdown patterns and replaces repeated dropdown code found in views like `baskets/index.html.erb` and throughout the GED interface.

## Features

- **Multiple trigger styles**: Icon button, button with text, link, ghost button
- **Flexible action configuration**: Support for links, buttons, JavaScript actions
- **Action grouping**: Support for dividers to group related actions
- **Danger actions**: Special styling for destructive actions
- **Accessibility**: Full ARIA support and keyboard navigation
- **Stimulus integration**: Works with existing dropdown controller
- **Responsive design**: Configurable positioning and sizing
- **Turbo support**: Built-in support for Turbo methods and confirmations

## Basic Usage

### Simple Icon Button Dropdown

```erb
<%= action_dropdown(
  actions: [
    {
      label: "Voir",
      href: "/documents/1",
      icon: :eye
    },
    {
      label: "Modifier", 
      href: "/documents/1/edit",
      icon: :edit
    }
  ]
) %>
```

### Button with Text

```erb
<%= action_dropdown(
  actions: actions,
  trigger_style: :button,
  trigger_text: "Actions"
) %>
```

## Configuration Options

### Trigger Styles

- `:icon_button` (default) - Icon-only button
- `:button` - Button with text and optional icon
- `:link` - Link-styled trigger
- `:ghost` - Ghost button (transparent background)

### Trigger Variants

- `:primary` - Primary color scheme
- `:secondary` (default) - Secondary color scheme
- `:ghost` - Transparent styling

### Trigger Sizes

- `:xs` - Extra small
- `:sm` (default) - Small
- `:md` - Medium
- `:lg` - Large

### Menu Positioning

- `"right"` (default) - Menu opens to the right
- `"left"` - Menu opens to the left
- `"center"` - Menu opens centered

## Action Configuration

Each action is a hash with the following options:

### Required Fields

- `label` - Text to display for the action

### Action Type (one required)

- `href` - URL for link actions
- `action` - Named route or path for link actions
- `data` - Data attributes only (for JavaScript-only actions)

### Optional Fields

- `icon` - Icon name (symbol)
- `method` - HTTP method (`:get`, `:post`, `:patch`, `:delete`)
- `confirm` - Confirmation message
- `danger` - Boolean, applies danger styling (red colors)
- `data` - Hash of data attributes

### Special Actions

- `{ divider: true }` - Creates a separator between action groups

## Examples

### Complex Dropdown with Grouping

```erb
<%
actions = [
  {
    label: "Télécharger",
    href: document_path(@document, format: :pdf),
    icon: :download,
    data: { turbo_method: :get }
  },
  {
    label: "Partager",
    action: "share",
    icon: :share,
    data: { action: "click->document-actions#share" }
  },
  { divider: true },
  {
    label: "Archiver",
    href: archive_document_path(@document),
    icon: :archive,
    method: :patch,
    confirm: "Archiver ce document ?"
  },
  { divider: true },
  {
    label: "Supprimer",
    href: document_path(@document),
    icon: :trash,
    method: :delete,
    confirm: "Êtes-vous sûr ?",
    danger: true
  }
]
%>

<%= action_dropdown(
  actions: actions,
  trigger_variant: :secondary
) %>
```

### JavaScript-Only Actions

```erb
<%
actions = [
  {
    label: "Show Modal",
    data: { action: "click->modal#show" },
    icon: :eye
  },
  {
    label: "Copy Link",
    data: { 
      action: "click->clipboard#copy", 
      clipboard_text: "https://example.com" 
    },
    icon: :clipboard
  }
]
%>

<%= action_dropdown(
  actions: actions,
  trigger_style: :button,
  trigger_text: "Quick Actions"
) %>
```

### Custom Styling and Positioning

```erb
<%= action_dropdown(
  actions: actions,
  trigger_style: :button,
  trigger_text: "Options",
  trigger_variant: :primary,
  trigger_size: :lg,
  position: "left",
  menu_width: "w-72",
  z_index: "z-40"
) %>
```

## Component API

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `actions` | Array | required | Array of action hashes |
| `trigger_style` | Symbol | `:icon_button` | Style of trigger button |
| `trigger_text` | String | `nil` | Text for trigger button |
| `trigger_icon` | Symbol | `:menu` | Icon for trigger button |
| `trigger_variant` | Symbol | `:secondary` | Color variant for trigger |
| `trigger_size` | Symbol | `:sm` | Size of trigger button |
| `position` | String | `"right"` | Menu position relative to trigger |
| `menu_width` | String | `"w-56"` | Tailwind width class for menu |
| `z_index` | String | `"z-50"` | Tailwind z-index class |
| `data` | Hash | `{}` | Additional data attributes |

## Accessibility

The component includes comprehensive accessibility features:

- ARIA attributes (`aria-haspopup`, `aria-expanded`, `aria-label`)
- Proper role attributes (`role="menu"`, `role="menuitem"`)
- Keyboard navigation support
- Screen reader friendly labels
- Proper tabindex management

## Stimulus Integration

The component automatically integrates with the existing `dropdown_controller.js`:

- Uses `data-controller="dropdown"`
- Includes `data-action="click->dropdown#toggle"`
- Provides `data-dropdown-target="button"` and `data-dropdown-target="menu"`

## Migration from Existing Patterns

### Before (baskets/index.html.erb)

```erb
<%= dropdown(trigger_icon: '<path d="..."/>') do %>
  <%= link_to "Voir", basket_path(basket), 
              class: "block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" %>
  <%= link_to "Modifier", edit_basket_path(basket), 
              class: "block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100" %>
  <hr class="my-1">
  <%= link_to "Supprimer", basket_path(basket), method: :delete,
              data: { confirm: "Êtes-vous sûr ?" },
              class: "block px-4 py-2 text-sm text-red-700 hover:bg-gray-100" %>
<% end %>
```

### After

```erb
<%
basket_actions = [
  {
    label: "Voir",
    href: basket_path(basket),
    icon: :eye
  },
  {
    label: "Modifier",
    href: edit_basket_path(basket),
    icon: :edit
  },
  { divider: true },
  {
    label: "Supprimer",
    href: basket_path(basket),
    icon: :trash,
    method: :delete,
    confirm: "Êtes-vous sûr ?",
    danger: true
  }
]
%>

<%= action_dropdown(actions: basket_actions) %>
```

## Testing

The component includes comprehensive tests covering:

- All trigger styles and variants
- Action rendering and data attributes
- Grouping and dividers
- Accessibility features
- Stimulus integration
- Error handling and validation

Run tests with:

```bash
docker-compose run --rm web bundle exec rspec spec/components/ui/action_dropdown_component_spec.rb
```

## ViewComponent Previews

Preview the component with various configurations:

```bash
# Start Rails server
docker-compose up web

# Visit: http://localhost:3000/rails/view_components/ui/action_dropdown_component
```

Available previews:
- Default icon button
- Button trigger with text
- Complex actions with grouping
- Different trigger variants
- Different sizes
- Position variations
- JavaScript-only actions