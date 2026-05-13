function [c1, c2] = llm_smart_crossover(p1, p2)
    % 改进思路：在原有边频加权贪心构造的基础上，增加基于边频最大化的2-opt局部搜索。
    % 1. 与之前相同，构建边频矩阵 edge_cnt (n×n) 和邻接表。
    % 2. 分别以 p1(1) 和 p2(1) 为起点，按边频优先 + 最小未访问邻居的贪心规则构造两个子代。
    % 3. 对每个子代执行2-opt优化：以当前路径中所有边的边频之和为目标，
    %    通过反转路径片段尝试增加边频总和（即更倾向于使用父代中重复出现的边），
    %    迭代至局部最优，从而进一步提升子代质量。

    n = length(p1);
    edge_cnt = zeros(n, n);

    % 提取 p1 的边（循环闭合，无向）
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
        adj{i} = find(edge_cnt(i, :) > 0);
    end

    % ====== 生成子代 c1 ======
    c1 = zeros(1, n);
    visited = false(1, n);
    current = p1(1);
    for k = 1:n
        c1(k) = current;
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
            top_freq = find(freq == max_freq);
            if length(top_freq) == 1
                idx = top_freq(1);
            else
                deg_in = deg(top_freq);
                min_deg = min(deg_in);
                idx = top_freq(deg_in == min_deg);
                idx = idx(randi(length(idx)));
            end
            next = unvisited(idx);
        end
        current = next;
    end

    % ====== 对 c1 执行 2-opt 局部搜索（以边频总和最大化为目标） ======
    improved = true;
    while improved
        improved = false;
        % 计算当前边频总和
        total = 0;
        for i = 1:n
            total = total + edge_cnt(c1(i), c1(mod(i, n) + 1));
        end
        % 遍历所有可能的反转片段 [i+1, j] (i < j, 且不相邻)
        for i = 1:n-2
            for j = i+2:n-1
                % 当前边的四个端点
                a = c1(i);
                b = c1(i+1);
                c = c1(j);
                d = c1(mod(j, n) + 1);
                % 反转后新增的两条边
                new_ab = edge_cnt(a, c);
                new_cd = edge_cnt(b, d);
                % 被移除的两条边
                old_ab = edge_cnt(a, b);
                old_cd = edge_cnt(c, d);
                delta = (new_ab + new_cd) - (old_ab + old_cd);
                if delta > 0
                    % 执行反转：将片段 c1(i+1 : j) 逆序
                    c1(i+1 : j) = fliplr(c1(i+1 : j));
                    improved = true;
                    % 更新 total 以便后续比较（但为简单，直接重新扫描整个循环）
                    % 这里 immediate 改进后，会重新进入 while 重新扫描
                    break; % 跳出内层循环，重新开始新一轮扫描
                end
            end
            if improved
                break; % 跳出外层循环，重新开始 while
            end
        end
    end

    % ====== 生成子代 c2（起点为 p2(1)） ======
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
            top_freq = find(freq == max_freq);
            if length(top_freq) == 1
                idx = top_freq(1);
            else
                deg_in = deg(top_freq);
                min_deg = min(deg_in);
                idx = top_freq(deg_in == min_deg);
                idx = idx(randi(length(idx)));
            end
            next = unvisited(idx);
        end
        current = next;
    end

    % ====== 对 c2 执行 2-opt 局部搜索 ======
    improved = true;
    while improved
        improved = false;
        total = 0;
        for i = 1:n
            total = total + edge_cnt(c2(i), c2(mod(i, n) + 1));
        end
        for i = 1:n-2
            for j = i+2:n-1
                a = c2(i);
                b = c2(i+1);
                c = c2(j);
                d = c2(mod(j, n) + 1);
                new_ab = edge_cnt(a, c);
                new_cd = edge_cnt(b, d);
                old_ab = edge_cnt(a, b);
                old_cd = edge_cnt(c, d);
                delta = (new_ab + new_cd) - (old_ab + old_cd);
                if delta > 0
                    c2(i+1 : j) = fliplr(c2(i+1 : j));
                    improved = true;
                    break;
                end
            end
            if improved
                break;
            end
        end
    end
end