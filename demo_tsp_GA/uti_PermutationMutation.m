function [c1]=uti_PermutationMutation(p1,mutationType,individual)
        
        c1=individual;
        tour1 = p1.Position;
        n=numel(tour1);

        switch mutationType
            case 'swap'
                % swap -> ii and jj 不能相同
                I = randperm(n,2);
                ii = I(1);
                jj = I(2);
                
                tour2 = tour1;
                tour2([ii jj])=tour1([jj ii]);
                
            case 'insert'
                % insert -> ii and jj 不能相同
                I = randperm(n,2);
                ii = I(1);
                jj = I(2);
                if ii<jj
                    tour2=tour1([1:ii-1 ii+1:jj ii jj+1:end]);
                else
                    tour2=tour1([1:jj ii jj+1:ii-1 ii+1:end]);
                end
                
            case '2opt'
                % 2opt -> ii必须<n-1; jj必须>ii+1; jj必须<n或ii为1时,jj必须<n-1;
                
                % ii必须<n-1;
                ii = randperm(n,1);
                while ii >= n-1
                    ii = randperm(n,1);
                end
                
                % jj必须>ii+1; ii为1时,jj必须<n-1;
                jj = randperm(n,1);
                while jj <= ii+1 || (ii==1 && jj>=n-1)
                    jj = randperm(n,1);
                end
                
                tour2 = [tour1(1:ii) fliplr(tour1(ii+1:jj)) tour1(jj+1:end)];
                
            case 'doublebridge'
                n =length(tour1);
                
                pos1 = randi(round(n/4),1,1);
                pos2 = pos1 + randi(round(n/4),1,1);
                pos3 = pos2 + randi(round(n/4),1,1);
                
                tour2 = [ tour1(1:pos1) , tour1(pos3+1:end), tour1(pos2+1: pos3), tour1(pos1+1 : pos2)];

            otherwise
                error('wrong Shake type');
        end
        
        c1.Position = tour2;        

end