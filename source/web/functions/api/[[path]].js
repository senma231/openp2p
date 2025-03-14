export async function onRequest(context) {
  // 获取原始请求
  const { request } = context;
  
  // 获取请求路径
  const url = new URL(request.url);
  const path = url.pathname.replace(/^\/api/, '');
  
  // 构建转发URL
  const apiUrl = `https://api.openp2p.909981.xyz/api${path}${url.search}`;
  
  // 创建新的请求
  const newRequest = new Request(apiUrl, {
    method: request.method,
    headers: request.headers,
    body: request.body,
    redirect: 'follow',
  });
  
  try {
    // 发送请求到API服务器
    const response = await fetch(newRequest);
    
    // 创建新的响应，添加CORS头
    const newResponse = new Response(response.body, response);
    
    // 添加CORS头
    newResponse.headers.set('Access-Control-Allow-Origin', 'https://openp2p.909981.xyz');
    newResponse.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    newResponse.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    newResponse.headers.set('Access-Control-Allow-Credentials', 'true');
    
    return newResponse;
  } catch (error) {
    // 返回错误响应
    return new Response(JSON.stringify({ error: 'API请求失败', details: error.message }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': 'https://openp2p.909981.xyz',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Credentials': 'true',
      },
    });
  }
} 