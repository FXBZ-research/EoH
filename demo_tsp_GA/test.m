
clear all;tic
load('deepseek_api_key'); 
base_url = 'https://api.deepseek.com';

deepseek_model='deepseek-v4-flash';
%deepseek_model='deepseek-reasoner';

system_text = '你是一个非常强大的助手';

user_text = '你好，我现在使用matlab的api接口与你对话,现在正在测试使用的模型版本，请告诉我你的模型版本。';

payload = struct(...
    'model', deepseek_model, ...
    'messages', {{...
        struct('role', 'system', 'content', system_text), ...
        struct('role', 'user', 'content', user_text)...
    }}, ...
    'stream', false ...
);

options = weboptions('RequestMethod', 'post', ...
                     'ContentType', 'json', ...
                     'HeaderFields', {'Authorization', ['Bearer ' deepseek_api_key]});

url = [base_url '/chat/completions'];

response = webwrite(url, payload, options);

disp(response.choices.message.content);


