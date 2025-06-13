# Form Field Components

This documentation covers the enhanced form field component suite designed to replace repeated form patterns and provide consistent, accessible form elements across the application.

## Architecture

All form field components inherit from the base `Forms::FieldComponent`, which provides:
- Consistent labeling and styling
- Error handling and display
- ARIA attributes for accessibility
- Inline vs stacked layout options
- Hint text support

## Base Component: Forms::FieldComponent

The foundation component that all other form components inherit from.

### Options

- `form`: Rails form builder instance (required)
- `attribute`: The model attribute name (required)
- `label`: Custom label text (optional, defaults to humanized attribute)
- `hint`: Help text displayed below the field (optional)
- `required`: Marks field as required and adds asterisk to label (default: false)
- `wrapper_class`: CSS classes for the wrapper div (default: 'mb-4')
- `layout`: Layout style - `:stacked` or `:inline` (default: :stacked)

### Example

```erb
<%= render Forms::FieldComponent.new(
      form: form, 
      attribute: :name,
      label: 'Full Name',
      hint: 'Enter your complete legal name',
      required: true,
      layout: :inline
    ) %>
```

## Enhanced Components

### 1. Forms::TextFieldComponent

Enhanced text input with support for different input types.

#### Additional Options

- `type`: Input type - `:text`, `:email`, `:password`, `:number`, `:tel`, `:url`, `:date`, `:time`, `:datetime` (default: :text)
- `placeholder`: Placeholder text
- `autocomplete`: Autocomplete attribute

#### Example

```erb
<%= render Forms::TextFieldComponent.new(
      form: form,
      attribute: :email,
      type: :email,
      label: 'Email Address',
      hint: 'We will never share your email',
      required: true,
      placeholder: 'your@email.com',
      autocomplete: 'email'
    ) %>
```

### 2. Forms::SelectComponent

Enhanced select dropdown with optional search functionality.

#### Additional Options

- `options`: Array of options or options_for_select string (required)
- `include_blank`: Add blank option (default: false)
- `prompt`: Prompt text for empty selection
- `multiple`: Allow multiple selections (default: false)
- `searchable`: Enable search/filter functionality (default: false)

#### Example

```erb
<%# Standard Select %>
<%= render Forms::SelectComponent.new(
      form: form,
      attribute: :country,
      options: [['United States', 'US'], ['Canada', 'CA']],
      label: 'Country',
      required: true,
      prompt: 'Select a country...'
    ) %>

<%# Searchable Select %>
<%= render Forms::SelectComponent.new(
      form: form,
      attribute: :category,
      options: Category.all.map { |c| [c.name, c.id] },
      label: 'Category',
      searchable: true,
      hint: 'Search and select a category'
    ) %>
```

### 3. Forms::TextAreaComponent

Enhanced textarea with auto-resize and character counting.

#### Additional Options

- `rows`: Number of rows (default: 3)
- `placeholder`: Placeholder text
- `resize`: Allow manual resize (default: true)
- `auto_resize`: Enable automatic height adjustment (default: false)
- `character_count`: Show character count (default: false)
- `max_length`: Maximum character limit for validation

#### Example

```erb
<%= render Forms::TextAreaComponent.new(
      form: form,
      attribute: :description,
      label: 'Description',
      hint: 'Provide a detailed description',
      rows: 4,
      auto_resize: true,
      character_count: true,
      max_length: 500,
      placeholder: 'Enter description...'
    ) %>
```

### 4. Forms::FileFieldComponent

Advanced file upload with drag-and-drop, preview, and progress tracking.

#### Additional Options

- `accept`: File type restrictions (e.g., 'image/*,.pdf')
- `multiple`: Allow multiple file selection (default: false)
- `drag_drop`: Enable drag-and-drop interface (default: true)
- `preview`: Show selected file preview (default: true)
- `progress`: Show upload progress (default: true)
- `max_file_size`: Maximum file size in bytes
- `max_files`: Maximum number of files

#### Example

```erb
<%= render Forms::FileFieldComponent.new(
      form: form,
      attribute: :documents,
      label: 'Upload Documents',
      hint: 'Drag and drop files or click to browse',
      accept: '.pdf,.doc,.docx,.jpg,.png',
      multiple: true,
      max_file_size: 10.megabytes,
      max_files: 5,
      required: true
    ) %>
```

## JavaScript Controllers

The enhanced components use Stimulus controllers for interactive functionality:

### SearchableController
- **Purpose**: Handles searchable select functionality
- **Targets**: `input`, `dropdown`, `option`, `select`
- **Actions**: Filter options, handle selection, update hidden select

### AutoResizeController
- **Purpose**: Automatically adjusts textarea height
- **Actions**: Resize on input, maintain min/max height

### CharacterCountController
- **Purpose**: Displays real-time character count
- **Targets**: `counter`
- **Actions**: Update count on input, color coding based on remaining characters

### FileUploadController
- **Purpose**: Handles drag-and-drop file upload
- **Targets**: `dropZone`, `input`, `fileList`, `progressArea`, `progressBar`, `errorArea`
- **Actions**: Drag/drop handling, file validation, progress tracking

