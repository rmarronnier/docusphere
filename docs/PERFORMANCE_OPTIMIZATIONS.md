# Performance Optimizations - DocuSphere

## Overview

This document describes the performance optimizations implemented in DocuSphere to improve response times and reduce database load.

## 1. Database Indexes

### Added Indexes (Migration: 20250610000002_add_performance_indexes.rb)

#### Authorization Queries
- `index_authorizations_on_authorizable_and_user` - Composite index on authorizable_type, authorizable_id, and user_id
- `index_authorizations_on_authorizable_and_group` - Composite index on authorizable_type, authorizable_id, and user_group_id

#### Document Queries
- `index_documents_on_space_id_and_status` - Composite index for filtering documents by space and status

#### Validation Queries
- `index_validation_requests_on_validatable_and_status` - Composite index for polymorphic validations
- `index_document_validations_on_validatable_and_status` - Composite index for document validations

#### Notification Queries
- `index_notifications_on_user_id_and_read_at` - For unread notifications by user
- `index_notifications_on_notification_type_and_created_at` - For filtering by type and date

#### Other Queries
- `index_folders_on_space_id_and_parent_id` - For folder hierarchy navigation
- `index_user_group_memberships_on_user_id_and_role` - For role-based queries
- `index_document_tags_on_document_id_and_tag_id` - Unique index for tag associations

## 2. Caching Strategy

### Permission Cache Service

The `PermissionCacheService` caches authorization checks to reduce database queries:

```ruby
# Usage in Authorizable concern
def authorized_for?(user, permission_level)
  PermissionCacheService.authorized_for?(self, user, permission_level)
end
```

**Features:**
- 5-minute TTL for permission cache
- Automatic cache invalidation on permission changes
- Support for both user and group permissions
- Redis-compatible cache clearing

**Cache Keys:**
- Pattern: `permissions:{Model}:{id}:user:{user_id}:{permission_level}`
- Example: `permissions:Document:123:user:456:read`

### Tree Path Cache Service

The `TreePathCacheService` caches ancestry paths for hierarchical models:

```ruby
# Usage in Treeable concern
def ancestors
  return [] if root?
  TreePathCacheService.path_for(self)
end
```

**Features:**
- 1-hour TTL for path cache
- Automatic cache invalidation on parent changes
- Cascading cache clear for descendants

**Cache Keys:**
- Pattern: `tree_paths:{Model}:{id}`
- Example: `tree_paths:Folder:789`

### Progress Cache Service (Immo::Promo)

The `Immo::Promo::ProgressCacheService` caches project and phase progress calculations:

```ruby
# Usage
progress = Immo::Promo::ProgressCacheService.project_progress(project)
```

**Features:**
- 10-minute TTL for progress calculations
- Separate caching for project and phase progress
- Automatic invalidation on task/phase updates

## 3. Query Optimizations

### Scope Optimizations

The `readable_by` and `writable_by` scopes have been optimized to use subqueries:

```ruby
scope :readable_by, ->(user) {
  direct_ids = joins(:active_authorizations)
    .where(authorizations: { user_id: user.id, permission_level: ['read', 'write', 'admin'] })
    .pluck(:id)
  
  group_ids = joins(active_authorizations: { user_group: :users })
    .where(users: { id: user.id })
    .where(authorizations: { permission_level: ['read', 'write', 'admin'] })
    .pluck(:id)
  
  where(id: (direct_ids + group_ids).uniq)
}
```

### Active Authorization Scope

Fixed ambiguous column issues in Authorization model:

```ruby
scope :active, -> { 
  where(revoked_at: nil)
    .where('authorizations.expires_at IS NULL OR authorizations.expires_at > ?', Time.current) 
}
```

## 4. Best Practices

### When to Clear Cache

1. **Permission Changes:**
   - When granting/revoking permissions
   - When adding/removing users from groups
   - When modifying authorization expiry

2. **Hierarchy Changes:**
   - When moving folders/documents
   - When changing parent relationships
   - When deleting nodes with children

3. **Progress Updates:**
   - When task status changes
   - When phase completion updates
   - When project milestones are reached

### Cache Warming

For frequently accessed resources, consider warming the cache:

```ruby
# Example rake task
task warm_permission_cache: :environment do
  User.active.find_each do |user|
    user.accessible_documents.find_each do |doc|
      PermissionCacheService.authorized_for?(doc, user, 'read')
    end
  end
end
```

## 5. Monitoring

### Key Metrics to Track

1. **Cache Hit Rate:**
   - Monitor Redis STATS to track cache effectiveness
   - Target: > 80% hit rate for permissions

2. **Query Performance:**
   - Monitor slow query logs
   - Track N+1 query patterns
   - Use bullet gem in development

3. **Response Times:**
   - Document list views
   - Permission checks
   - Tree navigation

### Performance Testing

```ruby
# Example performance test
RSpec.describe "Permission Performance", type: :performance do
  it "caches permission checks effectively" do
    user = create(:user)
    documents = create_list(:document, 100)
    
    # Warm cache
    documents.each { |doc| doc.readable_by?(user) }
    
    # Measure cached performance
    expect {
      documents.each { |doc| doc.readable_by?(user) }
    }.to perform_under(50).ms
  end
end
```

## 6. Future Optimizations

### Planned Improvements

1. **Batch Permission Checks:**
   - Load multiple permissions in single query
   - Useful for document lists

2. **Materialized Views:**
   - For complex permission hierarchies
   - For frequently calculated aggregates

3. **Background Cache Warming:**
   - Sidekiq jobs for cache maintenance
   - Scheduled cache refresh for hot data

4. **Read Replicas:**
   - Route read-heavy queries to replicas
   - Reduce load on primary database

### Configuration Tuning

1. **Connection Pooling:**
   ```yaml
   # database.yml
   pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
   ```

2. **Redis Configuration:**
   ```ruby
   # config/initializers/redis.rb
   Redis.new(
     url: ENV['REDIS_URL'],
     pool_size: 10,
     pool_timeout: 5
   )
   ```

3. **Cache Store Configuration:**
   ```ruby
   # config/environments/production.rb
   config.cache_store = :redis_cache_store, {
     url: ENV['REDIS_URL'],
     expires_in: 1.hour,
     race_condition_ttl: 5.seconds
   }
   ```