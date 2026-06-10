# Migrating from Legacy Hooks to TanStack Query

Step-by-step guide for migrating existing `useState` + `useEffect` hooks to TanStack Query.

## Migration Strategy

### Phase 1: Preparation (Do Once)
1. ✅ Install TanStack Query devtools
2. ✅ Create centralized `QUERY_KEYS` file
3. ✅ Configure `queryClient` with defaults
4. ✅ Wrap app with `QueryClientProvider`

### Phase 2: Gradual Migration (Per Hook)
1. Identify hook to migrate
2. Create TanStack Query version
3. Update components to use new hook
4. Remove legacy hook when all usages migrated

### Phase 3: Cleanup
1. Remove unused legacy hooks
2. Remove manual refetch calls
3. Remove `useQueryInvalidationListener` (bridge hook)

---

## Step-by-Step Migration Example

### BEFORE: Legacy Hook with useState

```typescript
// ❌ OLD: hooks/useTransacciones.ts (useState pattern)
import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';

export function useTransacciones(entityId?: string) {
  // Manual state management
  const [transacciones, setTransacciones] = useState<Transaccion[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Manual fetch function
  const fetchTransacciones = async () => {
    try {
      setLoading(true);
      setError(null);

      if (!entityId) {
        setTransacciones([]);
        return;
      }

      const { data, error: fetchError } = await supabase
        .from('transaccion')
        .select('*')
        .eq('entity_id', entityId)
        .eq('is_deleted', false)
        .order('fecha', { ascending: false });

      if (fetchError) throw fetchError;

      // Manual post-processing
      const processed = data.map(t => ({
        ...t,
        // ... transformations
      }));

      setTransacciones(processed);

    } catch (error) {
      console.error('Error:', error);
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };

  // Manual effect
  useEffect(() => {
    fetchTransacciones();
  }, [entityId]);

  // Manual CRUD functions
  const createTransaccion = async (data: any) => {
    const { error } = await supabase.from('transaccion').insert(data);
    if (error) throw error;
    await fetchTransacciones();  // ← Manual refetch
  };

  return {
    transacciones,
    loading,
    error,
    refetch: fetchTransacciones,
    createTransaccion,
  };
}
```

**Problems:**
- 🐛 50+ lines of boilerplate
- 🔄 Manual refetch after mutations
- 🚫 No cache (every component instance fetches independently)
- ⏱️ No background refetch
- 🤝 No shared state between components

---

### AFTER: TanStack Query Hook

```typescript
// ✅ NEW: hooks/useTransacciones.ts (TanStack Query)
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNotifications } from '@/hooks/use-notifications';
import { QUERY_KEYS } from '@/lib/queryKeys';
import { supabase } from '@/lib/supabase';

export function useTransacciones(entityId?: string) {
  const queryClient = useQueryClient();
  const notifications = useNotifications();

  // ✅ Query: Automatic cache, loading, error handling
  const {
    data: transacciones = [],
    isLoading: loading,
    error,
    refetch
  } = useQuery({
    queryKey: QUERY_KEYS.transacciones.root(entityId || ''),

    queryFn: async () => {
      if (!entityId) return [];

      const { data, error: fetchError } = await supabase
        .from('transaccion')
        .select('*')
        .eq('entity_id', entityId)
        .eq('is_deleted', false)
        .order('fecha', { ascending: false });

      if (fetchError) throw fetchError;

      // Same post-processing
      return data.map(t => ({
        ...t,
        // ... transformations
      }));
    },

    enabled: !!entityId,
    staleTime: 5 * 60 * 1000,  // 5 min cache
  });

  // ✅ Mutation: Automatic invalidation
  const createMutation = useMutation({
    mutationFn: async (data: any) => {
      const { error } = await supabase.from('transaccion').insert(data);
      if (error) throw error;
    },

    onSuccess: () => {
      // ✅ Automatic refetch (no manual call needed)
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.transacciones.root(entityId || '')
      });

      notifications.showSuccess("¡Creado!", "Transacción creada");
    }
  });

  return {
    transacciones,
    loading,
    error,
    refetch,
    createTransaccion: createMutation.mutate,
    isCreating: createMutation.isPending,
  };
}
```

