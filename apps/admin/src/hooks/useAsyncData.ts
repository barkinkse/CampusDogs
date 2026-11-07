import { useCallback, useEffect, useState } from 'react'

export function useAsyncData<T>(load: () => Promise<T>, enabled = true) {
  const [data, setData] = useState<T | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(enabled)
  const refresh = useCallback(async () => { setLoading(true); setError(null); try { setData(await load()) } catch (caught) { setError(caught instanceof Error ? caught.message : 'Veri alınamadı.') } finally { setLoading(false) } }, [load])
  useEffect(() => { if (enabled) void refresh() }, [enabled, refresh])
  return { data, error, loading, refresh }
}
