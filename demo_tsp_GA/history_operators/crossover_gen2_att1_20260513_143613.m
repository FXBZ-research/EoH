function [c1, c2] = llm_smart_crossover(p1, p2)
    % 改进策略：在原有边重组交叉的基础上引入边频加权。
    % 1. 构建无向边频矩阵 edge_cnt (n×n)，记录每条边在两个父代中出现的总次数（0/1/2）。
    % 2. 贪心构造子代时，优先选择边频最高的未访问邻居（即同时出现在两个父代中的边最受青睐），
    %    若平局则再按原策略选择“最少未访问邻居”的城市，以保持优良边与探索的平衡。
    % 3. 当无未访问邻居时，从剩余城市中随机选择以维持多样性。

    n = length(p1);
    % edge_cnt 矩阵：edge_cnt(i,j) = 边(i,j)出现的次数（无向，对称）
    edge_cnt = zeros(n, n);

    % 辅助函数：增加无向边 (a,b) 的计数
    add_edge = @(a,b) deal(...
        edge_cnt(a,b) = edge_cnt(a,b) + 1, ...
        edge_cnt(b,a) = edge_cnt(b,a) + 1 );
    % 由于匿名函数不能修改外部变量，改用手动循环

    % 提取 p1 的边（循环闭合）
    for i = 1:n
        a = p1(i);
        b = p1(mod(i, n) + 1);
        edge_cnt(a, b) = edge_cnt(a, b) + 1;
        edge_cnt(b, a) = edge_cnt(b, a) + 1;
    end
    % 提取 p2 的边
    for i = 1:n
        a = p2(i);
        b = p2(mod(i, n) + 1);
        edge_cnt(a, b) = edge_cnt(a, b) + 1;
        edge_cnt(b, a) = edge_cnt(b, a) + 1;
    end

    % 构建每个城市的邻居列表（去重）
    adj = cell(1, n);
    for i = 1:n
        adj{i} = find(edge_cnt(i,:) > 0);
    end

    % ---------- 生成子代 c1（起点为 p1(1)） ----------
    c1 = zeros(1, n);
    visited = false(1, n);
    current = p1(1);
    for k = 1:n
        c1(k) = current;
        visited(current) = true;
        if k == n
            break;
        end

        % 当前城市的未访问邻居
        neighbors = adj{current};
        unvisited = neighbors(~visited(neighbors));

        if isempty(unvisited)
            % 所有邻居已访问 -> 从剩余城市中随机选一个
            remaining = find(~visited);
            next = remaining(randi(length(remaining)));
        else
            % 先按边频降序排序，再按未访问邻居数升序排序
            % 构造候选列表：每个候选城市及其边频权重和未访问邻居数
            freq = zeros(size(unvisited));
            deg = zeros(size(unvisited));
            for j = 1:length(unvisited)
                nb = unvisited(j);
                freq(j) = edge_cnt(current, nb);        % 边频
                nb_neighbors = adj{nb};
                nb_unvisited = nb_neighbors(~visited(nb_neighbors));
                deg(j) = length(nb_unvisited);          % 未访问邻居数
            end
            % 组合排序：先按边频降序，再按deg升序
            % 使用 sortrows 需要构建矩阵，但可能较慢。这里使用两步筛选
            max_freq = max(freq);
            % 选择边频最大的所有候选
            top_freq_idx = find(freq == max_freq);
            if length(top_freq_idx) == 1
                idx = top_freq_idx(1);
            else
                % 在边频最大的候选里，选择未访问邻居数最少的
                deg_in_top = deg(top_freq_idx);
                min_deg = min(deg_in_top);
                min_deg_idx = top_freq_idx(deg_in_top == min_deg);
                % 若还有多个，随机选一个
                idx = min_deg_idx(randi(length(min_deg_idx)));
            end
            next = unvisited(idx);
        end
        current = next;
    end

    % ---------- 生成子代 c2（起点为 p2(1)） ----------
    c2 = zeros(1, n);
    visited = false(1, n);
    current = p2(1);
    for k = 1:n
        c2(k) = current;
        visited(current) = true;
        if k == n
            break;
        end

        neighbors = adj{current};
        unvisited = neighbors(~visited(neighbors));

        if isempty(unvisited)
            remaining = find(~visited);
            next = remaining(randi(length(remaining)));
        else
            freq = zeros(size(unvisited));
            deg = zeros(size(unvisited));
            for j = 1:length(unvisited)
                nb = unvisited(j);
                freq(j) = edge_cnt(current, nb);
                nb_neighbors = adj{nb};
                nb_unvisited = nb_neighbors(~visited(nb_neighbors));
                deg(j) = length(nb_unvisited);
            end
            max_freq = max(freq);
            top_freq_idx = find(freq == max_freq);
            if length(top_freq_idx) == 1
                idx = top_freq_idx(1);
            else
                deg_in_top = deg(top_freq_idx);
                min_deg = min(deg_in_top);
                min_deg_idx = top_freq_idx(deg_in_top == min_deg);
                idx = min_deg_idx(randi(length(min_deg_idx)));
            end
            next = unvisited(idx);
        end
        current = next;
    end
end