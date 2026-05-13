function [c1, c2] = llm_smart_crossover(p1, p2)
    % 改进的边重组交叉算子 (Enhanced ERX)
    % 策略：在原有ERX基础上，记录每条边的出现次数（来自两个父代），
    % 构建子代时优先选择公共边（出现2次）中的邻居，若没有公共边则选择出现1次的邻居，
    % 在同类中再按自由度最小（即未访问邻居个数最少）进行选择，以保留更多优质边信息。
    n = length(p1);
    if n <= 2
        c1 = p1; c2 = p2;
        return;
    end

    % 为每个城市存储唯一邻居和对应边的出现次数
    neigh = cell(n,1);   % 邻居城市列表（唯一）
    wgt   = cell(n,1);   % 对应的边计数（1或2）
    for i = 1:n
        neigh{i} = [];
        wgt{i}   = [];
    end

    % 从两个父代中添加边，并记录出现次数
    for u = [p1, p2]  % 用p1和p2循环添加
        if u == p1
            route = p1;
        else
            route = p2;
        end
        for idx = 1:n
            cur = route(idx);
            prev = route(mod(idx-2, n)+1);
            next = route(mod(idx, n)+1);
            % 处理前驱
            [found, pos] = ismember(prev, neigh{cur});
            if found
                wgt{cur}(pos) = wgt{cur}(pos) + 1;
            else
                neigh{cur} = [neigh{cur}, prev];
                wgt{cur}   = [wgt{cur}, 1];
            end
            % 处理后继
            [found, pos] = ismember(next, neigh{cur});
            if found
                wgt{cur}(pos) = wgt{cur}(pos) + 1;
            else
                neigh{cur} = [neigh{cur}, next];
                wgt{cur}   = [wgt{cur}, 1];
            end
        end
    end

    % 辅助匿名函数：给定当前城市c和已访问标记visited，返回未访问邻居及其权重
    get_unvisited = @(c, visited) deal(...
        neigh{c}(~ismember(neigh{c}, find(visited))), ...
        wgt{c}(~ismember(neigh{c}, find(visited))) );
    % 辅助匿名函数：计算一组邻居的自由度（未访问邻居个数）
    calc_freedom = @(nbrs, visited) arrayfun(@(x) length(setdiff(neigh{x}, find(visited))), nbrs);

    % 生成c1（从p1的第一个城市开始）
    c1 = zeros(1,n);
    visited = false(1,n);
    current = p1(1);
    visited(current) = true;
    c1(1) = current;
    for k = 2:n
        [unvisited_neigh, unvisited_wgt] = get_unvisited(current, visited);
        if ~isempty(unvisited_neigh)
            % 优先选择公共边（weight == 2）的邻居
            public_idx = (unvisited_wgt == 2);
            if any(public_idx)
                candidates = unvisited_neigh(public_idx);
            else
                candidates = unvisited_neigh(~public_idx);
            end
            % 在候选中按自由度最小选择
            freedoms = calc_freedom(candidates, visited);
            [min_f, ~] = min(freedoms);
            best = candidates(freedoms == min_f);
            if length(best) > 1
                next = best(randi(length(best)));
            else
                next = best(1);
            end
        else
            % 无未访问邻居，从全局未访问中选择自由度最小的
            unvisited_all = find(~visited);
            freedoms = calc_freedom(unvisited_all, visited);
            [min_f, ~] = min(freedoms);
            best = unvisited_all(freedoms == min_f);
            if length(best) > 1
                next = best(randi(length(best)));
            else
                next = best(1);
            end
        end
        c1(k) = next;
        visited(next) = true;
        current = next;
    end

    % 生成c2（从p2的第一个城市开始，重置visited）
    c2 = zeros(1,n);
    visited = false(1,n);
    current = p2(1);
    visited(current) = true;
    c2(1) = current;
    for k = 2:n
        [unvisited_neigh, unvisited_wgt] = get_unvisited(current, visited);
        if ~isempty(unvisited_neigh)
            public_idx = (unvisited_wgt == 2);
            if any(public_idx)
                candidates = unvisited_neigh(public_idx);
            else
                candidates = unvisited_neigh(~public_idx);
            end
            freedoms = calc_freedom(candidates, visited);
            [min_f, ~] = min(freedoms);
            best = candidates(freedoms == min_f);
            if length(best) > 1
                next = best(randi(length(best)));
            else
                next = best(1);
            end
        else
            unvisited_all = find(~visited);
            freedoms = calc_freedom(unvisited_all, visited);
            [min_f, ~] = min(freedoms);
            best = unvisited_all(freedoms == min_f);
            if length(best) > 1
                next = best(randi(length(best)));
            else
                next = best(1);
            end
        end
        c2(k) = next;
        visited(next) = true;
        current = next;
    end
end