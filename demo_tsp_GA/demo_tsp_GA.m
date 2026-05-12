clc; clear; close all;

% TSP算例 基于标准格式 berlin8(2550.94)  berlin52(7544)  st70(675) pr76(108159) a280(2579?) 
instanceName = 'st70';  

% 读取标准TSP算例
[TSP_DisplayData, TSP_EdgeWeight] = uti_readlib_tsp(instanceName);  

% TSP算例算例转换为tsp结构体
% tsp.d city距离矩阵
% tsp.n city数量
[tsp] = uti_lib2struct(TSP_DisplayData, TSP_EdgeWeight);  

% GA求解算法和参数设置 
% GA算子
solver = 'TSP_GA';  
par_sga.selectionType = 'Tournament'; % 选择算子: RouletteWheel Tournament
par_sga.crossoverType = 'OX' ;        % 交叉算子: OX PMX CX
par_sga.mutationType = '2opt';        % 变异算子: swap insert 2opt 类似LocalSearch邻域搜索算子
par_sga.fitnessType = 'Quality';      % 适应度算子: 基于质量/多样性/综合 'Quality' 'Diversity'  'Quality_Diversity'
par_sga.replacementType = 'Elitism';  % 替换策略: Elitism精英保留 SteadyState:单offspring SteadyStateLambda:单offspring 种群数量不固定
par_sga.isLocalSearch = true;
% GA参数
par_sga.maxIter = 5000;  % 最大迭代次数
par_sga.noIter = 500;     % 不改进迭代次数
par_sga.popSize = 30;                    % 种群规模
par_sga.popSizeLambda = 40;              % 动态种群大小
par_sga.crossoverProb = 0.8;             % 交叉概率 706 1变异
par_sga.mutationProb = 0.1;              % 变异概率
par_sga.eliteNum = 10;   % 精英保留个数
par_sga.nClosest = 5;    % 适应度算子计算多样性时 需要的参数
par_sga.ISDEBUG =  1 ;
par_sga.ISPLOT = 0 ;    % 是否作图标记


%% 基于solverName选择不同算法求解
switch solver     
    case {'TSP_GA'}   % GA算法（有crossover/recombination 和 mutation 和selection 和Fitness 和Replacement）
        [BestSol,IterBestSols] = sol_TSP_GA(tsp,par_sga);
end
