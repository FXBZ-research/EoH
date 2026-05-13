function [c1, c2] = llm_smart_crossover(p1, p2)
    % 改进思路：
    % 1. 保持边频加权贪心构造（同原代码），作为初始子代。
    % 2. 增加基于边频的2-opt局部搜索（同原代码）。
    % 3. 新增基于边频的or-opt（单城市插入）局部搜索：
    %    依次将每个城市从其当前位置移除，尝试插入到所有可能的间隙，
    %    选择使边频总和增加最多的位置（若有改善则立即执行），
    %    循环遍历所有城市直至无改进。
    % 4. 此组合能更精细地调整边的拓扑，保留更多父代中的优秀边。

    n = length(p1);
    edge_cnt = zeros(n, n);

    % 提取 p1 的边
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

    % 邻接表
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
        if k == n; break; end
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

    % ====== 2-opt 局部搜索（边频最大化） ======
    improved = true;
    while improved
        improved = false;
        for i = 1:n-2
            for j = i+2:n-1
                a = c1(i);
                b = c1(i+1);
                c = c1(j);
                d = c1(mod(j, n) + 1);
                new_ab = edge_cnt(a, c);
                new_cd = edge_cnt(b, d);
                old_ab = edge_cnt(a, b);
                old_cd = edge_cnt(c, d);
                delta = (new_ab + new_cd) - (old_ab + old_cd);
                if delta > 0
                    c1(i+1 : j) = fliplr(c1(i+1 : j));
                    improved = true;
                    break;
                end
            end
            if improved; break; end
        end
    end

    % ====== or-opt 局部搜索（单城市插入优化边频） ======
    or_improved = true;
    while or_improved
        or_improved = false;
        for city_idx = 1:n
            city = c1(city_idx);
            % 暂时移除 city
            temp_path = [c1(1:city_idx-1), c1(city_idx+1:n)];
            % 计算插入各个间隙的边频增益（包括首尾之间的间隙）
            best_delta = -inf;
            best_pos = -1;
            % 间隙位置：在temp_path中，位置1到n-1（在元素之前插入，以及末尾之后）
            % 循环中，需要正确处理环路
            for pos = 1:n-1
                % 在temp_path的pos之前插入city（即变成temp_path(1:pos-1), city, temp_path(pos:end)）
                % 新边：(temp_path(pos-1), city) 和 (city, temp_path(pos))
                if pos == 1
                    left = temp_path(end);   % 环路：前一个元素是末尾
                else
                    left = temp_path(pos-1);
                end
                right = temp_path(pos);
                new_left = edge_cnt(left, city);
                new_right = edge_cnt(city, right);
                % 被移除的边：原来连接(temp_path(pos-1), temp_path(pos)) 但注意pos=1时，原边是(temp_path(end), temp_path(1))
                if pos == 1
                    old_edge = edge_cnt(temp_path(end), temp_path(1));
                else
                    old_edge = edge_cnt(temp_path(pos-1), temp_path(pos));
                end
                delta = (new_left + new_right) - old_edge;
                if delta > best_delta
                    best_delta = delta;
                    best_pos = pos;
                end
            end
            % 还要考虑插入到末尾之后（即temp_path最后和首部之间）
            % 在末尾之后插入：变成 [temp_path, city]
            % 新边：(temp_path(end), city) 和 (city, temp_path(1))
            new_left = edge_cnt(temp_path(end), city);
            new_right = edge_cnt(city, temp_path(1));
            old_edge = edge_cnt(temp_path(end), temp_path(1));
            delta = (new_left + new_right) - old_edge;
            if delta > best_delta
                best_delta = delta;
                best_pos = n; % 表示放在末尾（索引n对应在temp_path最后，即原路径的末尾之后）
            end
            if best_delta > 0
                % 执行插入
                if best_pos == n
                    c1 = [temp_path, city];
                else
                    c1 = [temp_path(1:best_pos-1), city, temp_path(best_pos:end)];
                end
                or_improved = true;
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
        if k == n; break; end
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

    % ====== 对 c2 执行 2-opt ======
    improved = true;
    while improved
        improved = false;
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
            if improved; break; end
        end
    end

    % ====== 对 c2 执行 or-opt ======
    or_improved = true;
    while or_improved
        or_improved = false;
        for city_idx = 1:n
            city = c2(city_idx);
            temp_path = [c2(1:city_idx-1), c2(city_idx+1:n)];
            best_delta = -inf;
            best_pos = -1;
            for pos = 1:n-1
                if pos == 1
                    left = temp_path(end);
                else
                    left = temp_path(pos-1);
                end
                right = temp_path(pos);
                new_left = edge_cnt(left, city);
                new_right = edge_cnt(city, right);
                if pos == 1
                    old_edge = edge_cnt(temp_path(end), temp_path(1));
                else
                    old_edge = edge_cnt(temp_path(pos-1), temp_path(pos));
                end
                delta = (new_left + new_right) - old_edge;
                if delta > best_delta
                    best_delta = delta;
                    best_pos = pos;
                end
            end
            new_left = edge_cnt(temp_path(end), city);
            new_right = edge_cnt(city, temp_path(1));
            old_edge = edge_cnt(temp_path(end), temp_path(1));
            delta = (new_left + new_right) - old_edge;
            if delta > best_delta
                best_delta = delta;
                best_pos = n;
            end
            if best_delta > 0
                if best_pos == n
                    c2 = [temp_path, city];
                else
                    c2 = [temp_path(1:best_pos-1), city, temp_path(best_pos:end)];
                end
                or_improved = true;
            end
        end
    end
end