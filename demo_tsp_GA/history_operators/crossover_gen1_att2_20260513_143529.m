function [c1, c2] = llm_smart_crossover(p1, p2)
    % 策略：基于边重组交叉的启发式变体。
    % 1. 从两个父代路径中提取所有相邻边（无向），构建每个城市的邻接表（去重）。
    % 2. 分别以 p1(1) 和 p2(1) 为起点，贪心构造两个子代：
    %    - 每一步从当前城市的未访问邻居中，选择“具有最少未访问邻居”的城市作为下一站。
    %    - 若无未访问邻居，则从全部剩余城市中随机挑选。
    % 3. 此方法保留父代中高频出现的短边，同时增加随机性。

    n = length(p1);
    % 邻接表：cell数组，每个元素存储该城市的邻居列表（无重复）
    adj = cell(1, n);
    for i = 1:n
        adj{i} = [];
    end

    % 添加 p1 的边（循环闭合，无向）
    for i = 1:n
        curr = p1(i);
        nxt = p1(mod(i, n) + 1);
        adj{curr} = unique([adj{curr}, nxt]);
        adj{nxt} = unique([adj{nxt}, curr]);
    end

    % 添加 p2 的边
    for i = 1:n
        curr = p2(i);
        nxt = p2(mod(i, n) + 1);
        adj{curr} = unique([adj{curr}, nxt]);
        adj{nxt} = unique([adj{nxt}, curr]);
    end

    % ---------- 生成子代 c1（起点为 p1(1)） ----------
    c1 = zeros(1, n);
    visited = false(1, n);
    current = p1(1);
    for k = 1:n
        c1(k) = current;
        visited(current) = true;
        if k == n
            break;   % 最后一个城市已放置，无需再选择下一个
        end

        % 当前城市的未访问邻居
        neighbors = adj{current};
        unvisited = neighbors(~visited(neighbors));

        if isempty(unvisited)
            % 所有邻居已访问 -> 从剩余城市中随机选一个
            remaining = find(~visited);
            next = remaining(randi(length(remaining)));
        else
            % 计算每个未访问邻居的“未访问邻居数”
            cnt = zeros(size(unvisited));
            for j = 1:length(unvisited)
                nb = unvisited(j);
                nb_neighbors = adj{nb};
                nb_unvisited = nb_neighbors(~visited(nb_neighbors));
                cnt(j) = length(nb_unvisited);
            end
            % 选择未访问邻居数最少的邻居（若有多个则随机选一个）
            min_val = min(cnt);
            candidates = find(cnt == min_val);
            idx = candidates(randi(length(candidates)));
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
            cnt = zeros(size(unvisited));
            for j = 1:length(unvisited)
                nb = unvisited(j);
                nb_neighbors = adj{nb};
                nb_unvisited = nb_neighbors(~visited(nb_neighbors));
                cnt(j) = length(nb_unvisited);
            end
            min_val = min(cnt);
            candidates = find(cnt == min_val);
            idx = candidates(randi(length(candidates)));
            next = unvisited(idx);
        end
        current = next;
    end
end