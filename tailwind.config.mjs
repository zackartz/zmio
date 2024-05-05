/** @type {import('tailwindcss').Config} */
export default {
  content: ["./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}"],
  theme: {
    extend: {},
    fontFamily: {
      sans: ["Iosevka Web", "ui-monospace", "monospace"],
    },
  },
  plugins: [require("@tailwindcss/typography")],
};
