% GA算法求解Tsp
% 特色: 种群概念;
%       可跳出局部最优：交叉/变异
%       选择概念：哪些在下一次保留

function [BestSol,IterBestSols] = sol_TSP_GA(tsp,par)

%% 初始化 Initialization
rng(1);  % seed确保结果复现

maxIter = par.maxIter;  % 最大迭代次数
noIter = par.noIter;    % N次无改进次数
ISDEBUG = par.ISDEBUG;
ISPLOT = par.ISPLOT;

% TSP算例
n = tsp.n;
d = tsp.d;

% GA算子
selectionType = par.selectionType;         % 选择类型
crossoverType = par.crossoverType;         % 交叉类型
mutationType=par.mutationType;             % 变异类型
fitnessType = par.fitnessType;             % 适应度计算类型
replacementType = par.replacementType;     % 种群替换策略
% GA参数
crossoverProb=par.crossoverProb;   % 交叉概率
mutationProb=par.mutationProb;     % 变异概率 
popSize = 2*round(par.popSize/2);  % 种群大小 确保可被2整除
eliteNum = par.eliteNum;           % 精英大小
popSizeLambda = par.popSizeLambda; % Lambda大小

% 基于替换策略指定子代规模
switch replacementType
    case 'Elitism'
        offspringSize = popSize;
    case {'SteadyState','SteadyStateLambda'}
        offspringSize = 1;
    otherwise
        error('wrong replacementType');
end

% 记录初始化
% 个体除Cost(tour距离外),新增Quality(解的质量);Diversity(解的多样性);Fitness(基于算子评估)
individual = struct('Position',[],'Cost',[],'Quality',[],'Diversity',[],'Fitness',[]);
IterBestSols(1:maxIter) = individual;
BestSol=individual;
BestSol.Cost=Inf;

%% GA /* 0 Generate an initial solution POP 建立初始种群P(0) */
pop(1:popSize) = individual;
for i=1:popSize
    pop(i).Position=randperm(n);   % 每个个体随机解
    pop(i).Cost=uti_cal_obj(pop(i).Position,d);
end
if ISDEBUG
    fprintf(' # 初始种群 个体数%d个,平均目标值%.2f 平均适应度%.2f 平均求解质量%.4f 平均多样性%.1f \n', ...
        numel(pop), mean([pop.Cost]),mean([pop.Fitness]),mean([pop.Quality]),mean([pop.Diversity]) );
end

