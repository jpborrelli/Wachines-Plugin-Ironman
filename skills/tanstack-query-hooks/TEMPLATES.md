# TanStack Query Hook Templates

Complete template implementations for common data fetching patterns.

## Basic Query Hook

Standard hook for fetching a list of entities:

```typescript
import { useQuery } from '@tanstack/react-query';
import { QUERY_KEYS } from '@/lib/queryKeys';
import { supabase } from '@/lib/supabase';

export interface Proveedor {
  id: string;
  nombre: string;
  cuit: string;
  email?: string;
  telefono?: string;
  // ... more fields
}

export function useProveedores(entityId: string) {
  const {
    data: proveedores = [],
    isLoading,
    error,
    refetch
  } = useQuery({
    // 🔑 Query key for cache and invalidation
    queryKey: QUERY_KEYS.proveedores.all(entityId),

    // 📡 Query function - fetches the data
    queryFn: async () => {
      const { data, error } = await supabase
        .from('proveedor')
        .select('*')
        .eq('entity_id', entityId)
        .eq('is_deleted', false)
        .order('nombre', { ascending: true });

      if (error) throw error;
      return data as Proveedor[];
    },

    // ⚙️ Options
    enabled: !!entityId,  // Only fetch if ID exists
    staleTime: 5 * 60 * 1000,      // Cache valid for 5 minutes
  });

  return {
    proveedores,
    isLoading,
    error,
    refetch
  };
}
```

**Usage in component:**

```typescript
function ProveedoresPage() {
  const { entityActivo } = useAuth();
  const { proveedores, isLoading, error } = useProveedores(
    entityActivo?.id
  );

  if (isLoading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;

  return (
    <DataTable data={proveedores} columns={columns} />
  );
}
```

---

## Mutation Hook

Hook for creating/updating/deleting entities with automatic cache invalidation:

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useNotifications } from '@/hooks/use-notifications';
import { QUERY_KEYS } from '@/lib/queryKeys';
import { supabase } from '@/lib/supabase';

export interface CreateProveedorData {
  entity_id: string;
  nombre: string;
  cuit: string;
  email?: string;
  telefono?: string;
}

