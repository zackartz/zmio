import { defineConfig } from "astro/config";
import mdx from "@astrojs/mdx";
import sitemap from "@astrojs/sitemap";

import tailwind from "@astrojs/tailwind";
import syntaxTheme from "./syntax-theme.json";

// https://astro.build/config
export default defineConfig({
  site: "https://zackmyers.io",
  markdown: {
    shikiConfig: {
      theme: syntaxTheme,
    },
  },
  integrations: [mdx(), sitemap(), tailwind()],
});
