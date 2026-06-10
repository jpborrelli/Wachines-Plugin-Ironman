# Advanced TanStack Query Patterns

Advanced patterns for complex data fetching scenarios.

## Optimistic Updates

Update UI immediately before server confirms (with rollback on error).

### Pattern: Optimistic Create

```typescript
export function useCreateProveedorOptimistic(entityId: string) {
  const queryClient = useQueryClient();
  const notifications = useNotifications();

  const mutation = useMutation({
    mutationFn: async (newProveedor: CreateProveedorData) => {
      const { data, error } = await supabase
        .from('proveedor')
        .insert(newProveedor)
        .select()
        .single();

      if (error) throw error;
      return data;
    },

    // 🎯 OPTIMISTIC UPDATE: Before server responds
    onMutate: async (newProveedor) => {
      // 1. Cancel any outgoing refetches
      await queryClient.cancelQueries({
        queryKey: QUERY_KEYS.proveedores.all(entityId)
      });

      // 2. Snapshot current state (for rollback)
      const previousProveedores = queryClient.getQueryData(
        QUERY_KEYS.proveedores.all(entityId)
      );

      // 3. Optimistically update cache
      queryClient.setQueryData(
        QUERY_KEYS.proveedores.all(entityId),
        (old: Proveedor[] = []) => [
          ...old,
          { ...newProveedor, id: `temp-${Date.now()}` }  // Temp ID
        ]
      );

      // Return context for rollback
      return { previousProveedores };
    },

    // ❌ ROLLBACK: If mutation fails
    onError: (err, newProveedor, context) => {
      // Restore previous state
      queryClient.setQueryData(
        QUERY_KEYS.proveedores.all(entityId),
        context?.previousProveedores
      );

      notifications.showError(
        "Error al crear proveedor",
        "Se revirtieron los cambios"
      );
    },

    // ✅ SUCCESS: Replace temp data with real data
    onSettled: () => {
      // Always refetch to ensure sync with server
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.proveedores.root(entityId)
      });
    }
  });

  return {
    createProveedor: mutation.mutate,
    isCreating: mutation.isPending,
  };
}
```

**Benefits:**
- ⚡ Instant UI feedback (no waiting for server)
- 🔄 Automatic rollback on error
- 🎯 Guaranteed sync with server

**Use when:**
- UI needs to feel instant
- Operation has high success rate
- User expects immediate feedback

---

## Parallel Queries

Fetch multiple independent queries simultaneously.

### Pattern: Multiple Entities in Parallel

```typescript
export function useDashboardData(entityId: string) {
  // ✅ All queries run in parallel (not sequential)
  const proveedoresQuery = useQuery({
    queryKey: QUERY_KEYS.proveedores.all(entityId),
    queryFn: () => fetchProveedores(entityId),
  });

  const transaccionesQuery = useQuery({
    queryKey: QUERY_KEYS.transacciones.root(entityId),
    queryFn: () => fetchTransacciones(entityId),
  });

  const lotesQuery = useQuery({
    queryKey: QUERY_KEYS.lotes.all(entityId),
    queryFn: () => fetchLotes(entityId),
  });

  return {
    proveedores: proveedoresQuery.data ?? [],
    transacciones: transaccionesQuery.data ?? [],
    lotes: lotesQuery.data ?? [],

    // ✅ Combined loading state
    isLoading:
      proveedoresQuery.isLoading ||
      transaccionesQuery.isLoading ||
      lotesQuery.isLoading,

    // ✅ Any error from any query
    error:
      proveedoresQuery.error ||
      transaccionesQuery.error ||
      lotesQuery.error,
  };
}
```

**Alternative: useQueries for dynamic lists**

```typescript
export function useMultipleProveedores(proveedorIds: string[]) {
  const queries = useQueries({
    queries: proveedorIds.map(id => ({
      queryKey: QUERY_KEYS.proveedores.detail(entityId, id),
      queryFn: () => fetchProveedorDetail(id),
    })),
  });

  return {
    proveedores: queries.map(q => q.data).filter(Boolean),
    isLoading: queries.some(q => q.isLoading),
    errors: queries.map(q => q.error).filter(Boolean),
  };
}
```

