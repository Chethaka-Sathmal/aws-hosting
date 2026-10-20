import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'

// Mirrors the CloudFront /api/* behavior locally
const proxy = {
  '/api': {
    target: 'http://localhost:3001'
  }
}

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy
  },
  preview: {
    port: 3000,
    proxy
  }
})
