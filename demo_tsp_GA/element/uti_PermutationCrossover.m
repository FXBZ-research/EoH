function [c1,c2]=uti_PermutationCrossover(p1,p2,crossoverType,individual)
    
    c1=individual;
    c2=individual;
    switch crossoverType
        case 'OX'  % 测试过
            % parents的p1和p2
            
            x1 = p1.Position;
            x2 = p2.Position;
            
            nPoint = length(x1);
            y1 = zeros(1,nPoint);
            y2 = zeros(1,nPoint);
            
            c=randperm(nPoint,2); % 返回两个点
            point1=min(c);
            point2=max(c);
            
            % inherit继承x1的部分到y1
            y1(point1:point2)=x1(point1:point2);
            y2(point1:point2)=x2(point1:point2);
            
            % x2从第2个点后重新排序
            x2sorted = [x2(point2+1:nPoint),x2(1:point2)];
            x1sorted = [x1(point2+1:nPoint),x1(1:point2)];
            
            % y1其余部分从x2赋值
            x2sorted(ismember(x2sorted,y1))=[];
            y1([point2+1:nPoint,1:point1-1]) = x2sorted;
            
            % y2其余部分从x1赋值
            x1sorted(ismember(x1sorted,y2))=[];
            y2([point2+1:nPoint,1:point1-1]) = x1sorted;
            
            c1.Position = y1;
            c2.Position = y2;
            
            
        case 'OX-web'  % 网络获取 未验证真伪
            x1 = p1.Position;
            x2 = p2.Position;
            
            nVar=length(x1);
            
            c=randperm(nVar-1,2); % 返回两个点
            point1=min(c);
            point2=max(c);
            
            % inherit继承x1的部分到y1
            y1=x1(point1+1:point2);
            [~,loc]=ismember(y1,x2);% ex: y1=(1 3),x2=(2 3 1 4 5 6). Donc loc=(3 2)
            loc=sort(loc);
            y1=[x1(1:point1) x2(loc) x1(point2+1:end)];
            
            y2=x2(point1+1:point2);
            [~,loc1]=ismember(y2,x1);
            loc1=sort(loc1);
            y2=[x2(1:point1) x1(loc1) x2(point2+1:end)];
            
            c1.Position = y1;
            c2.Position = y2;
            
        case 'PMX'  % 网络获取 未验证真伪
            
            x1 = p1.Position;
            x2 = p2.Position;
            
            nbrville=length(x1);
            point=randperm(nbrville,2); %deux points de courpures al�aatoires
            pt1=min(point); %premier point de courpure
            pt2=max(point); %deuxieme point de courpure
            
            %Je vais diviser chaque chromosome en 3 parties :
            %P : partie premiere
            %M : partie medium
            %F : partie  Fin
            
            P1=x1(1:pt1);
            P2=x2(1:pt1);
            
            M1=x2(pt1+1:pt2);
            M2=x1(pt1+1:pt2);
            
            nVar1=length(M1);
            nVar2=length(M2);
            
            F1=x1(pt2+1:end);
            F2=x2(pt2+1:end);
            
            for j=1:nbrville
                for i=1:nVar1
                    [a,loc1]=ismember(M1(i),P1);
                    if a==1
                        P1(loc1)=M2(i);
                        break;
                    end
                end
                for i=1:nVar1
                    [b,loc2]=ismember(M1(i),F1);
                    if b==1
                        F1(loc2)=M2(i);
                        
                    end
                end
            end
            y1=[P1,M1,F1];
            
            for n=1:nbrville
                for i=1:nVar2
                    [point,loc3]=ismember(M2(i),P2);
                    if point==1
                        P2(loc3)=M1(i);
                    end
                end
                for i=1:nVar2
                    [d,loc4]=ismember(M2(i),F2);
                    if d==1
                        F2(loc4)=M1(i);
                    end
                end
            end
            y2=[P2,M2,F2];
            
            c1.Position = y1;
            c2.Position = y2;
            
        case  'CX'  % 网络获取 未验证真伪
            
            x1 = p1.Position;
            x2 = p2.Position;
            
            L = length(x1);
            y1=zeros(1,L);
            y2=zeros(1,L);
            
            pt=find(x1==1); %le point de d�part du cycle, Je choisi 1
            
            % On commence par remplire les cases vides du premier fils
            while (y1(pt)==0)
                y1(pt)=x1(pt);
                pt=find(x1==x2(pt));
            end
            
            % On cherche s'il reste des cases vides
            % Si oui, on les remplies par celles du paraent 2
            vide = find(y1==0);
            y1(vide) = x2(vide);
            
            % La m�me chose pour le deuxi�me fils
            pt=find(x2==1);
            while (y2(pt)==0)
                y2(pt)=x2(pt);
                pt=find(x2==x1(pt));
            end
            vide=find(y2==0);
            y2(vide)=x1(vide);

            c1.Position = y1;
            c2.Position = y2;
            
        otherwise
            error('wrong PermutationCrossover');
            
    end

end
