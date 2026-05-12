%
% Copyright (c) 2015, Yarpiz (www.yarpiz.com)
% All rights reserved. Please read the "license.txt" for license terms.
%
% Project Code: YPEA105
% Project Title: Simulated Annealing for Traveling Salesman Problem
% Publisher: Yarpiz (www.yarpiz.com)
%
% Developer: S. Mostapha Kalami Heris (Member of Yarpiz Team)
%
% Contact Info: sm.kalami@gmail.com, info@yarpiz.com
%
function PlotSolution_TSP(model,sol)

xmin=model.xmin;
xmax=model.xmax;
ymin=model.ymin;
ymax=model.ymax;

if nargin == 1
    tour=[1:model.n];
    pline = 'o';
else
    if isfield(sol,'Position')
        tour=sol.Position;
    elseif isfield(sol,'Tour')
        tour=sol.Tour;
    elseif isfield(sol,'L')
        tour=sol.L;
    else
        error('1');
    end
    pline = 'k-o';
end



tour=[tour tour(1)];

%     plot(model.x(tour),model.y(tour),pline,...
%         'MarkerSize',10,...
%         'MarkerFaceColor','y',...
%         'LineWidth',1.5);
plot(model.x(tour),model.y(tour),pline,...
    'MarkerSize',2,...
    'MarkerFaceColor','y',...
    'LineWidth',0.2);

% Ôö¼Óposition
str = mat2cell(tour(1:end-1)', ones(1,model.n))';
text(model.x(tour(1:end-1)),model.y(tour(1:end-1)), str, 'Color','red','FontSize',10);


xlabel('x');
ylabel('y');

axis equal;
grid on;

alpha = 0.1;

dx = xmax - xmin;
xmin = floor((xmin - alpha*dx)/10)*10;
xmax = ceil((xmax + alpha*dx)/10)*10;
xlim([xmin xmax]);

dy = ymax - ymin;
ymin = floor((ymin - alpha*dy)/10)*10;
ymax = ceil((ymax + alpha*dy)/10)*10;
ylim([ymin ymax]);

end