export function useCreateProveedor(entityId: string) {
  const queryClient = useQueryClient();
  const notifications = useNotifications();

  const mutation = useMutation({
    // 🔧 Mutation function
    mutationFn: async (data: CreateProveedorData) => {
      const { data: result, error } = await supabase
        .from('proveedor')
        .insert(data)
        .select()
        .single();

      if (error) throw error;
      return result;
    },

    // ✅ On success: Invalidate queries + show notification
    onSuccess: () => {
      // 🔄 Invalidate all proveedor queries → automatic refetch
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.proveedores.root(entityId)
      });

      notifications.showSuccess(
        "¡Proveedor creado!",
        "El proveedor se registró correctamente"
      );
    },

    // ❌ On error: Show error notification
    onError: (error) => {
      notifications.showError(
        "Error al crear proveedor",
        error instanceof Error ? error.message : "Error desconocido"
      );
    }
  });

  return {
    createProveedor: mutation.mutate,
    isCreating: mutation.isPending,
    isSuccess: mutation.isSuccess,
    isError: mutation.isError,
  };
}
```

**Usage in component:**

```typescript
function NuevoProveedorForm({ onClose }) {
  const { entityActivo } = useAuth();
  const { createProveedor, isCreating } = useCreateProveedor(
    entityActivo?.id
  );

  const handleSubmit = (data: FormData) => {
    createProveedor({
      entity_id: entityActivo.id,
      ...data
    }, {
      onSuccess: () => {
        onClose();  // Close modal after success
      }
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
      <Button type="submit" disabled={isCreating}>
        {isCreating ? "Guardando..." : "Guardar"}
      </Button>
    </form>
  );
}
```

---

## Detail Query with Dependencies

Hook for fetching a single entity with conditional execution:

```typescript
import { useQuery } from '@tanstack/react-query';
import { QUERY_KEYS } from '@/lib/queryKeys';
import { supabase } from '@/lib/supabase';

export function useProveedorDetail(
  entityId: string,
  proveedorId?: string
) {
  const {
    data: proveedor,
    isLoading,
    error,
    refetch
  } = useQuery({
    queryKey: QUERY_KEYS.proveedores.detail(
      entityId,
      proveedorId || ''
    ),

    queryFn: async () => {
      if (!proveedorId) return null;

      const { data, error } = await supabase
        .from('proveedor')
        .select(`
          *,
          transacciones:transaccion!contraparte_id (
            id,
            monto_total,
            fecha,
            tipo_operacion
          )
        `)
        .eq('id', proveedorId)
        .single();

      if (error) throw error;
      return data;
    },

    // ✅ CRITICAL: Only run query if both IDs exist
    enabled: !!entityId && !!proveedorId,
    staleTime: 2 * 60 * 1000,  // 2 minutes for detail views
  });

  return {
    proveedor,
    isLoading,
    error,
    refetch
  };
}
```

---

## Update Mutation

Hook for updating existing entities:

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { QUERY_KEYS } from '@/lib/queryKeys';

export interface UpdateProveedorData {
  id: string;
  nombre?: string;
  email?: string;
  telefono?: string;
}

export function useUpdateProveedor(entityId: string) {
  const queryClient = useQueryClient();
  const notifications = useNotifications();

  const mutation = useMutation({
    mutationFn: async ({ id, ...updates }: UpdateProveedorData) => {
      const { data, error } = await supabase
        .from('proveedor')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },

    onSuccess: (data) => {
      // Invalidate both list and detail queries
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.proveedores.root(entityId)
      });

      // ✨ OPTIONAL: Update specific detail query optimistically
      queryClient.setQueryData(
        QUERY_KEYS.proveedores.detail(entityId, data.id),
        data
      );

      notifications.showSuccess(
        "¡Actualizado!",
        "Los cambios se guardaron correctamente"
      );
    },

    onError: (error) => {
      notifications.showError("Error al actualizar", error.message);
    }
  });

  return {
    updateProveedor: mutation.mutate,
    isUpdating: mutation.isPending,
  };
}
```

---

## Delete Mutation

Hook for soft-delete with confirmation:

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { QUERY_KEYS } from '@/lib/queryKeys';

export function useDeleteProveedor(entityId: string) {
  const queryClient = useQueryClient();
  const notifications = useNotifications();

  const mutation = useMutation({
    mutationFn: async (proveedorId: string) => {
      // ✅ Soft delete (set is_deleted = true)
      const { error } = await supabase
        .from('proveedor')
        .update({ is_deleted: true })
        .eq('id', proveedorId);

      if (error) throw error;
      return proveedorId;
    },

    onSuccess: () => {
      // Invalidate list queries (detail will be excluded by is_deleted filter)
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.proveedores.root(entityId)
      });

      notifications.showSuccess(
        "¡Eliminado!",
        "El proveedor se eliminó correctamente"
      );
    },

    onError: (error) => {
      notifications.showError("Error al eliminar", error.message);
    }
  });

  return {
    deleteProveedor: mutation.mutate,
    isDeleting: mutation.isPending,
  };
}
```

**Usage with confirmation dialog:**

```typescript
function ProveedorRow({ proveedor }) {
  const { deleteProveedor, isDeleting } = useDeleteProveedor(
    entityActivo.id
  );

  const handleDelete = () => {
    if (confirm(`¿Eliminar proveedor ${proveedor.nombre}?`)) {
      deleteProveedor(proveedor.id);
    }
  };

  return (
    <TableRow>
      <TableCell>{proveedor.nombre}</TableCell>
      <TableCell>
        <Button onClick={handleDelete} disabled={isDeleting}>
          <Trash2 className="h-4 w-4" />
        </Button>
      </TableCell>
    </TableRow>
  );
}
```

---

## Dependent Queries

Fetch data that depends on another query's result:

```typescript
export function useProveedorConTransacciones(
  entityId: string,
  proveedorId?: string
) {
  // Query 1: Fetch proveedor
  const { data: proveedor, isLoading: loadingProveedor } = useQuery({
    queryKey: QUERY_KEYS.proveedores.detail(entityId, proveedorId || ''),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('proveedor')
        .select('*')
        .eq('id', proveedorId)
        .single();

      if (error) throw error;
      return data;
    },
    enabled: !!entityId && !!proveedorId,
  });

  // Query 2: Fetch transacciones (depends on proveedor existing)
  const { data: transacciones = [], isLoading: loadingTransacciones } = useQuery({
    queryKey: QUERY_KEYS.transacciones.proveedorTransacciones(
      entityId,
      proveedorId || ''
    ),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('transaccion')
        .select('*')
        .eq('contraparte_id', proveedorId)
        .eq('is_deleted', false)
        .order('fecha', { ascending: false });

      if (error) throw error;
      return data;
    },
    // ✅ Only fetch transacciones if proveedor was fetched successfully
    enabled: !!proveedor,
  });

  return {
    proveedor,
    transacciones,
    isLoading: loadingProveedor || loadingTransacciones,
  };
}
```

---

## Infinite Query (Load More)

Hook for paginated data with "Load More" button:

```typescript
import { useInfiniteQuery } from '@tanstack/react-query';
import { QUERY_KEYS } from '@/lib/queryKeys';

