function [Shares, globalCost] = PumpAndDump2(Shares, AlgorithmParams, ProblemParams, globalCost, ub, lb, beta)
    % Generate random shares around the best share
    numSharesToGenerate = 10;
    rangeFactor = beta*rand(); % Adjust this factor as needed
    
    bestIndex = find([Shares.Cost] == min([Shares.Cost]), 1);
    bestPosition = Shares(bestIndex).Position;
    
    for i = 1:numSharesToGenerate
        % Generate a random position around the best position within the specified range
        newPosition = bestPosition + rangeFactor * (ub - lb) * (rand(1, ProblemParams.NPar) - 0.5);
        
        % Ensure positions are within bounds
        newPosition(newPosition > ub) = ub;
        newPosition(newPosition < lb) = lb;
        
        % Evaluate cost for the new position
        newCost = feval(ProblemParams.CostFuncName, newPosition);
        
        % Check if the new cost is less than the current best cost
        if newCost < globalCost
            % Replace shares in the top 10th to 20th position with the new share
            [~, sortIndices] = sort([Shares.Cost], 'ascend');
            replaceIndices = sortIndices(10:20);
            Shares(replaceIndices(1)).Position = newPosition;
            Shares(replaceIndices(1)).Cost = newCost;
            
            % Update global cost
            globalCost = newCost;
        end
    end
end
