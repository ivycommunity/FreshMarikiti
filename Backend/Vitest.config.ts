import { defineProject } from "vitest/config";

export default defineProject({
  test: {
    name: "Node Tests",
    environment: "node",
    // includeSource:['src/*.{js,ts}'],
  },
  // Used on production builds
  define: {
    "import.meta.vitest": "undefined",
  },
});
