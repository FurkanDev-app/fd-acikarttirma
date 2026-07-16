import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// FiveM NUI: goreli asset yollari + cikti resource'un html/ klasorune.
// input yollari proje kokune (web/) goredir.
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: '../html',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        index: './index.html',
        screen: './screen.html',
        prop: './prop.html',
      },
    },
  },
})