---

## Query Invalidation Strategies

Different strategies for when to invalidate cache.

### Strategy 1: Invalidate Root (ALL children)

```typescript
// ✅ Invalidates ALL transacciones queries
queryClient.invalidateQueries({
  queryKey: QUERY_KEYS.transacciones.root(estId)
});

// Refetches:
// - ['transacciones', 'est-123']
// - ['transacciones', 'est-123', 'children']
// - ['transacciones', 'est-123', 'pagos']
// - ['transacciones', 'est-123', 'detail', 'txn-456']
```

**Use when:** Mutation affects many related queries (e.g., create transaction).

### Strategy 2: Invalidate Specific Query

```typescript
// ✅ Only invalidates children query
queryClient.invalidateQueries({
  queryKey: QUERY_KEYS.transacciones.children(estId)
});

// Refetches ONLY:
// - ['transacciones', 'est-123', 'children']
```

**Use when:** Mutation only affects specific subset (e.g., update child status).

### Strategy 3: Invalidate Multiple Roots

```typescript
// ✅ Invalidate multiple independent hierarchies
queryClient.invalidateQueries({
  queryKey: QUERY_KEYS.transacciones.root(estId)
});
queryClient.invalidateQueries({
  queryKey: QUERY_KEYS.bancos.root(estId)
});

// Use when: Mutation affects multiple modules
// Example: Creating pago with cheque affects both transacciones and bancos
```

### Strategy 4: Set Data Directly (No Refetch)

```typescript
// ✅ Update cache without refetching
queryClient.setQueryData(
  QUERY_KEYS.proveedores.detail(estId, proveedorId),
  (old) => ({ ...old, nombre: "Nuevo Nombre" })
);

// NO refetch happens - use when:
// - You have fresh data from mutation response
// - You want instant update without server roundtrip
```

---

## Prefetching

Load data before user needs it (improve perceived performance).

### Pattern: Prefetch on Hover

```typescript
export function ProveedorListItem({ proveedor }) {
  const queryClient = useQueryClient();
  const { entityActivo } = useAuth();

  const handleMouseEnter = () => {
    // 🚀 Prefetch detail before user clicks
    queryClient.prefetchQuery({
      queryKey: QUERY_KEYS.proveedores.detail(
        entityActivo.id,
        proveedor.id
      ),
      queryFn: () => fetchProveedorDetail(proveedor.id),
      staleTime: 2 * 60 * 1000,  // Cache for 2 min
    });
  };

  return (
    <TableRow onMouseEnter={handleMouseEnter}>
      <TableCell>{proveedor.nombre}</TableCell>
      <TableCell>
        <Link to={`/proveedores/${proveedor.id}`}>Ver detalle</Link>
      </TableCell>
    </TableRow>
  );
}
```

**Result:** When user hovers, detail loads in background. When they click, it's instant (from cache).

### Pattern: Prefetch Next Page

```typescript
export function usePaginatedTransacciones(
  entityId: string,
  page: number
) {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: QUERY_KEYS.transacciones.page(entityId, page),
    queryFn: () => fetchTransaccionesPage(entityId, page),
  });

  // 🚀 Prefetch next page proactively
  useEffect(() => {
    if (query.data?.hasNextPage) {
      queryClient.prefetchQuery({
        queryKey: QUERY_KEYS.transacciones.page(entityId, page + 1),
        queryFn: () => fetchTransaccionesPage(entityId, page + 1),
      });
    }
  }, [page, query.data?.hasNextPage, queryClient, entityId]);

  return query;
}
```

---

## Background Sync

Keep data fresh in the background without blocking UI.

### Pattern: Polling for Real-Time Updates

```typescript
export function useLiveTransacciones(entityId: string) {
  const query = useQuery({
    queryKey: QUERY_KEYS.transacciones.root(entityId),
    queryFn: () => fetchTransacciones(entityId),

    // ✅ Refetch every 30 seconds
    refetchInterval: 30 * 1000,

    // ✅ Only refetch if window is focused
    refetchIntervalInBackground: false,

    // ✅ Refetch when user returns to tab
    refetchOnWindowFocus: true,
  });

  return query;
}
```

