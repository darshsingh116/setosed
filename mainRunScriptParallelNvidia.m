clc;
clear;
clear all;
delete(gcp('nocreate'));

% List available GPUs
gpuCount = gpuDeviceCount();
if gpuCount > 0
    fprintf('Available GPUs:\n');
    for i = 1:gpuCount
        gpuInfo = gpuDevice(i);
        fprintf('GPU %d: %s\n', i, gpuInfo.Name);
    end
else
    fprintf('No GPUs available.\n');
end

% Specify number of runs and significance level
numRuns = 50;
alpha = 0.05;  % Significance level

% Function names (excluding F2)
funcNames = arrayfun(@(x) ['F' num2str(x)], 1:30, 'UniformOutput', false);
funcNames(2) = [];  % Remove F2

% Initialize results storage
originalCosts = cell(1, length(funcNames));
modifiedCosts = cell(1, length(funcNames));
pValues = zeros(1, length(funcNames));

% Set up parallel pool for GPU computations
pool = parpool('local', 'AttachedFiles', {'OriginalSolo.m', 'ModifiedSolo.m', 'CreateInitialShares.m', 'CEC2014.m', 'DumpAndPump.m', 'Exchange.m', 'Falling.m', 'GenerateNewShare.m', 'ModifiedCreateInitialShares.m', 'PumpAndDump.m', 'ModifiedRising.m', 'ModifiedExchange.m', 'ModifiedFalling.m', 'ModifiedGenerateNewShare.m'});
% Automatically select the available Nvidia GPU
gpuDevice(); % This will automatically select the first available Nvidia GPU

% Loop through functions in parallel
parfor i = 1:length(funcNames)
    funcName = funcNames{i};
    
    % Run algorithms and store average costs
    originalCosts{i} = zeros(1, numRuns);
    modifiedCosts{i} = zeros(1, numRuns);
    for run = 1:numRuns
        originalCosts{i}(run) = OriginalSolo(numRuns, funcName);
        modifiedCosts{i}(run) = ModifiedSolo(numRuns, funcName);
        % Print the cost after each run (may not display in real-time due to parallel execution)
        disp(['func', funcNames{i}]);
        fprintf('Run %d - Original Cost: %.4f, Modified Cost: %.4f\n', run, originalCosts{i}(run), modifiedCosts{i}(run));
    end
    
    % Perform two-sample t-test (assuming costs are normally distributed)
    [~, pValues(i)] = ttest2(originalCosts{i}, modifiedCosts{i});
end
% Create new matrices to store the results
originalAnswerMatrix = zeros(length(funcNames), numRuns);
modifiedAnswerMatrix = zeros(length(funcNames), numRuns);

% Store data from original and modified matrices to new matrices
for i = 1:length(funcNames)
    originalAnswerMatrix(i, :) = originalCosts{i};
    modifiedAnswerMatrix(i, :) = modifiedCosts{i};
end
% Display results
for i = 1:length(funcNames)
    funcName = funcNames{i};
    avgOriginalCost = mean(originalCosts{i});
    avgModifiedCost = mean(modifiedCosts{i});
    pValue = pValues(i);
    
    fprintf('Function: %s\n', funcName);
    fprintf('  Average Original Cost: %f\n', avgOriginalCost);
    fprintf('  Average Modified Cost: %f\n', avgModifiedCost);
    if pValue < alpha
        fprintf('  p-value: %f better\n', pValue);
        fprintf('  Modified algorithm performs statistically better.\n');
    else
        fprintf('  p-value: %f worse\n', pValue);
        fprintf('  No statistically significant difference found.\n');
    end
    fprintf('\n');
end

% Delete the parallel pool
delete(gcp('nocreate'));