%% GA /* 主循环 Main Loop */
it2=0;
for it=1:maxIter 
    % 超出N次迭代无改进 终止演化
    if it2 >= noIter 
        fprintf('演化终止:%d次迭代无改进 \n',it2);
        break;  
    end
    
    % #1 /* 评估当前种群POP中个体的适应度 */   
    pop = uti_cal_fitness(pop,fitnessType,par);
    
    % #2 /* selection 初始化offspringSize个大小的 offspring Population */
    offspring(1:offspringSize) = individual;
    for k=1:2:offspringSize
        % Select Parents  从pop中按selectionType类型参数选择两个different个体
        [p1,p2] = uti_select_two_individual(pop,selectionType);  
        offspring(k) = p1;
        offspring(k+1) = p2;
    end
    if ISDEBUG >=2
        fprintf(' # 第%d次迭代 步骤1;选择通过%s算子 种群个体数%d个,平均目标值%.2f  \n',it, selectionType, numel(offspring), mean([offspring.Cost]) );
    end
    
    % #3 /* Recombination（Crossover and mutatoin） 对selected offspring Population */
    % #3.1 Crossover
    for k=1:2:numel(offspring)
    
        p1=offspring(k);
        p2=offspring(k+1);
        % Crossover operator 基于交叉crossoverType类型对p1和p2进行交叉
        if rand <= crossoverProb
            [c1,c2]=uti_PermutationCrossover(p1,p2,crossoverType,individual);
            c1.Cost = uti_cal_obj(c1.Position,d);
            c2.Cost = uti_cal_obj(c2.Position,d);
        else
            c1=p1;
            c2=p2;
        end
        offspring(k) = c1;
        offspring(k+1) = c2;
    end
    if ISDEBUG >=2
        fprintf(' # 第%d次迭代 步骤2;交叉通过%s算子%.2f概率 种群个体数%d个,平均目标值%.2f \n', ...
            it, crossoverType, crossoverProb, numel(offspring), mean([offspring.Cost]) );
    end
    
    % #3.2 Mutation
    for k=1:1:numel(offspring)
        p1=offspring(k);
        % Mutation operator 基于变异mutationType类型对p1和p2进行变异
        if rand <= mutationProb
            [c1]=uti_PermutationMutation(p1,mutationType,individual);
            c1.Cost = uti_cal_obj(c1.Position,d);
        else
            c1=p1;
        end        
        offspring(k) = c1;
    end
    if ISDEBUG >=2
        fprintf(' # 第%d次迭代 步骤3;变异通过%s算子%.2f概率 种群个体数%d个,平均目标值%.2f \n', ...
        it, mutationType,mutationProb, numel(offspring), mean([offspring.Cost]) );
    end

    % #4 /* Replacement pop 种群管理 */
    switch replacementType
        case 'Elitism'
            % a. elitePop:原pop内的Elite精英保留（基于Fitness）
            [~,eliteIdx]=maxk([pop.Fitness],eliteNum);
            elitePop = pop(eliteIdx);
            % b. newPop:offspring内的新个体保留（淘汰适应度差的）
            % /* POP 计算offspring个体的适应度 */
            offspring = uti_cal_fitness(offspring,fitnessType,par);
            [~,newPopIdx]=maxk([offspring.Fitness],popSize-eliteNum);
            newPop = offspring(newPopIdx);
            % c. pop: 下一代种群由上一代的精英和子代的补齐构成
            pop = [elitePop newPop];
        case 'SteadyState'
            % a. newPop:原pop删除worst的最差个体
            [~,worstIdx]=min([pop.Fitness]);
            pop(worstIdx)=[];
            % b. offspring: 两个offspring的最佳进入下一代
            [~,bestIdx]=min([offspring.Cost]);
            offspring=offspring(bestIdx);
            % b. pop: 下一代种群由上一代的删除后的和子代的最佳offspring构成
            pop = [pop offspring];
        case 'SteadyStateLambda'
            % a. offspring: 两个offspring的最佳进入下一代
            [~,bestIdx]=min([offspring.Cost]);
            offspring=offspring(bestIdx);
            % b. pop: 下一代种群由上一代和子代的最佳offspring构成
            pop = [pop offspring];
            % c. lambda: 动态更新种群规模(基于Fitness)
            %       如超出popSize+popSizeLamda,则缩小至popSize,删除clone的和劣解
            if numel(pop) > popSize+popSizeLambda
                pop = uti_cal_fitness(pop,fitnessType,par);
                [~,lambdaIdx]=mink([pop.Fitness],popSizeLambda+1);
                pop(lambdaIdx)=[];
            end
    end

    % #5 /* Update Best Solution Ever Found 基于Cost 非Fitness */
    [minCost,minIdx]=min([pop.Cost]);
    if minCost < BestSol.Cost
        BestSol=pop(minIdx);
    end
    IterBestSols(it) = BestSol;
    
    % #6: N次迭代无改变
    if it>1
        if IterBestSols(it).Cost < IterBestSols(it-1).Cost % 本次迭代有改进 则重置it2
            it2 = 0;
        else
            it2 = it2+1;
        end
    end
    if ISDEBUG
        fprintf('# 第%d次迭代, 全局最优解%.2f 本种群最优解%.2f 种群平均解%.2f 平均适应度%.2f 平均求解质量%.4f 平均多样性%.1f \n', ...
            it, BestSol.Cost, minCost, mean([pop.Cost]), mean([pop.Fitness]),mean([pop.Quality]),mean([pop.Diversity]) );
    end
    
    if ISPLOT && mod(it,100)==0
        % Plot Best Solution
        figure(1);
        subplot(1,2,1);
        uti_plotSolution_TSP(tsp,BestSol);
        title(['第',num2str(it),'次迭代', ' 目标值:',num2str(BestSol.Cost)]);
        subplot(1,2,2);
        plot([IterBestSols.Cost],'LineWidth',2);
        xlabel('Iteration');
        ylabel('Best Cost');
        grid on;
        pause(0.001);
    end

end

end


%% 局部函数 