**Benefits:**
- ✅ ~20 lines vs 50+ lines (60% less code)
- ✅ Automatic cache sharing
- ✅ Automatic refetch after mutations
- ✅ Background updates
- ✅ Better TypeScript types
- ✅ DevTools for debugging

---

## Component Migration

### BEFORE: Component with Legacy Hook

```typescript
// ❌ OLD: Component uses legacy hook
function TransaccionesPage() {
  const { entityActivo } = useAuth();
  const { transacciones, loading, createTransaccion } = useTransacciones(
    entityActivo?.id
  );

  const handleCreate = async (data: FormData) => {
    await createTransaccion(data);
    // Hook refetches internally
  };

  if (loading) return <Spinner />;

  return (
    <div>
      <DataTable data={transacciones} />
      <Button onClick={handleCreate}>Crear</Button>
    </div>
  );
}
```

---

### AFTER: Component with TanStack Query Hook

```typescript
// ✅ NEW: Same component code (zero changes!)
function TransaccionesPage() {
  const { entityActivo } = useAuth();
  const { transacciones, loading, createTransaccion } = useTransacciones(
    entityActivo?.id
  );

  const handleCreate = async (data: FormData) => {
    createTransaccion(data);  // ← No await needed (mutation handles it)
  };

  if (loading) return <Spinner />;

  return (
    <div>
      <DataTable data={transacciones} />
      <Button onClick={handleCreate}>Crear</Button>
    </div>
  );
}
```

**✅ Zero changes in component!** The hook API stays the same.

---

## Handling Multiple Components

### Problem with Legacy Hooks

```typescript
// ❌ Each component has independent state
function TransaccionesTab() {
  const { transacciones } = useTransacciones(estId);  // Instance A
  // Shows: [txn1, txn2]
}

function DashboardWidget() {
  const { transacciones } = useTransacciones(estId);  // Instance B (independent!)
  // Shows: [txn1, txn2] (fetches again from server)
}

// User creates transaction in TransaccionesTab
// → Instance A refetches → shows [txn1, txn2, txn3]
// → Instance B NOT updated → still shows [txn1, txn2] ❌
```

---

### Solution with TanStack Query

```typescript
// ✅ Both components share the same cache
function TransaccionesTab() {
  const { transacciones } = useTransacciones(estId);
  // Cache key: ['transacciones', 'est-123']
}

function DashboardWidget() {
  const { transacciones } = useTransacciones(estId);
  // Same cache key: ['transacciones', 'est-123']
  // ✅ NO additional fetch - uses existing cache
}

// User creates transaction
// → queryClient.invalidateQueries(['transacciones', 'est-123'])
// → BOTH components refetch automatically ✅
```

---

## Bridge Pattern (Temporary)

If you can't migrate all components at once, use a bridge hook:

### Bridge Hook: Listen to TanStack Query from Legacy Hook

```typescript
// hooks/useQueryInvalidationListener.ts
import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';

export function useQueryInvalidationListener(
  queryKey: readonly unknown[],
  callback: () => void
) {
  const queryClient = useQueryClient();

  useEffect(() => {
    const unsubscribe = queryClient.getQueryCache().subscribe((event) => {
      if (event?.type === 'updated' && event?.action?.type === 'invalidate') {
        const invalidatedKey = event.query.queryKey;

        const matches = queryKey.every((keyPart, index) => {
          return invalidatedKey[index] === keyPart;
        });

        if (matches) {
          callback();  // ← Trigger legacy hook's refetch
        }
      }
    });

    return unsubscribe;
  }, [queryClient, queryKey, callback]);
}
```

### Usage in Legacy Component