const PAGE_SIZE = 50;

export function useTransaccionesPaginated(entityId: string) {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isLoading,
  } = useInfiniteQuery({
    queryKey: QUERY_KEYS.transacciones.paginated(entityId),

    queryFn: async ({ pageParam = 0 }) => {
      const { data, error } = await supabase
        .from('transaccion')
        .select('*')
        .eq('entity_id', entityId)
        .order('fecha', { ascending: false })
        .range(pageParam, pageParam + PAGE_SIZE - 1);

      if (error) throw error;

      return {
        transacciones: data,
        nextCursor: data.length === PAGE_SIZE ? pageParam + PAGE_SIZE : undefined,
      };
    },

    getNextPageParam: (lastPage) => lastPage.nextCursor,
    initialPageParam: 0,
  });

  // Flatten pages into single array
  const transacciones = data?.pages.flatMap(page => page.transacciones) ?? [];

  return {
    transacciones,
    isLoading,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  };
}
```

**Usage with Load More button:**

```typescript
function TransaccionesList() {
  const { entityActivo } = useAuth();
  const {
    transacciones,
    isLoading,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage
  } = useTransaccionesPaginated(entityActivo.id);

  if (isLoading) return <Spinner />;

  return (
    <div>
      <DataTable data={transacciones} />

      {hasNextPage && (
        <Button onClick={() => fetchNextPage()} disabled={isFetchingNextPage}>
          {isFetchingNextPage ? "Cargando..." : "Cargar más"}
        </Button>
      )}
    </div>
  );
}
```

---

## Combined Hook (CRUD Operations)

Hook that exports all CRUD operations for an entity:

```typescript
export function useProveedoresCRUD(entityId: string) {
  const queryClient = useQueryClient();
  const notifications = useNotifications();

  // Query: List
  const listQuery = useQuery({
    queryKey: QUERY_KEYS.proveedores.all(entityId),
    queryFn: async () => {
      const { data, error } = await supabase
        .from('proveedor')
        .select('*')
        .eq('entity_id', entityId)
        .eq('is_deleted', false);

      if (error) throw error;
      return data;
    },
    enabled: !!entityId,
  });

  // Mutation: Create
  const createMutation = useMutation({
    mutationFn: async (data: CreateProveedorData) => {
      const { data: result, error } = await supabase
        .from('proveedor')
        .insert(data)
        .select()
        .single();

      if (error) throw error;
      return result;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.proveedores.root(entityId)
      });
      notifications.showSuccess("¡Creado!", "Proveedor creado correctamente");
    }
  });

  // Mutation: Update
  const updateMutation = useMutation({
    mutationFn: async ({ id, ...updates }: UpdateProveedorData) => {
      const { data, error } = await supabase
        .from('proveedor')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.proveedores.root(entityId)
      });
      notifications.showSuccess("¡Actualizado!", "Cambios guardados");
    }
  });

  // Mutation: Delete
  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('proveedor')
        .update({ is_deleted: true })
        .eq('id', id);

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: QUERY_KEYS.proveedores.root(entityId)
      });
      notifications.showSuccess("¡Eliminado!", "Proveedor eliminado");
    }
  });

  return {
    // Query data
    proveedores: listQuery.data ?? [],
    isLoading: listQuery.isLoading,
    error: listQuery.error,
    refetch: listQuery.refetch,

    // CRUD operations
    create: createMutation.mutate,
    update: updateMutation.mutate,
    delete: deleteMutation.mutate,

    // Loading states
    isCreating: createMutation.isPending,
    isUpdating: updateMutation.isPending,
    isDeleting: deleteMutation.isPending,
  };
}
```
