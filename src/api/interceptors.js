// src/api/interceptors.js
export function setupInterceptors({ api, router, store }) {
  // Request: attach token jika ada
  api.interceptors.request.use(config => {
    const token = store?.token || localStorage.getItem('token');
    if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
  }, err => Promise.reject(err));

  // Response: tangani 401 / unauthenticated
  api.interceptors.response.use(
    res => res,
    error => {
      const res = error.response;
      const message = String(res?.data?.message || res?.data?.error || '').toLowerCase();

      const isAuthError =
        res?.status === 401 ||
        res?.status === 419 || // session expired (optional)
        /unauthenticated|unauthorized|token expired/.test(message);

      if (isAuthError) {
        try {
          // kalau pakai Pinia/Vuex: panggil action logout supaya UI update
          if (store?.logout && typeof store.logout === 'function') {
            store.logout();
          } else {
            // fallback: hapus localStorage
            localStorage.removeItem('token');
            localStorage.removeItem('user');
          }
        } catch (e) {
          console.error('Error during logout cleanup', e);
        }

        // beri sedikit delay supaya store update dulu (opsional)
        router.push({ name: 'login' });
      }

      return Promise.reject(error);
    }
  );
}