```typescript
// Component still using legacy hook
function PagosYCobrosTab() {
  const { transacciones, refetch } = useTransaccionesLegacy(estId);

  // ✅ Bridge: Listen to TanStack Query invalidations
  useQueryInvalidationListener(
    QUERY_KEYS.transacciones.root(estId),
    refetch  // ← Trigger legacy refetch
  );

  // Now responds to TanStack Query mutations!
  return <DataTable data={transacciones} />;
}
```

**Remove bridge once all components migrated.**

---

## Migration Checklist

### Per Hook Migration

- [ ] Create new TanStack Query version of hook
- [ ] Define query key in `QUERY_KEYS`
- [ ] Implement `useQuery` for fetching
- [ ] Implement `useMutation` for CRUD operations
- [ ] Add query invalidation in mutation `onSuccess`
- [ ] Test with DevTools (verify cache updates)
- [ ] Update components to use new hook
- [ ] Remove legacy hook file
- [ ] Remove manual refetch calls
- [ ] Remove bridge hooks if used

### Testing After Migration

- [ ] Verify data loads correctly
- [ ] Create new entity → check all views update
- [ ] Update entity → check all views update
- [ ] Delete entity → check all views update
- [ ] Check DevTools for query states
- [ ] Check DevTools for cache updates
- [ ] Test with multiple components open
- [ ] Test with slow network (DevTools → Network)
- [ ] Verify no duplicate requests

---

## Common Migration Pitfalls

### Pitfall 1: Forgetting `enabled` Flag

```typescript
// ❌ WRONG: Runs even if ID is undefined
useQuery({
  queryKey: ['users', userId],
  queryFn: () => fetchUser(userId),  // ← Error if userId is undefined
});

// ✅ CORRECT: Only runs if ID exists
useQuery({
  queryKey: ['users', userId],
  queryFn: () => fetchUser(userId!),
  enabled: !!userId,  // ← Wait for ID
});
```

### Pitfall 2: Not Invalidating After Mutation

```typescript
// ❌ WRONG: No invalidation → UI doesn't update
useMutation({
  mutationFn: createUser,
  onSuccess: () => {
    notifications.showSuccess("Created!");
    // ❌ Missing invalidation
  }
});

// ✅ CORRECT: Invalidate to trigger refetch
useMutation({
  mutationFn: createUser,
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['users'] });
    notifications.showSuccess("Created!");
  }
});
```

### Pitfall 3: Using Wrong Query Key

```typescript
// ❌ WRONG: Hardcoded key doesn't match centralized key
queryClient.invalidateQueries({ queryKey: ['users'] });
// But query uses: QUERY_KEYS.users.all(estId) → ['users', 'est-123']
// ❌ Doesn't match → no refetch

// ✅ CORRECT: Use centralized key
queryClient.invalidateQueries({
  queryKey: QUERY_KEYS.users.root(estId)  // Matches all user queries
});
```

### Pitfall 4: Async/Await on Mutations

```typescript
// ❌ WRONG: Using await blocks UI unnecessarily
const handleCreate = async () => {
  await mutation.mutate(data);  // ❌ Returns void, no point in awaiting
};

// ✅ CORRECT: Let mutation handle it
const handleCreate = () => {
  mutation.mutate(data, {
    onSuccess: () => {
      console.log("Created!");
    }
  });
};
```

---

## Performance Considerations

### Before Migration (Legacy)

```
Component A mounts → Fetch from server (500ms)
Component B mounts → Fetch from server again (500ms)
Total: 1000ms + 2 requests
```

### After Migration (TanStack Query)

```
Component A mounts → Fetch from server (500ms) → Cache
Component B mounts → Read from cache (instant) → 0ms
Total: 500ms + 1 request ✅
```

**Result:** 50% faster, 50% fewer requests.

---

## When Migration is Complete

Remove these temporary files:
- ✅ `useQueryInvalidationListener.ts` (bridge hook)
- ✅ All legacy `useState` hooks
- ✅ Manual refetch calls

Enjoy the benefits:
- 🚀 Automatic cache management
- 🔄 Automatic refetch on mutations
- ⚡ Instant data from cache
- 🎯 Single source of truth
- 🛠️ DevTools for debugging
- 📉 60% less boilerplate code
