# StatusBadgeComponent Usage Guide

The `Ui::StatusBadgeComponent` provides a consistent way to display status badges throughout the application.

## Basic Usage

```erb
<%= render Ui::StatusBadgeComponent.new(status: 'active') %>
```

## Parameters

- `status`: The status to display (required)
- `label`: Custom label text (optional, defaults to humanized status)
- `color`: Override the automatic color selection (optional)
- `size`: Badge size - `:sm`, `:default`, `:lg` (default: `:default`)
- `dot`: Show a dot indicator (default: `false`)
- `removable`: Show a remove button (default: `false`)
- `icon`: HTML string for an icon (optional)
- `variant`: Display style - `:badge` (default) or `:pill`
- `class`: Additional CSS classes (optional)

## Examples

### Basic Status Badge
```erb
<%= render Ui::StatusBadgeComponent.new(status: 'active') %>
```

### Custom Label
```erb
<%= render Ui::StatusBadgeComponent.new(
  status: 'active',
  label: 'Currently Active'
) %>
```

### With Dot Indicator
```erb
<%= render Ui::StatusBadgeComponent.new(
  status: 'in_progress',
  dot: true
) %>
```

### Removable Badge
```erb
<%= render Ui::StatusBadgeComponent.new(
  status: 'draft',
  removable: true
) %>
```

### Pill Style
```erb
<%= render Ui::StatusBadgeComponent.new(
  status: 'pending',
  variant: :pill
) %>
```

### With Icon
```erb
<%= render Ui::StatusBadgeComponent.new(
  status: 'locked',
  icon: '<svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>
  </svg>'
) %>
```

### Different Sizes
```erb
<!-- Small -->
<%= render Ui::StatusBadgeComponent.new(status: 'active', size: :sm) %>

<!-- Default -->
<%= render Ui::StatusBadgeComponent.new(status: 'active') %>

<!-- Large -->
<%= render Ui::StatusBadgeComponent.new(status: 'active', size: :lg) %>
```

### Custom Color
```erb
<%= render Ui::StatusBadgeComponent.new(
  status: 'custom',
  color: 'purple'
) %>
```

### Custom CSS Classes
```erb
<%= render Ui::StatusBadgeComponent.new(
  status: 'active',
  class: 'ml-2 shadow-sm'
) %>
```

## Replacing Inline Badge HTML

### Before (inline HTML):
```erb
<span class="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800">
  Actif
</span>
```

### After (using component):
```erb
<%= render Ui::StatusBadgeComponent.new(
  status: 'active',
  label: 'Actif'
) %>
```

### Before (with conditional coloring):
```erb
<span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium <%= 
  case user.role
  when 'super_admin' then 'bg-purple-100 text-purple-800'
  when 'admin' then 'bg-red-100 text-red-800'
  when 'manager' then 'bg-yellow-100 text-yellow-800'
  else 'bg-gray-100 text-gray-800'
  end %>">
  <%= user.role.humanize %>
</span>
```

### After (using component):
```erb
<%= render Ui::StatusBadgeComponent.new(
  status: user.role,
  color: case user.role
         when 'super_admin' then 'purple'
         when 'admin' then 'red'
         when 'manager' then 'yellow'
         else 'gray'
         end
) %>
```

## Predefined Status Colors

The component automatically maps common statuses to appropriate colors:

### Success States (Green)
- `success`, `completed`, `approved`, `active`, `published`, `on_track`

### Warning States (Yellow)
- `warning`, `pending`, `in_progress`, `processing`, `draft`, `on_hold`

### Error States (Red)
- `error`, `failed`, `rejected`, `overdue`, `delayed`

### Info States (Blue)
- `info`, `new`, `submitted`, `in_progress`

### Neutral States (Gray)
- `neutral`, `archived`, `cancelled`, `inactive`, `locked`, `not_started`

### Special States (Other Colors)
- `at_risk` (Orange)

## Migration Examples

### User Status (users/index.html.erb)
```erb
<!-- Before -->
<% if user.last_sign_in_at %>
  <span class="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800">
    Actif
  </span>
<% else %>
  <span class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-800">
    Jamais connecté
  </span>
<% end %>

<!-- After -->
<%= render Ui::StatusBadgeComponent.new(
  status: user.last_sign_in_at ? 'active' : 'inactive',
  label: user.last_sign_in_at ? 'Actif' : 'Jamais connecté'
) %>
```

### User Groups (user_groups/index.html.erb)
```erb
<!-- Before -->
<% if group.active? %>
  <span class="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800">
    Actif
  </span>
<% else %>
  <span class="inline-flex items-center rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-800">
    Inactif
  </span>
<% end %>

<!-- After -->
<%= render Ui::StatusBadgeComponent.new(
  status: group.active? ? 'active' : 'inactive',
  label: group.active? ? 'Actif' : 'Inactif'
) %>
```

### Group Type Badge
```erb
<!-- Before -->
<% if group.group_type.present? %>
  <span class="inline-flex items-center rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-800">
    <%= group.group_type.humanize %>
  </span>
<% end %>

<!-- After -->
<% if group.group_type.present? %>
  <%= render Ui::StatusBadgeComponent.new(
    status: group.group_type,
    color: 'blue'
  ) %>
<% end %>
```