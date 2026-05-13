function [reply, messages] = Call_AI_more(user_text, messages)
    % 自动加载你的 API 密钥文件
    load('deepseek_api_key', 'deepseek_api_key');
    base_url = 'https://api.deepseek.com';
    model_name = 'deepseek-v4-flash';
    
    % --- 第 1 步：上下文初始化 ---
    % 如果是第一次对话（也就是没有传入 messages，或者 messages 为空）
    if nargin < 2 || isempty(messages)
        system_text = '你是一个顶尖的运筹学与计算机科学专家，精通MATLAB，擅长设计和重构车辆路径规划(VRP)的启发式算法。';
        % 初始化一个 Cell 数组，存入系统提示词
        messages = {struct('role', 'system', 'content', system_text)};
    end

    % --- 第 2 步：追加当前用户提问 ---
    % 将你新输入的话，作为 'user' 角色追加到记录的末尾
    messages{end+1} = struct('role', 'user', 'content', user_text);

    % 构建请求数据
    requestData = struct(...
        'model', model_name, ...
        'messages', {messages}, ... % <--- 直接把整个"记忆数组"传给服务器！
        'stream', false, ...
        'temperature', 0.2, ...
        'max_tokens', 4096, ...
        'reasoning_effort', 'high', ...
        'thinking', struct('type', 'enabled') ... % 正确的参数位置
    );

    httpConfig = weboptions('RequestMethod', 'post', ...
        'ContentType', 'json', ...
        'Timeout', 10, ... 
        'HeaderFields', {'Authorization', ['Bearer ' deepseek_api_key]});
        
    url = [base_url '/chat/completions'];

    % 发送请求
    try
        response = webwrite(url, requestData, httpConfig);
        reply = response.choices(1).message.content;
        
        % --- 第 3 步：追加 AI 的回复 ---
        % 【核心环节】把 AI 返回的话作为 'assistant' 角色追加到记录末尾
        messages{end+1} = struct('role', 'assistant', 'content', reply);
        
    catch ME
        reply = "网络请求失败: " + ME.message;
        % 如果网络断了，把刚才加进去的用户提问删掉，防止污染记忆
        messages(end) = []; 
    end
end