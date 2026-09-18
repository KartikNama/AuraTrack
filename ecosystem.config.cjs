module.exports = {
  apps: [
    {
      name: "auratrack-web",
      script: "npx",
      args: "serve -s dist -l 4000",
      cwd: "/var/www/AuraTrack",
      instances: 1,
      exec_mode: "fork",
      env: {
        NODE_ENV: "production",
      },
      max_memory_restart: "250M",
    },
  ],
};
