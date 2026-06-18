/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        sunset: {
          50: '#fef7ee',
          100: '#fdecd7',
          200: '#fbd5ae',
          300: '#f8b77a',
          400: '#f59144',
          500: '#f3751f',
          600: '#e45b15',
          700: '#bd4313',
          800: '#963617',
          900: '#792f16',
        },
      },
    },
  },
  plugins: [],
};
