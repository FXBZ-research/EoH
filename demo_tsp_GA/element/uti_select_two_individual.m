function [p1,p2] = uti_select_two_individual(pop,selectionType)

    switch selectionType
        case 'RouletteWheel'
            
            % 基于适应度, 计算轮盘赌的选择概率 Calculate Selection Probabilities                            
            popFitness = [pop(:).Fitness];  % pop的适应度向量
            popFitness=popFitness/sum(popFitness);  % 每个个体的轮盘赌概率
            c=cumsum(popFitness);                   % 个体的累积概率
            
            % 轮盘赌从pop种群,选出两个'不同'的个体
            r1=rand; 
            r2=rand;            
            p1=find(r1<=c,1,'first');
            p2=find(r2<=c,1,'first');
            while p1==p2
                r2=rand;      
                p2=find(r2<=c,1,'first');
            end
            
            p1=pop(p1);
            p2=pop(p2);

        case 'Tournament'   % 锦标赛 随机选两个体, 选适应度优的选出
            
            n = numel(pop);

            p1 = randi(n,2,1);
            if pop(p1(1)).Fitness > pop(p1(2)).Fitness
                p1 = p1(1);
            else
                p1 = p1(2);
            end
            
            p2 = randi(n,2,1);
            if pop(p2(1)).Fitness > pop(p2(2)).Fitness
                p2 = p2(1);
            else
                p2 = p2(2);
            end
            
            while p1==p2
                p2 = randi(n,2,1);
                if pop(p2(1)).Fitness > pop(p2(2)).Fitness
                    p2 = p2(1);
                else
                    p2 = p2(2);
                end
            end
            
            p1=pop(p1);
            p2=pop(p2);
            
        otherwise
            error('error selectionType');
    end

end