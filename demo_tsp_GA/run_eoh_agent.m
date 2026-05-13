% run_eoh_agent.m
clc; clear; close all;
addpath(genpath('.'))

% 1. 加载提示词模板和TSP数据
prompts = get_eoh_prompts();
instanceName = 'st70';
[TSP_DisplayData, TSP_EdgeWeight] = uti_readlib_tsp(instanceName);
[tsp] = uti_lib2struct(TSP_DisplayData, TSP_EdgeWeight);

% 2. GA 评估参数设置
par_sga.selectionType = 'Tournament';
par_sga.crossoverType = 'LLM_Operator'; % 强制使用LLM交叉算子
par_sga.mutationType = '2opt';          
par_sga.fitnessType = 'Quality';
par_sga.replacementType = 'Elitism';
par_sga.maxIter = 5000;  
par_sga.noIter = 500;
par_sga.popSize = 30;
par_sga.crossoverProb = 0.8;
par_sga.mutationProb = 0.2;
par_sga.eliteNum = 10;
par_sga.ISDEBUG = 0; 
par_sga.ISPLOT = 0;

% 3. EoH 演化参数与算子管理器初始化
evo_generations = 5; 
fprintf('=== 开始 EoH 交叉算子自动演化 ===\n');

if ~exist('history_operators', 'dir')
    mkdir('history_operators');
end

% 【核心新增】：建立算子管理结构体
opManager = struct('gen', {}, 'code', {}, 'fitness', {}, 'fileName', {});
totalOps = 0; 

% 初始 Prompt 与 记忆
ChatNow = prompts.init;
ChatLog = {};       

for gen = 1:evo_generations
    fprintf('\n[第 %d 代] 正在向 LLM 请求新的交叉算子...\n', gen);
    SayNew = ChatNow;
    
    % 每代开始前备份当前记忆 (存档点)
    history_backup = ChatLog;
    
    % 最多尝试 2 次（1次首发 + 1次自愈修正）
    for attempt = 1:2
        if attempt == 2
            fprintf(' -> 正在启动 1 次自动调试与修正...\n');
        end
        
        [LLM_Say, ChatLog] = Call_AI_more(SayNew, ChatLog);  
        code_str = extract_matlab_code(LLM_Say);   
        
        if isempty(code_str)
            fprintf(' -> 未提取到代码，跳过...\n');
            continue;
        end
        
        % 保存覆盖执行文件
        fid = fopen('llm_smart_crossover.m', 'w');
        fprintf(fid, '%s', code_str);
        fclose(fid);
        
        % 归档至文件夹
        timeStamp = datestr(now, 'yyyymmdd_HHMMSS');
        archiveFile = sprintf('history_operators/crossover_gen%d_att%d_%s.m', gen, attempt, timeStamp);
        fid_archive = fopen(archiveFile, 'w');
        fprintf(fid_archive, '%s', code_str);
        fclose(fid_archive);
        
        % 运行 GA 评估
        try
            [BestSol, ~] = sol_TSP_GA(tsp, par_sga);
            current_fitness = BestSol.Cost;
            fprintf(' -> 本代算子评估成功 (最小距离): %.2f\n', current_fitness);
            
            % 【核心新增】：将成功运行的算子存入 Manager 并根据 Fitness 排序
            totalOps = totalOps + 1;
            opManager(totalOps).gen = gen;
            opManager(totalOps).code = code_str;
            opManager(totalOps).fitness = current_fitness;
            opManager(totalOps).fileName = archiveFile;
            
            % 根据 Fitness 对种群库进行升序排序 (越小越好)
            T = struct2table(opManager);
            T = sortrows(T, 'fitness');
            opManager = table2struct(T);
            
            best_fitness = opManager(1).fitness;
            fprintf(' -> 当前历史最佳距离为: %.2f\n', best_fitness);
            
            % 【核心新增】：基于库中的精英，动态决定下一代的策略
            if totalOps == 1
                % 库里只有 1 个，只能用 M1 单体变异策略
                ChatNow = sprintf(prompts.m1_template, opManager(1).code);
                fprintf(' -> 准备下一代 Prompt：采用 M1(单体变异) 策略。\n');
            else
                % 库里有 2 个或以上，随机选择使用 M1 还是 E2 融合策略
                if rand() < 0.5
                    % 50% 概率：提取排名第一的进行 M1
                    ChatNow = sprintf(prompts.m1_template, opManager(1).code);
                    fprintf(' -> 准备下一代 Prompt：采用 M1(单体变异) 策略，基于 Top-1。\n');
                else
                    % 50% 概率：提取排名前两名的进行 E2 交叉创新
                    ChatNow = sprintf(prompts.e2_template, opManager(1).code, opManager(2).code);
                    fprintf(' -> 准备下一代 Prompt：采用 E2(提取共性) 策略，融合 Top-1 和 Top-2。\n');
                end
            end
            
            % 如果这次表现不好，向 prompt 追加反馈
            if current_fitness > best_fitness
                feedback = sprintf('\n注：你上次生成的代码跑出的距离为 %.2f，未打破历史最佳 %.2f。请尝试不同于上次的启发式思想。', current_fitness, best_fitness);
                ChatNow = ChatNow + feedback;
            end
            
            break; % 成功运行并完成评估，跳出 attempt 内部修正循环
            
        catch ME
            fprintf(' -> 算子运行时发生 MATLAB 报错：%s\n', ME.message);
            if attempt == 1
                SayError = sprintf('\n【报错修正反馈】你刚才生成的代码：\n```matlab\n%s\n```\n在运行时引发了错误：\n%s\n请注意，TSP的子代必须是合法的全排列。请确保没有使用局部子函数，修复逻辑并重新输出完整代码。', code_str, ME.message);
                SayNew = SayError;
            else
                fprintf(' -> 修正后依然报错，放弃本代演化，进行记忆回档...\n');
                ChatLog = history_backup;
                % 如果本代失败，下一代的 ChatNow 沿用上一次成功构建的 Prompt
            end
        end
    end
end
fprintf('\n=== 演化结束 ===\n');
if totalOps > 0
    fprintf('找到的【全局最佳】交叉算子最终评估距离: %.2f\n', opManager(1).fitness);
    fprintf('保存在: %s\n', opManager(1).fileName);
else
    fprintf('未能演化出任何可运行的算子。\n');
end

%% 辅助函数：从 Markdown 提取 MATLAB 代码
function code = extract_matlab_code(markdown_str)
    tokens = regexp(markdown_str, '```matlab\s*(.*?)\s*```', 'tokens', 'once');
    if isempty(tokens)
        tokens = regexp(markdown_str, '```\s*(.*?)\s*```', 'tokens', 'once');
    end
    if ~isempty(tokens)
        code = tokens{1};
    else
        code = '';
    end
end