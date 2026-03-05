%% 📊 F1 2026 UNIFIED POST-TESTING MASTER AGGREGATOR (v5.0)
clear; clc; close all;

% 1. Configuration
base_folders = {'F1_Testing_Day_1', 'F1_Testing_Day_2', 'F1_Testing_Day_3', ...
                'F1_Testing_Day_4', 'F1_Testing_Day_5', 'F1_Testing_Day_6'};
output_folder = 'F1_Final_Post_Analysis';
if ~exist(output_folder, 'dir'), mkdir(output_folder); end

% Data Containers
AllDays_Reliability = table();
AllDays_Performance = table();
AllDays_LongRuns    = table();

fprintf('🚀 Phase 1: Global Data Collection...\n');

% 2. Loop through each day's folder
for d = 1:length(base_folders)
    current_day = base_folders{d};
    files = dir(fullfile(current_day, '*.xlsx'));
    if isempty(files), continue; end
    target_path = fullfile(current_day, files(1).name);
    fprintf('    Reading Day %d: %s\n', d, files(1).name);
    
    % --- Load Reliability ---
    try
        day_rel = readtable(target_path, 'Sheet', '2_Reliability');
        day_rel.Day = repmat(d, height(day_rel), 1); 
        AllDays_Reliability = [AllDays_Reliability; day_rel];
    catch; end
    
    % --- Load Performance ---
    try
        day_perf = readtable(target_path, 'Sheet', '3_Peak_Performance');
        day_perf.Day = repmat(d, height(day_perf), 1);
        AllDays_Performance = [AllDays_Performance; day_perf];
    catch; end

    % --- Load Long Runs ---
    try
        day_long = readtable(target_path, 'Sheet', '4_Long_Runs');
        day_long.Day = repmat(d, height(day_long), 1);
        AllDays_LongRuns = [AllDays_LongRuns; day_long];
    catch; end
end

%% 🏎️ Phase 2: PERFORMANCE & STINT ANALYSIS
fprintf('🏁 Phase 2: Processing Leaderboards & Stints...\n');

% A. Pre-Process: Convert lap times to numeric
AllDays_Performance.Sec_FL = lapTimeToSeconds(AllDays_Performance.Fastest_Lap);
AllDays_LongRuns.Sec_Avg = lapTimeToSeconds(AllDays_LongRuns.Avg_Pace);
uDrivers = unique(AllDays_Performance.Driver);
uTyres = unique(AllDays_Performance.Tyre);

