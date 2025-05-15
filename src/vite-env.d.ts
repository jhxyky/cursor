/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_WALLETCONNECT_PROJECT_ID: string
  // 可以在这里添加其他环境变量
}

interface ImportMeta {
  readonly env: ImportMetaEnv
} 