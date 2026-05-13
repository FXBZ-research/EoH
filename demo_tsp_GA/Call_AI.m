function reply = Call_AI(user_text)
% 自动加载你的 API 密钥文件 (确保 deepseek_api_key.mat 在当前路径)
load('deepseek_api_key', 'deepseek_api_key');

base_url = 'https://api.deepseek.com';
model_name = 'deepseek-v4-flash';

% 专门针对你科研方向的系统提示词
system_text = '你是一个顶尖的运筹学与计算机科学专家，精通MATLAB，擅长设计和重构车辆路径规划(VRP)的启发式算法。';

requestData = struct(...
    'model', model_name, ...
    'messages', {{...
    struct('role', 'system', 'content', system_text), ...
    struct('role', 'user', 'content', user_text)...
    }}, ...
    'stream', false, ...
    'temperature', 0.2, ...
    'max_tokens', 4096, ...
    'reasoning_effort', 'high', ... % <-- 新增参数 1：直接作为平铺的键值对
    'extra_body', struct('thinking', struct('type', 'enabled')) ... % <-- 新增参数 2：使用 struct 嵌套来表达 JSON 的层级关系
    );

httpConfig = weboptions('RequestMethod', 'post', ...
    'ContentType', 'json', ...
    'Timeout', 60, ... % 算法代码生成可能较慢，增加超时时间
    'HeaderFields', {'Authorization', ['Bearer ' deepseek_api_key]});

url = [base_url '/chat/completions'];

% 发送请求并捕获报错，防止主程序崩溃
try
    response = webwrite(url, requestData, httpConfig);
    reply = response.choices(1).message.content;
catch ME
    reply = "网络请求失败: " + ME.message;
end
end