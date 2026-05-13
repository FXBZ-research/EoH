% tour : 访问序列（不含终点）
% d : tsp问题的距离矩阵

function pop = uti_cal_fitness(pop,fitnessType,par)
    
    popSize  = numel(pop);  

    % 初始化个体求解质量和多样性的评估向量
    Quality=zeros(popSize,1);
    Diversity=zeros(popSize,1);
    rank_quality=zeros(popSize,1);
    rank_diversity=zeros(popSize,1);

    switch fitnessType
        case 'Quality'
            % 个体质量：TSP总距离 距离越大 解越差 即适应度越小  %其它变体 P=exp(-beta*P/max(P));
            maxCost = max([pop.Cost]);
            for ii=1:numel(pop)
                Quality(ii) = 1 - pop(ii).Cost / (maxCost+1);
            end

        case 'Diversity'
            % 个体多样性：个体距离最近nClosest个体相似性度量 距离越小 多样性越大 适应度越大 
            %   a.构造popStartFrom1：pop每个个体从1开始，方便计算Hanmming距离
            popStartFrom1 = [];
            for ii=1:numel(pop)
                tour=pop(ii).Position;
                idx=find(tour==1);
                tour= [tour(idx:end),tour(1:idx-1)];
                popStartFrom1 = [popStartFrom1; tour];
            end  
            %    b.计算HanmmingDist:差异越大 距离越高
            HanmmingDist = squareform(pdist(popStartFrom1,'hamming'));
            for ii=1:numel(pop)
                iHanmmingDist = HanmmingDist(ii,:);
                [~,iHanmmingDist] = mink(iHanmmingDist,par.nClosest+1);  % 最近的nCloest+1个体的距离 自身距离为0 
                iHanmmingDist(1)=[];                                 % 最近的一定是自身 可删除
                Diversity(ii) = mean( iHanmmingDist );
            end

        case 'Quality_Diversity'
            % 个体质量：TSP总距离 距离越大 解越差 即适应度越小 
            maxCost = max([pop.Cost]);
            for ii=1:numel(pop)
                Quality(ii) = 1 - pop(ii).Cost / (maxCost+1);
            end
            % 个体质量rank：quality越高 rank值越大
            [~,sortIdx] = sort(Quality,'ascend');
            [~,rank_quality] = sort(sortIdx);

            % 个体多样性：个体距离最近nClosest个体相似性度量 距离越小 多样性越大 适应度越大 
            %   a.构造popStartFrom1：pop每个个体从1开始，方便计算Hanmming距离
            popStartFrom1 = [];
            for ii=1:numel(pop)
                tour=pop(ii).Position;
                idx=find(tour==1);
                tour= [tour(idx:end),tour(1:idx-1)];
                popStartFrom1 = [popStartFrom1; tour];
            end  
            %    b.计算HanmmingDist:差异越大 距离越高
            HanmmingDist = squareform(pdist(popStartFrom1,'hamming'));
            for ii=1:numel(pop)
                iHanmmingDist = HanmmingDist(ii,:);
                [~,iHanmmingDist] = mink(iHanmmingDist,par.nClosest+1);  % 最近的nCloest+1个体的距离 自身距离为0 
                iHanmmingDist(1)=[];                                     % 最近的一定是自身 可删除
                Diversity(ii) = mean( iHanmmingDist );
            end
            % 个体多样性rank：diversity越高 rank值越大
            [~,sortIdx] = sort(Diversity,'ascend');
            [~,rank_diversity] = sort(sortIdx);

        otherwise
            error('wrong fitnessType');
    end
    
    
    % 记录个体的求解质量和多样性
    for ii=1:numel(pop)
        pop(ii).Quality= Quality(ii);
        pop(ii).Diversity= Diversity(ii);
    end

    % Fitness适应度赋值 基于目标值+多样性 （基于rank排名：有统一量纲作用）
    % 权重：（1-par.eliteNum/popSize)
    for ii=1:numel(pop)
        switch fitnessType
            case 'Quality'   % 适应度仅与解的质量相关
                pop(ii).Fitness = Quality(ii);
            case 'Diversity' % 适应度仅与解的多样性相关 
                pop(ii).Fitness = Diversity(ii);
            case 'Quality_Diversity'  % 适应度与解的质量和解的多样性相关
                pop(ii).Fitness = rank_quality(ii) + (1-par.eliteNum/popSize) * rank_diversity(ii);
            otherwise
                error('wrong fitnessType');
        end

end