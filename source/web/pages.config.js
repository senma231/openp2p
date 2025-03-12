module.exports = {
  // 构建命令
  build: {
    command: "npm run build",
    directory: "dist",
  },
  // 环境变量
  env: {
    VITE_API_URL: "https://your-api-server.com",
  },
  // 路由规则
  routes: [
    { src: "/api/*", dest: "https://your-api-server.com/api/:splat" },
    { src: "/*", dest: "/index.html" },
  ],
} 