function [c1, c2] = llm_smart_crossover(p1, p2)
    % 启发式边重组交叉算子 (ERX)
    % 策略：从两个父代中提取每个城市的邻接边（前驱和后继），构建邻接列表。
    % 在构建子代时，从指定的起始城市出发，每一步选择当前城市邻居中具有最少未访问邻居的城市，
    % 以保留父代中的优秀边，生成更短路径。c1 从 p1 的第一个城市开始，c2 从 p2 的第一个城市开始。
    n = length(p1);
    if n <= 2
        c1 = p1; c2 = p2;
        return;
    end
    % 构建邻居列表（循环路径）
    edges = cell(n,1);
    for i = 1:n
        edges{i} = [];
    end
    % 从 p1 添加邻居
    for i = 1:n
        prev = p1(mod(i-2, n)+1); % 前一个
        next = p1(mod(i, n)+1);   % 后一个
        edges{p1(i)} = unique([edges{p1(i)}, prev, next]);
    end
    % 从 p2 添加邻居
    for i = 1:n
        prev = p2(mod(i-2, n)+1);
        next = p2(mod(i, n)+1);
        edges{p2(i)} = unique([edges{p2(i)}, prev, next]);
    end
    % 辅助匿名函数：获取一个城市c的当前未访问邻居列表
    get_neighbors = @(c, visited) setdiff(edges{c}, find(visited));
    % 辅助匿名函数：计算每个未访问邻居的剩余自由度（未访问邻居个数）
    get_freedoms = @(neighbors, visited) arrayfun(@(x) length(get_neighbors(x, visited)), neighbors);
    % 生成c1：从p1的第一个城市开始
    c1 = zeros(1,n);
    visited = false(1,n);
    start = p1(1);
    current = start;
    visited(current) = true;
    c1(1) = current;
    for k = 2:n
        nbrs = get_neighbors(current, visited);
        if ~isempty(nbrs)
            frees = get_freedoms(nbrs, visited);
            [~, idx] = min(frees); % 选择自由度最小的邻居
            % 如果有多个最小，随机选一个
            min_frees = nbrs(frees == min(frees));
            if length(min_frees) > 1
                next = min_frees(randi(length(min_frees)));
            else
                next = nbrs(idx);
            end
        else
            % 无可用邻居，从剩余未访问中选一个自由度最小的
            unvisited = find(~visited);
            frees = get_freedoms(unvisited, visited);
            [~, idx] = min(frees);
            min_frees = unvisited(frees == min(frees));
            if length(min_frees) > 1
                next = min_frees(randi(length(min_frees)));
            else
                next = unvisited(idx);
            end
        end
        c1(k) = next;
        visited(next) = true;
        current = next;
    end
    % 生成c2：从p2的第一个城市开始，重置visited
    c2 = zeros(1,n);
    visited = false(1,n);
    start = p2(1);
    current = start;
    visited(current) = true;
    c2(1) = current;
    for k = 2:n
        nbrs = get_neighbors(current, visited);
        if ~isempty(nbrs)
            frees = get_freedoms(nbrs, visited);
            [~, idx] = min(frees);
            min_frees = nbrs(frees == min(frees));
            if length(min_frees) > 1
                next = min_frees(randi(length(min_frees)));
            else
                next = nbrs(idx);
            end
        else
            unvisited = find(~visited);
            frees = get_freedoms(unvisited, visited);
            [~, idx] = min(frees);
            min_frees = unvisited(frees == min(frees));
            if length(min_frees) > 1
                next = min_frees(randi(length(min_frees)));
            else
                next = unvisited(idx);
            end
        end
        c2(k) = next;
        visited(next) = true;
        current = next;
    end
end