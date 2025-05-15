import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    host: true,
    strictPort: true,
    hmr: {
      overlay: false,
    },
    watch: {
      usePolling: false,
      interval: 1000,
    },
  },
  build: {
    target: 'esnext',
    minify: 'terser',
    sourcemap: false,
    chunkSizeWarningLimit: 1000,
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom'],
          'wagmi-vendor': ['wagmi', 'viem'],
        },
      },
    },
  },
  optimizeDeps: {
    include: ['react', 'react-dom', 'wagmi', 'viem', '@web3modal/wagmi', '@tanstack/react-query'],
    exclude: [],
  },
  esbuild: {
    target: 'esnext',
    treeShaking: true,
  },
}); 