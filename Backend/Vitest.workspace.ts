import { defineWorkspace } from "vitest/config";

export default defineWorkspace([
  //Matches every folder and file inside the packages folder
  {
    test: {
      //Every file with the extension of ts,js o jsx will be tested provided its within the src folder and as well.
      include: ["./**/*.{ts,js}", "./**/*.{test-d.ts}"],
      //All projects must have a unique name, otherwise error. If not provied a number will be assigned.
      name: "Testing",
      environment: "node", //Default testing environment
    },
    extends: "vitest.config.js", // since not all configurations are found in the workspace.
  },
]);

//Workspaces lack all configurations hence you can use defineProject method instead of defineConfig
