---
name: tanstack-query-hooks
description: "Generate TanStack Query hooks for efficient server state management. Creates query hooks, mutation hooks with automatic cache invalidation, and handles loading/error states. Use when fetching data from APIs or databases in React components."
license: MIT
metadata:
  author: Perennia-Regeneracion
  version: "1.0.0"
---

# TanStack Query Hooks Builder

Generate production-ready data fetching hooks using TanStack Query (React Query) v5.

## Quick Start

### Step 1: Identify Data Type

Choose the appropriate hook pattern:

| Data Type | Pattern | Use Case |
|-----------|---------|----------|
| **Read-only data** | `useQuery` | Get users, get transactions, get products |
| **Create/Update/Delete** | `useMutation` | Create user, update transaction, delete product |
| **Paginated lists** | `useInfiniteQuery` | Infinite scroll, load more |
| **Dependent queries** | Chained `useQuery` | Fetch user → then user's posts |

### Step 2: Define Query Key Strategy

**CRITICAL**: Query keys enable automatic cache invalidation.

```typescript
// ✅ Hierarchical keys (RECOMMENDED)
QUERY_KEYS.users.root(estId)           // ['users', 'est-123']
QUERY_KEYS.users.detail(estId, userId) // ['users', 'est-123', 'detail', 'user-456']

// ❌ Flat keys (avoid)
['users']  // Can't target specific user
```

See [Query Keys Architecture](../../../client/src/lib/queryKeys.ts) for centralized keys.

### Step 3: Generate Hook

Provide hook specifications:
```
Hook: useTransacciones
Type: query
Entity: transacciones
Params: entityId
Returns: transacciones[], loading, error
```

Receive complete hook with:
- TanStack Query integration
- Automatic cache management
- Error handling
- TypeScript types
- Loading/success/error states

## Core Standards

### Required Imports
```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { QUERY_KEYS } from '@/lib/queryKeys';
import { supabase } from '@/lib/supabase';
```

### Query Pattern
```typescript
const { data, isLoading, error, refetch } = useQuery({
  queryKey: QUERY_KEYS.entity.root(id),
  queryFn: async () => {
    const { data, error } = await supabase
      .from('table')
      .select('*')
      .eq('id', id);

    if (error) throw error;
    return data;
  },
  enabled: !!id,  // Only run if id exists
  staleTime: 5 * 60 * 1000,  // 5 minutes
});
```

### Mutation Pattern
```typescript
const mutation = useMutation({
  mutationFn: async (data) => {
    const { data: result, error } = await supabase
      .from('table')
      .insert(data)
      .select()
      .single();

    if (error) throw error;
    return result;
  },
  onSuccess: () => {
    // ✅ CRITICAL: Invalidate related queries
    queryClient.invalidateQueries({
      queryKey: QUERY_KEYS.entity.root(id)
    });
  }
});
```

## Decision Tree

### When to Use useQuery

**Use for:**
- ✅ Fetching lists (users, products, transactions)
- ✅ Fetching single items (user detail, product detail)
- ✅ Fetching computed data (dashboards, reports)
- ✅ Data that changes infrequently

**Benefits:**
- Automatic caching
- Background refetching
- Deduplication (same query = single request)
- Optimistic UI updates

### When to Use useMutation

**Use for:**
- ✅ Creating records (POST)
- ✅ Updating records (PUT/PATCH)
- ✅ Deleting records (DELETE)
- ✅ Any action that modifies server state

**Benefits:**
- Automatic query invalidation
- Loading/success/error states
- Optimistic updates support
- Retry on failure

### When to Use useState (NOT TanStack Query)

**Use for:**
- ✅ UI-only state (modal open/closed, selected tab)
- ✅ Form field values (before submit)
- ✅ Client-side filters (doesn't affect server)

**Rule of Thumb:**
> If it comes from the server → TanStack Query
> If it's only UI state → useState

## Configuration

### Global Settings (queryClient.ts)

```typescript
import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,      // 5 min cache
      gcTime: 10 * 60 * 1000,        // 10 min garbage collection
      refetchOnWindowFocus: true,    // Refetch on tab focus
      retry: 3,                      // Retry 3 times on error
      refetchOnMount: false,         // Don't refetch if cache fresh
    },
    mutations: {
      retry: 1,                      // Retry mutations once
    }
  }
});
```

### DevTools (Development Only)

```typescript
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

<QueryClientProvider client={queryClient}>
  <App />
  <ReactQueryDevtools initialIsOpen={false} />
</QueryClientProvider>
```

## Templates

### Basic Query Hook
See [TEMPLATES.md](TEMPLATES.md#basic-query-hook)

### Mutation Hook with Invalidation
See [TEMPLATES.md](TEMPLATES.md#mutation-hook)

### Dependent Queries
See [TEMPLATES.md](TEMPLATES.md#dependent-queries)

### Infinite Query (Pagination)
See [TEMPLATES.md](TEMPLATES.md#infinite-query)

## Advanced Patterns

### Optimistic Updates
See [PATTERNS.md](PATTERNS.md#optimistic-updates)

### Parallel Queries
See [PATTERNS.md](PATTERNS.md#parallel-queries)

### Query Invalidation Strategies
See [PATTERNS.md](PATTERNS.md#invalidation-strategies)

## Migration from Legacy Hooks

If you have existing hooks using `useState` + `useEffect`:

See [INTEGRATION.md](INTEGRATION.md) for step-by-step migration guide.

## Checklist

When generating TanStack Query hooks, verify:
- [ ] Uses centralized `QUERY_KEYS` from `/lib/queryKeys.ts`
- [ ] Query has appropriate `staleTime` (default 5 min)
- [ ] Query uses `enabled` flag for conditional fetching
- [ ] Mutation invalidates related queries in `onSuccess`
- [ ] Error handling with proper error messages
- [ ] TypeScript types for data and params
- [ ] Loading states handled in component
- [ ] Success/error notifications on mutations

## Anti-patterns to Avoid

- Using useState for server data
- Not invalidating queries after mutations
- Missing `enabled` flag on conditional queries
- Hardcoded query keys (use QUERY_KEYS)
- Fetching in useEffect (use useQuery)
- Not handling loading/error states
- Refetching manually when invalidation is better

## Examples

### Example 1: Simple List Hook
```typescript
Type: query
Entity: proveedores
Params: entityId
```

Result: Complete hook fetching provider list with cache.

### Example 2: Create Mutation
```typescript
Type: mutation
Action: createProveedor
Invalidates: proveedores list
```

Result: Mutation hook with auto-invalidation and loading states.

### Example 3: Detail Query with Dependencies
```typescript
Type: query
Entity: childDetail
Params: entityId, childId
DependsOn: entityId exists
```

Result: Query that only runs when dependencies are met.