## Usage Examples

### Complete Form Example

```erb
<%= form_with model: @document, local: false do |form| %>
  <div class="space-y-6">
    <%# Standard text field %>
    <%= render Forms::TextFieldComponent.new(
          form: form,
          attribute: :title,
          label: 'Document Title',
          required: true
        ) %>

    <%# Searchable select %>
    <%= render Forms::SelectComponent.new(
          form: form,
          attribute: :category_id,
          options: options_from_collection_for_select(Category.all, :id, :name),
          label: 'Category',
          searchable: true,
          required: true
        ) %>

    <%# Auto-resizing textarea with character count %>
    <%= render Forms::TextAreaComponent.new(
          form: form,
          attribute: :description,
          label: 'Description',
          auto_resize: true,
          character_count: true,
          max_length: 1000
        ) %>

    <%# Advanced file upload %>
    <%= render Forms::FileFieldComponent.new(
          form: form,
          attribute: :file,
          label: 'Document File',
          accept: '.pdf,.doc,.docx',
          max_file_size: 5.megabytes,
          required: true
        ) %>
  </div>

  <div class="mt-6">
    <%= form.submit 'Save Document', class: 'btn btn-primary' %>
  </div>
<% end %>
```

### Inline Layout Example

```erb
<%= form_with model: @user do |form| %>
  <%# Inline layout for compact forms %>
  <%= render Forms::TextFieldComponent.new(
        form: form,
        attribute: :first_name,
        label: 'First Name',
        layout: :inline,
        required: true
      ) %>

  <%= render Forms::TextFieldComponent.new(
        form: form,
        attribute: :last_name,
        label: 'Last Name',
        layout: :inline,
        required: true
      ) %>

  <%= render Forms::SelectComponent.new(
        form: form,
        attribute: :role,
        options: User.roles.keys.map { |role| [role.humanize, role] },
        label: 'Role',
        layout: :inline
      ) %>
<% end %>
```

## Migration from Existing Forms

To migrate existing forms to use the new components:

1. **Replace basic inputs**:
   ```erb
   <!-- Old -->
   <%= form.text_field :title, class: 'form-control', required: true %>
   
   <!-- New -->
   <%= render Forms::TextFieldComponent.new(
         form: form,
         attribute: :title,
         required: true
       ) %>
   ```

2. **Replace select fields**:
   ```erb
   <!-- Old -->
   <%= form.select :category_id, options_for_select(...), {}, { class: 'form-control' } %>
   
   <!-- New -->
   <%= render Forms::SelectComponent.new(
         form: form,
         attribute: :category_id,
         options: options_for_select(...),
         searchable: true
       ) %>
   ```

3. **Replace file uploads**:
   ```erb
   <!-- Old -->
   <%= form.file_field :document, class: 'form-control' %>
   
   <!-- New -->
   <%= render Forms::FileFieldComponent.new(
         form: form,
         attribute: :document,
         drag_drop: true,
         preview: true
       ) %>
   ```

## Styling and Customization

All components use Tailwind CSS classes and follow the application's design system:

- **Colors**: Indigo for primary actions, gray for neutrals, red for errors
- **Spacing**: Consistent padding and margins using Tailwind scale
- **Typography**: Standard font sizes and weights
- **Focus States**: Proper focus rings for accessibility

### Custom Styling

You can extend component styling by:

1. **Adding custom CSS classes**:
   ```erb
   <%= render Forms::TextFieldComponent.new(
         form: form,
         attribute: :name,
         class: 'custom-input-class'
       ) %>
   ```

2. **Customizing wrapper classes**:
   ```erb
   <%= render Forms::TextFieldComponent.new(
         form: form,
         attribute: :name,
         wrapper_class: 'mb-8 border-l-4 border-blue-500 pl-4'
       ) %>
   ```

## Accessibility Features

All components include proper accessibility features:

- **ARIA labels and descriptions**
- **Proper focus management**
- **Screen reader friendly error messages**
- **Keyboard navigation support**
- **High contrast support**

## Testing

Each component has comprehensive test coverage including:

- **Rendering tests**: Verify proper HTML output
- **Option tests**: Test all configuration options
- **Error handling**: Test error display and styling
- **Accessibility tests**: ARIA attributes and labels
- **JavaScript functionality**: Stimulus controller behavior

Run component tests:
```bash
bundle exec rspec spec/components/forms/
```

## Performance Considerations

- **Lazy loading**: JavaScript controllers load only when needed
- **Efficient rendering**: Components minimize DOM manipulation
- **Memory management**: Proper cleanup of event listeners
- **Bundle optimization**: JavaScript is split by functionality

## Browser Support

The components support:
- **Modern browsers**: Chrome, Firefox, Safari, Edge (latest versions)
- **Progressive enhancement**: Basic functionality without JavaScript
- **Mobile responsive**: Touch-friendly interfaces
- **Accessibility tools**: Screen readers and keyboard navigation