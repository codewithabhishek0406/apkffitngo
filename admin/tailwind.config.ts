import type { Config } from 'tailwindcss'

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50:  '#edfdf5',
          100: '#d5f5e3',
          200: '#aaebc7',
          300: '#73dba3',
          400: '#3ec47c',
          500: '#2ECC71',  // primary
          600: '#27ae60',
          700: '#1e8449',
          800: '#176134',
          900: '#0f4023',
        },
        accent: {
          400: '#ff8c5a',
          500: '#FF6B35',
          600: '#e55520',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
} satisfies Config
