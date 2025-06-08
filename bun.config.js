// Bun configuration for testing
export default {
  test: {
    // Use Bun's built-in test runner
    runner: "bun",
    
    // Test file patterns
    include: ["spec/javascript/**/*.spec.js", "spec/javascript/**/*.test.js"],
    
    // Setup files
    setup: ["./spec/javascript/setup.js"],
    
    // Coverage settings
    coverage: {
      enabled: true,
      outputDir: "./coverage/javascript",
      include: ["app/javascript/**/*.js"],
      exclude: ["**/*.spec.js", "**/*.test.js", "**/node_modules/**"]
    },
    
    // Environment
    env: {
      NODE_ENV: "test"
    }
  }
}