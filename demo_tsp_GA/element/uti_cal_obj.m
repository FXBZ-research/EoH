% tour : 访问序列（不含终点）
% d : tsp问题的距离矩阵
% objective : tour的长度

function objective=uti_cal_obj(tour,d)

    n=numel(tour);
    
    tour=[tour tour(1)];
    
    objective=0;
    
    for k=1:n
        
        i=tour(k);
        j=tour(k+1);
        
        objective=objective+d(i,j);

    end

end