**Use when:**
- Data changes frequently
- Multiple users editing same data
- Dashboard with live metrics

---

## Conditional Queries

Execute queries only when conditions are met.

### Pattern: Query Depends on Another Query

```typescript
export function useFacturaConPagos(
  entityId: string,
  childId?: string
) {
  // Query 1: Fetch child
  const childQuery = useQuery({
    queryKey: QUERY_KEYS.transacciones.detail(entityId, childId || ''),
    queryFn: () => fetchFactura(childId!),
    enabled: !!childId,  // Only if childId exists
  });

  // Query 2: Fetch pagos (only if child loaded successfully)
  const pagosQuery = useQuery({
    queryKey: QUERY_KEYS.transacciones.pagosFactura(entityId, childId || ''),
    queryFn: () => fetchPagosFactura(childId!),
    enabled: !!childQuery.data,  // ✅ Only if child exists
  });

  return {
    child: childQuery.data,
    pagos: pagosQuery.data ?? [],
    isLoading: childQuery.isLoading || pagosQuery.isLoading,
  };
}
```

### Pattern: Query with User Permission

```typescript
export function useAdminOnlyData(entityId: string) {
  const { user } = useAuth();

  const query = useQuery({
    queryKey: QUERY_KEYS.admin.reports(entityId),
    queryFn: () => fetchAdminReports(entityId),

    // ✅ Only fetch if user is admin
    enabled: user?.role === 'admin',
  });

  return query;
}
```

---

## Error Handling

Robust error handling strategies.

### Pattern: Retry with Exponential Backoff

```typescript
export function useTransaccionesWithRetry(entityId: string) {
  const query = useQuery({
    queryKey: QUERY_KEYS.transacciones.root(entityId),
    queryFn: () => fetchTransacciones(entityId),

    // ✅ Retry 3 times with exponential backoff
    retry: 3,
    retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
    // Attempt 1: 1s, Attempt 2: 2s, Attempt 3: 4s

    // ✅ Custom retry logic
    retryOnMount: true,  // Retry even if component remounts
  });

  return query;
}
```

### Pattern: Fallback Data on Error

```typescript
export function useTransaccionesWithFallback(entityId: string) {
  const query = useQuery({
    queryKey: QUERY_KEYS.transacciones.root(entityId),
    queryFn: () => fetchTransacciones(entityId),

    // ✅ Use cached data even if stale (on error)
    placeholderData: (previousData) => previousData,
  });

  // Show cached data with warning
  if (query.error && query.data) {
    return {
      ...query,
      warning: "Mostrando datos en caché (sin conexión)",
    };
  }

  return query;
}
```

---

## Placeholder Data

Show something immediately while loading.

### Pattern: Instant Loading with Placeholder

```typescript
export function useProveedorDetailWithPlaceholder(
  entityId: string,
  proveedorId: string
) {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: QUERY_KEYS.proveedores.detail(entityId, proveedorId),
    queryFn: () => fetchProveedorDetail(proveedorId),

    // ✅ Show data from list query as placeholder
    placeholderData: () => {
      const proveedores = queryClient.getQueryData<Proveedor[]>(
        QUERY_KEYS.proveedores.all(entityId)
      );

      return proveedores?.find(p => p.id === proveedorId);
    },
  });

  return query;
}
```

**Result:** Detail page shows partial data from list immediately, then fills in full details when loaded.

---

## Suspense Mode (Experimental)

Use React Suspense for declarative loading states.

### Pattern: Suspense Query

```typescript
export function useTransaccionesSuspense(entityId: string) {
  const query = useSuspenseQuery({
    queryKey: QUERY_KEYS.transacciones.root(entityId),
    queryFn: () => fetchTransacciones(entityId),
  });

  // ✅ No need to check isLoading - Suspense handles it
  return query.data;  // Always defined (suspends if loading)
}
```

**Usage in component:**

```typescript
function TransaccionesPage() {
  return (
    <Suspense fallback={<Spinner />}>
      <TransaccionesList />
    </Suspense>
  );
}

function TransaccionesList() {
  const transacciones = useTransaccionesSuspense(estId);
  // No loading check needed - Suspense handles it
  return <DataTable data={transacciones} />;
}
```
