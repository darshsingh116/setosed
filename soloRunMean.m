numRuns = 15;
globalCosts = zeros(1, numRuns);
   
    for run = 1:numRuns
        
        alpha=0.5;
        alphaDump=0.98;
        RSITimeFrame=15;
        
        ProblemParams.CostFuncName = "F1";
        
        
        %[lowerbound, upperbound, dimension, fobj]=Get_Functions_details(ProblemParams.CostFuncName);
        [lowerbound, upperbound, dimension, fobj]=CEC2017(ProblemParams.CostFuncName);
        globalCost=0;
        
        ProblemParams.CostFuncName=fobj;
        ProblemParams.lb=lowerbound;
        ProblemParams.ub=upperbound;
        ProblemParams.NPar = dimension;
        ProblemParams.gcost=globalCost;
        
        ProblemParams.VarMin =ProblemParams.lb;
        ProblemParams.VarMax = ProblemParams.ub;
        rangeWidth =  ProblemParams.ub-ProblemParams.lb;
        
        
        %fprintf("here");
        if isscalar(ProblemParams.VarMin)
            
            ProblemParams.VarMin=repmat(ProblemParams.VarMin,1,ProblemParams.NPar);
            ProblemParams.VarMax=repmat(ProblemParams.VarMax,1,ProblemParams.NPar);
            
        end
        ProblemParams.SearchSpaceSize = ProblemParams.VarMax - ProblemParams.VarMin;
        
        if isscalar(ProblemParams.VarMin) && isscalar(ProblemParams.VarMax)
           % fprintf("there");
            ProblemParams.dmax = (ProblemParams.VarMax-ProblemParams.VarMin)*sqrt(ProblemParams.NPar);
        else
            %fprintf("there2");
            ProblemParams.dmax = norm(ProblemParams.VarMax-ProblemParams.VarMin);
        end
        
        
        %% Algorithmic Parameter Setting
        AlgorithmParams.NumOfShares = 25;
        AlgorithmParams.NumOfTraders = 100;
        AlgorithmParams.NumOfDays = 100;
        
        InitialShares = ModifiedGenerateNewShare(AlgorithmParams.NumOfShares, ProblemParams);
        InitialCost = zeros(1, AlgorithmParams.NumOfShares); % Initialize an array to store individual costs
        for i = 1:AlgorithmParams.NumOfShares
            InitialCost(i) = feval(ProblemParams.CostFuncName, InitialShares(i,:)); % Calculate cost for each share
        end
        %InitialCost = feval(ProblemParams.CostFuncName,InitialShares); %here error
        Shares = ModifiedCreateInitialShares(InitialShares,InitialCost',AlgorithmParams, ProblemParams); %sometimes ' is used sometimes not note
        
        local=Shares;
        Costs = [Shares.Cost];
        BestIndex = find(Costs == min(Costs));
        %fprintf(BestIndex);
        bestSolution = Shares(BestIndex).Position;
        globalCost = Shares(BestIndex).Cost;
        
        for itr = 1:AlgorithmParams.NumOfDays
            
            for ii=1:AlgorithmParams.NumOfShares
                if(itr>RSITimeFrame && Shares(ii).RSI(itr-1)<40)
                    [Shares, AlgorithmParams]= ModifiedRising(ii,Shares,AlgorithmParams,ProblemParams,bestSolution,itr, alpha);
                elseif(itr>RSITimeFrame && Shares(ii).RSI(itr-1)>70)
                    [Shares, local, AlgorithmParams]= ModifiedFalling(ii,Shares, local, AlgorithmParams,ProblemParams,bestSolution,itr);
                else
                    r=rand;
                    if(r>0.2)
                        [Shares, AlgorithmParams]= ModifiedRising(ii,Shares,AlgorithmParams,ProblemParams,bestSolution,itr, alpha);
                    else
                        [Shares, local, AlgorithmParams]= ModifiedFalling(ii,Shares, local, AlgorithmParams,ProblemParams,bestSolution,itr);
                    end
                end
                
                [Shares, AlgorithmParams]= ModifiedExchange(Shares, AlgorithmParams);
                
                si=numel(Shares(ii).priceChanges);
                if(itr>=RSITimeFrame)
                    Pi=sum(Shares(ii).priceChanges(itr-RSITimeFrame+1:itr)>0);
                    Ni=sum(Shares(ii).priceChanges(itr-RSITimeFrame+1:itr)<0);
                    Shares(ii).RSI(itr)=100-(100/(1+(Pi/Ni)));
                end
                
            end
            
            Costs = [Shares.Cost];
            BestIndex = find(Costs == min(Costs),1);
            currentBestSolution = Shares(BestIndex).Position;
            currentBestCost = Shares(BestIndex).Cost;
            if(currentBestCost< globalCost)
                globalCost= currentBestCost;
                bestSolution=currentBestSolution;
            else
                Shares(BestIndex).Position=bestSolution;
            end
            
            %fprintf('Minimum Cost in Iteration %d is %e \n', itr, globalCost);
            alpha=alpha*alphaDump;
        end
   

        fprintf('Minimum Cost in Run %d is %e \n', run, globalCost)
        globalCosts(run) = globalCost;
    end

    % Calculate average global cost
    avgCost = mean(globalCosts);
    disp(['Modified Average Global Cost after ' num2str(numRuns) ' runs: ' num2str(avgCost)]);