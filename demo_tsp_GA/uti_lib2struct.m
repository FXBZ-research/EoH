%uti_lib2struct 转换Lib格式算例 到 结构体格式

function [tsp] = uti_lib2struct(TSP_DisplayData,TSP_EdgeWeight)

    x = TSP_DisplayData(:,1)';
    y = TSP_DisplayData(:,2)';    
    n=length(TSP_DisplayData);
    
    d=TSP_EdgeWeight;
    alpha = 0.0; % 显示增加系数
    xmin=min(x) - range(x)*alpha;     xmax=max(x) + range(x)*alpha;    
    ymin=min(y) - range(y)*alpha;    ymax=max(y) + range(y)*alpha;
    
    tsp.n=n;
    tsp.d=d;
    
    tsp.x=x;
    tsp.y=y;
    tsp.xmin=xmin;
    tsp.xmax=xmax;
    tsp.ymin=ymin;
    tsp.ymax=ymax;
    
end

