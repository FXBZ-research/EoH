function [c1, c2] = llm_smart_crossover(p1, p2)
    % 策略：基于Edge Recombination Crossover (ERX) 的改进
    % 1. 从两个父代中提取每个城市的无向邻接关系（前后邻居），构建邻接表
    % 2. 生成子代时，从随机起点出发，每次优先选择当前城市的未访问邻居中，
    %    具有最少未访问邻居的邻居（ERX启发式），以保留父代优质边
    % 3. 若当前城市无未访问邻居，则在剩余城市中随机选择
    % 4. 生成两个不同起始点的子代，确保多样性
    
    n = length(p1);
    
    % 构建邻接表 neighbors{i} = 城市i在p1和p2中的无向邻居（唯一值）
    neighbors = cell(1, n);
    for i = 1:n
        % 在p1中的前驱和后继（环形）
        idx1 = find(p1 == i, 1);
        prev1 = p1(mod(idx1-2, n) + 1);
        next1 = p1(mod(idx1, n) + 1);
        
        % 在p2中的前驱和后继
        idx2 = find(p2 == i, 1);
        prev2 = p2(mod(idx2-2, n) + 1);
        next2 = p2(mod(idx2, n) + 1);
        
        % 合并并去重，排除自身
        all_nbrs = [prev1, next1, prev2, next2];
        all_nbrs = unique(all_nbrs);
        neighbors{i} = all_nbrs(all_nbrs ~= i);
    end
    
    % 随机选择两个不同的起始城市
    rng('shuffle');
    start1 = randi(n);
    start2 = randi(n);
    while start2 == start1
        start2 = randi(n);
    end
    
    % 用于存储两个子代
    all_children = zeros(2, n);
    start_cities = [start1, start2];
    
    for child_idx = 1:2
        start_city = start_cities(child_idx);
        visited = false(1, n);
        perm = zeros(1, n);
        perm(1) = start_city;
        visited(start_city) = true;
        
        for k = 2:n
            current = perm(k-1);
            nbrs = neighbors{current};
            % 筛选未访问的邻居
            unvisited_nbrs = nbrs(~visited(nbrs));
            
            if isempty(unvisited_nbrs)
                % 无可用邻居，在剩余城市中随机选一个
                remain = find(~visited);
                next = remain(randi(length(remain)));
            else
                % ERX启发式：计算每个未访问邻居的未访问邻居数（在邻接表中计数）
                counts = zeros(1, length(unvisited_nbrs));
                for j = 1:length(unvisited_nbrs)
                    cand = unvisited_nbrs(j);
                    cand_nbrs = neighbors{cand};
                    counts(j) = sum(~visited(cand_nbrs));
                end
                % 选择未访问邻居数最少的城市（优先连接孤立边）
                [min_val, idx_min] = min(counts);
                % 若多个并列，随机选择一个
                idx_list = find(counts == min_val);
                if length(idx_list) > 1
                    chosen_idx = idx_list(randi(length(idx_list)));
                else
                    chosen_idx = idx_min;
                end
                next = unvisited_nbrs(chosen_idx);
            end
            
            perm(k) = next;
            visited(next) = true;
        end
        
        all_children(child_idx, :) = perm;
    end
    
    c1 = all_children(1, :);
    c2 = all_children(2, :);
end