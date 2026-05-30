import { useCallback, useEffect, useRef, useState } from "react";

interface UseAsyncOptions {
  onError?: (error: Error) => void;
}

interface UseAsyncResult<T> {
  data: T | undefined;
  isLoading: boolean;
  revalidate: () => void;
}

/**
 * Minimal data-loading hook so the extension only depends on packages that
 * Raycast already bundles (@raycast/api, react). Keeps previously loaded data
 * while refetching, mirroring useCachedPromise's keepPreviousData behavior.
 */
export function useAsync<T>(
  fn: () => Promise<T>,
  deps: unknown[],
  options?: UseAsyncOptions,
): UseAsyncResult<T> {
  const [data, setData] = useState<T | undefined>(undefined);
  const [isLoading, setIsLoading] = useState(true);
  const [nonce, setNonce] = useState(0);

  const fnRef = useRef(fn);
  fnRef.current = fn;
  const onErrorRef = useRef(options?.onError);
  onErrorRef.current = options?.onError;

  useEffect(() => {
    let cancelled = false;
    setIsLoading(true);
    fnRef
      .current()
      .then((result) => {
        if (!cancelled) setData(result);
      })
      .catch((error) => {
        if (!cancelled) {
          onErrorRef.current?.(
            error instanceof Error ? error : new Error(String(error)),
          );
        }
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [...deps, nonce]);

  const revalidate = useCallback(() => setNonce((value) => value + 1), []);

  return { data, isLoading, revalidate };
}