% B. GLOBAL BEST LAPS (Every Driver's personal best on each tyre used)
Global_Best_Every_Driver = table();
for i = 1:length(uDrivers)
    for j = 1:length(uTyres)
        sub = AllDays_Performance(strcmp(AllDays_Performance.Driver, uDrivers{i}) & ...
                                  strcmp(AllDays_Performance.Tyre, uTyres{j}), :);
        if isempty(sub), continue; end
        [~, bestIdx] = min(sub.Sec_FL);
        Global_Best_Every_Driver = [Global_Best_Every_Driver; sub(bestIdx, :)];
    end
end

% C. FASTEST DRIVER PER COMPOUND (The "Gold Medal" Leaders)
Fastest_Per_Compound = table();
for j = 1:length(uTyres)
    subTyre = Global_Best_Every_Driver(strcmp(Global_Best_Every_Driver.Tyre, uTyres{j}), :);
    if isempty(subTyre), continue; end
    [~, goldIdx] = min(subTyre.Sec_FL);
    
    row = table(subTyre.Tyre(goldIdx), subTyre.Driver(goldIdx), ...
                subTyre.Fastest_Lap(goldIdx), subTyre.S1(goldIdx), ...
                subTyre.S2(goldIdx), subTyre.S3(goldIdx), ...
                subTyre.Age_at_FL(goldIdx), subTyre.Day(goldIdx), ...
                'VariableNames', {'Compound','Fastest_Driver','Lap_Time','S1','S2','S3','Tyre_Age','Day_Set'});
    Fastest_Per_Compound = [Fastest_Per_Compound; row];
end

% D. BEST LONG RUNS per Compound
Global_Best_Long_Runs = table();
for j = 1:length(uTyres)
    subLR = AllDays_LongRuns(strcmp(AllDays_LongRuns.Tyre, uTyres{j}), :);
    if isempty(subLR), continue; end
    [~, bestLRIdx] = min(subLR.Sec_Avg);
    Global_Best_Long_Runs = [Global_Best_Long_Runs; subLR(bestLRIdx, :)];
end

%% 📈 Phase 3: RELIABILITY & VISUALS
fprintf('📈 Phase 3: Generating Visuals & Workload Stats...\n');

% Cumulative Workload
[drivers, ~, idx] = unique(AllDays_Reliability.Driver);
Overall_Workload = table(drivers, 'VariableNames', {'Driver'});
Overall_Workload.Total_Laps = accumarray(idx, AllDays_Reliability.Grand_Total);
Overall_Workload.Total_Clear = accumarray(idx, AllDays_Reliability.Total_Clean);
Overall_Workload.Total_Unclear = accumarray(idx, AllDays_Reliability.Total_Unclear);
Overall_Workload = sortrows(Overall_Workload, 'Total_Laps', 'descend');

% Color Mapping
DriverColorMap = containers.Map({'VER','HAD','LEC','HAM','NOR','PIA','RUS','ANT'}, ...
    {[0 0 1], [0 0 0.5], [1 0 0], [0.65 0 0], [1 0.6 0], [0.5 0.3 0], [0 0.83 0.77], [0.75 0.75 0.75]});

% Visual 1: Mileage Trend Line
h1 = figure('Name', 'Mileage_Trend', 'Color', 'w'); hold on;
for i = 1:length(drivers)
    d_name = drivers{i};
    d_data = AllDays_Reliability(strcmp(AllDays_Reliability.Driver, d_name), :);
    c = [0.5 0.5 0.5]; if isKey(DriverColorMap, d_name), c = DriverColorMap(d_name); end
    plot(d_data.Day, d_data.Grand_Total, '-o', 'LineWidth', 2, 'MarkerFaceColor', c, 'Color', c, 'DisplayName', d_name);
end
grid on; xlabel('Day'); ylabel('Laps'); title('Reliability: 6-Day Mileage Progression'); legend('Location', 'bestoutside');

% Visual 2: NEW! PACE PROGRESSION (Best Lap per Day)
h2 = figure('Name', 'Pace_Progression', 'Color', 'w'); hold on;
for i = 1:length(drivers)
    d_name = drivers{i};
    d_pace = []; d_days = [];
    for d_idx = 1:length(base_folders)
        day_best = min(AllDays_Performance.Sec_FL(strcmp(AllDays_Performance.Driver, d_name) & AllDays_Performance.Day == d_idx));
        if ~isempty(day_best)
            d_pace = [d_pace, day_best];
            d_days = [d_days, d_idx];
        end
    end
    if ~isempty(d_pace)
        c = [0.5 0.5 0.5]; if isKey(DriverColorMap, d_name), c = DriverColorMap(d_name); end
        plot(d_days, d_pace, '-s', 'LineWidth', 2.5, 'MarkerFaceColor', c, 'Color', c, 'DisplayName', d_name);
    end
end
grid on; xlabel('Testing Day'); ylabel('Fastest Lap Time (Seconds)');
title('Pace Evolution: Driver Improvement Across 6 Days');
set(gca, 'YDir','reverse'); % Lower times at the top (faster)
legend('Location', 'bestoutside');

% Visual 3: Total Mileage Bar Chart
h3 = figure('Name', 'Total_Mileage', 'Color', 'w');
bar(categorical(Overall_Workload.Driver), Overall_Workload.Total_Laps, 'FaceColor', [0.2 0.4 0.6]);
ylabel('Total Laps Completed'); title('F1 2026: Total Testing Mileage'); grid on;

%% 💾 Phase 4: FINAL EXPORT
master_report = fullfile(output_folder, 'F1_2026_ULTIMATE_AGGREGATED_REPORT.xlsx');

writetable(Fastest_Per_Compound,   master_report, 'Sheet', '1_Compound_Winners');
writetable(Global_Best_Long_Runs,  master_report, 'Sheet', '2_Best_Long_Runs');
writetable(Global_Best_Every_Driver, master_report, 'Sheet', '3_Driver_Personal_Bests');
writetable(Overall_Workload,       master_report, 'Sheet', '4_Workload_Leaderboard');
writetable(AllDays_LongRuns,       master_report, 'Sheet', '5_All_Long_Run_Raw');
writetable(AllDays_Reliability,    master_report, 'Sheet', '6_Daily_Reliability_Raw');
writetable(AllDays_Performance,    master_report, 'Sheet', '7_All_Performance_Laps_Raw');

exportgraphics(h1, fullfile(output_folder, 'Mileage_Progression.png'), 'Resolution', 300);
exportgraphics(h2, fullfile(output_folder, 'Pace_Evolution.png'), 'Resolution', 300);
exportgraphics(h3, fullfile(output_folder, 'Total_Mileage_Bar.png'), 'Resolution', 300);

fprintf('✅ DONE! All data and 3 graphs saved in: %s\n', output_folder);

%% 🔧 HELPER FUNCTION
function secs = lapTimeToSeconds(timeCells)
    if ischar(timeCells), timeCells = {timeCells}; end
    secs = zeros(height(timeCells), 1);
    for i = 1:height(timeCells)
        try
            tStr = char(timeCells{i});
            p = strsplit(tStr, ':');
            if length(p) == 3
                secs(i) = str2double(p{1})*60 + str2double(p{2}) + str2double(p{3})/1000;
            elseif length(p) == 2
                secs(i) = str2double(p{1})*60 + str2double(p{2});
            else
                secs(i) = str2double(tStr);
            end
        catch
            secs(i) = NaN;
        end
    end
end