/** @type {import('tailwindcss').Config} */
export default {
  content: ["./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}"],
  theme: {
    extend: {
      typography: (theme) => ({
        DEFAULT: {
          css: {
            color: "rgba(var(--ctp-text), 1)",
            "--tw-prose-body": "rgba(var(--ctp-text), 1)",
            "--tw-prose-headings": "rgba(var(--ctp-mauve), 1)",
            "--tw-prose-hr": "rgba(var(--ctp-surface0), 1)",
            "--tw-prose-code": "rgba(var(--ctp-red), 1)",
            a: {
              color: "rgba(var(--ctp-blue), 1)",
              "text-decoration-thickness": ".1em",
              "text-underline-offset": "4px",
              "&:hover": {
                color: "rgba(var(--ctp-sky), 1)",
              },
            },
          },
        },
      }),
    },
    fontFamily: {
      sans: ["Iosevka Web", "ui-monospace", "monospace"],
    },
  },
  plugins: [
    require("@catppuccin/tailwindcss")({
      prefix: "ctp",
      defaultFlavor: "mocha",
    }),
    require("@tailwindcss/typography"),
  ],
};
