% License -- COPYRIGHT
% Copyright (c) 2025 Thanasis Charalambous
% Licensed under the MIT License. See LICENSE file in the project root.

% Author: Thanasis Charalambous
% Role: Data Analysis Engineer
% DATE:  25/11/2025

% PURPOSE: Analyzes Lando Norris's (NOR) race performance from the 2025 São Paulo Grand Prix.
% It applies statistical filtering (2-sigma, clear status) to isolate 'pace laps' 
% and calculates key metrics including best fuel-corrected lap and tire degradation 
% rates (ms/lap) for each stint. Results are printed and visualized.

clc
clear
close all

%% 1. CONFIGURATION AND DATA LOADING 
% Define all constants and parameters at the beginning for easy adjustment.

% 1.1 File Configuration
FILE_PATH = 'são-paulo-grand-prix-race-NOR-TracingInsights.com-datatable-2025-11-19.csv';
HEADER_LINES = 15; % Number of header rows to skip
REQUIRED_COLS = {'LAP', 'NOR_SECTOR_SUM', 'NOR_COMPOUND', 'NOR_STINT', 'NOR_PITSTOP', 'NOR_TIRE_LIFE', 'NOR_STATUS', 'NOR_POSITION', 'NOR_TIME'};

% 1.2 Race Parameters
DRIVER_NAME = 'Lando Norris (NOR)';
RACE_TITLE = '2025 São Paulo Grand Prix';
MAX_FUEL_KG = 110; % F1 mandated maximum fuel load
PACE_GAIN_PER_LAP = 0.041575; % Fuel correction constant (s/lap). Derived from track-specific analysis.

fprintf('Loading Data for %s from %s...\n', DRIVER_NAME, FILE_PATH);

% 1.3 Data Import with Robust Error Handling
try
    T = readtable(FILE_PATH, "NumHeaderLines", HEADER_LINES, 'Delimiter', ',');
catch ME
    error('DATA_LOAD_ERROR: Could not load the CSV file. Check path and permissions. MATLAB Error: %s', ME.message);
end

% 1.4 Data Validation
if ~all(ismember(REQUIRED_COLS, T.Properties.VariableNames))
    missing_cols = setdiff(REQUIRED_COLS, T.Properties.VariableNames);
    error('DATA_COL_ERROR: CSV is missing one or more required columns: %s', strjoin(missing_cols, ', '));
end

TotalRaceLaps = height(T);
DriverStartPosition = T.NOR_POSITION(1);
DriverFinishPosition = T.NOR_POSITION(end);


%% 2. DATA PRE-PROCESSING AND FILTERING 

% 2.1 Convert Pitstop/Status Indicators to Standard Types
% Ensure 'NOR_PITSTOP' is a logical array (TRUE/FALSE)
% From TRUE/FALSE to 1/0
if iscell(T.NOR_PITSTOP)
    T.NOR_IS_PITSTOP = strcmp(T.NOR_PITSTOP, 'TRUE');
else
    T.NOR_IS_PITSTOP = logical(T.NOR_PITSTOP);
end
T.NOR_STATUS_STR = string(T.NOR_STATUS); % Convert numeric status to string for reliable filtering

% 2.2 Define Masks for Clear Laps (Statistical Pace Analysis)
% '1' = Clear track status (valid pace lap)
track_clear_status_mask = T.NOR_STATUS_STR == "1"; % 1 for yes, 0 for no
safety_car_laps_mask = contains(T.NOR_STATUS_STR, "4"); % 1 for yes, 0 for no
safety_car_laps_count = sum(safety_car_laps_mask);

% Identify In-laps (lap before a pit) and Out-laps (lap after a pit)
is_in_lap_mask = T.NOR_IS_PITSTOP; % Lap where pitstop occurs
is_out_lap_mask = [false; T.NOR_IS_PITSTOP(1:end-1)]; % Lap AFTER the pit stop 

% Combined mask for 'Clear Laps' - used for degradation/best lap analysis
clear_laps_mask = track_clear_status_mask & ~is_in_lap_mask & ~is_out_lap_mask;

% 2.3 Filtered Dataset for Robust PACE ANALYSIS
clearLapsDataset = T(clear_laps_mask, :);
initial_clear_laps_count = height(clearLapsDataset);

% 2.4 Apply 2-Sigma (2σ) Outlier Filtering
% Removes statistically slow laps (e.g., minor traffic or small driver error) 
% that were not flagged by 'NOR_STATUS'.
if initial_clear_laps_count > 1
    mean_clear_lap_time = mean(clearLapsDataset.NOR_SECTOR_SUM);
    sigma = std(clearLapsDataset.NOR_SECTOR_SUM);
    upper_bound_time = mean_clear_lap_time + 2 * sigma;
    
    sigma_filter = (clearLapsDataset.NOR_SECTOR_SUM <= upper_bound_time);
    clearLapsDataset = clearLapsDataset(sigma_filter, :);
    
    laps_removed_2sigma = initial_clear_laps_count - height(clearLapsDataset);
    upper_bound_disp = convertTime(upper_bound_time);
    fprintf('  Applied 2-σ Filter: Removed %d laps (Slower than %s ).\n', laps_removed_2sigma, upper_bound_disp);
else
    fprintf('  Skipped 2-σ Filter: Not enough clear laps for statistical filtering.\n');
end

valid_pace_laps_count = height(clearLapsDataset);

% 2.5 Calculate Fuel-Corrected Lap Time (Normalization)
% This removes the performance gain as fuel is burned, normalizing lap times
% to an empty tank baseline to assess true tire/car performance.
% Fuel_Corrected_Time = RawLapTime - (PaceGainPerLap * Laps_Remaining)

laps_already_completed = clearLapsDataset.LAP - 1;
laps_remaining_plus_current = TotalRaceLaps - laps_already_completed;

fuel_correction_substraction = laps_remaining_plus_current * PACE_GAIN_PER_LAP;
clearLapsDataset.NOR_FUEL_CORR_TIME = clearLapsDataset.NOR_SECTOR_SUM - fuel_correction_substraction;

% 2.6 Determine Sequential Race Strategy
stints = unique(T.NOR_STINT);
strategy_sequence = cell(length(stints), 1);
for i = 1:length(stints)
    stint_data = T(T.NOR_STINT == stints(i), :);
    if ~isempty(stint_data)
        strategy_sequence{i} = stint_data.NOR_COMPOUND{1};
    end
end
race_strategy_str = strjoin(strategy_sequence', ' → '); % Join strings in array

fprintf('Data processing complete. Total laps: %d. Robust pace laps remaining: %d.\n', TotalRaceLaps, valid_pace_laps_count);

%% 3. OVERALL RACE STATISTICS CALCULATION

% Metrics based on FULL RACE DATA (T)
all_lap_times = T.NOR_TIME;
total_race_time = sum(all_lap_times);
median_full_time = median(all_lap_times);
avg_full_time = mean(all_lap_times);
std_dev_full = std(all_lap_times);

% Metrics based on FILTERED CLEAR LAPS (clearLapsDataset)
all_clear_lap_times = clearLapsDataset.NOR_TIME;
[best_lap_time, best_lap_idx] = min(all_clear_lap_times);
best_lap_num = clearLapsDataset.LAP(best_lap_idx);

all_fuel_corr_times = clearLapsDataset.NOR_FUEL_CORR_TIME;
[best_fuel_corr_lap, best_fuel_corr_lap_idx] = min(all_fuel_corr_times);
best_fuel_corr_lap_num = clearLapsDataset.LAP(best_fuel_corr_lap_idx);

% Consistency using Coefficient of Variation (CV)
consistency_perc_full = calculate_consinsency_cv(all_lap_times);
track_clear_laps = sum(T.NOR_STATUS_STR == "1");
unique_incident_laps = TotalRaceLaps - track_clear_laps;

%% 4. DISPLAY SUMMARY RESULTS

fprintf('\n======================================================\n');
fprintf('⚡ F1 RACE PACE ANALYSIS - %s\n', DRIVER_NAME);
fprintf('======================================================\n');
fprintf('Race: %s\n', RACE_TITLE);
fprintf('Strategy: %s\n', race_strategy_str);
fprintf('Total Race Time: %s\n', convertTime(total_race_time));
fprintf('Position Change: %d -> %d (%+d)\n', DriverStartPosition, DriverFinishPosition, DriverFinishPosition - DriverStartPosition);
fprintf('--------------------------------------------\n');
fprintf('Pace Laps (Clear Status "1"): %d\n', track_clear_laps);
fprintf('Statistically Robust Laps (2-σ): %d\n', valid_pace_laps_count);
fprintf('Incident/Pit Laps: %d\n', unique_incident_laps);
fprintf('Safety Car Laps: %d\n', safety_car_laps_count);
fprintf('--------------------------------------------\n');
fprintf('🥇 Best Lap (Raw): %s (L%d)\n', convertTime(best_lap_time), best_lap_num);
fprintf('⛽ Best Lap (Fuel-Corrected): %s (L%d)\n', convertTime(best_fuel_corr_lap), best_fuel_corr_lap_num);
fprintf('Average Lap (Full Race): %s\n', convertTime(avg_full_time));
fprintf('Median Lap (Full Race): %s\n', convertTime(median_full_time));
fprintf('Overall Consistency (Full Race): %.2f%%\n', consistency_perc_full);
fprintf('============================================\n');


%% 5. STINTS ANALYSIS AND DEGRADATION

fprintf('\n=== STINT-BY-STINT BREAKDOWN ===\n');

% The variable 'stint_num' from the original code is undefined here. Use 'length(stints)'.
for i = 1:length(stints)
    current_stint_num = stints(i);
    fprintf('\n--- STINT %d (%s) ---\n', current_stint_num, strategy_sequence{i});

    % Full data for Stint i (includes pit/out/slow laps)
    stint_data_full = T(T.NOR_STINT == current_stint_num, :);
    stint_length = height(stint_data_full);
    
    stint_all_lap_times = stint_data_full.NOR_TIME;
    stint_total_time = sum(stint_all_lap_times);
    
    stint_avg_full_time = mean(stint_all_lap_times);
    stint_median_full_time = median(stint_all_lap_times);
    stint_std_dev_full = std(stint_all_lap_times);
    
    [stint_best_lap_time, stint_best_lap_idx] = min(stint_data_full.NOR_TIME);
    stint_best_lap_num = stint_data_full.LAP(stint_best_lap_idx);
    
    stint_consistency_perc = calculate_consinsency_cv(stint_all_lap_times);
    
    % Degradation Calculation (using ONLY clear, robust pace laps)
    stint_clear_lap = clearLapsDataset(clearLapsDataset.NOR_STINT == current_stint_num, :);
    if height(stint_clear_lap) >= 2
        % Independent variable: Tire life (laps on this set)
        x_deg = stint_clear_lap.NOR_TIRE_LIFE;
        % Dependent variable: Lap time (seconds)
        y_deg = stint_clear_lap.NOR_TIME;

        % Perform linear regression (polyfit degree 1)
        P = polyfit(x_deg, y_deg, 1);
        pace_per_lap_s = P(1); % Slope is degradation rate in s/lap
        pace_per_lap_ms = pace_per_lap_s * 1000; % Convert to ms/lap
        deg_str = sprintf('%.1f ms/lap (%.3f s/lap)', pace_per_lap_ms, pace_per_lap_s);
    else
        deg_str = 'N/A (requires >=2 robust laps)';
    end

    fprintf('Stint Laps: %d\n', stint_length);
    fprintf('Stint Duration: %s\n', convertTime(stint_total_time));
    fprintf('Best Lap: %s (L%d)\n', convertTime(stint_best_lap_time), stint_best_lap_num);
    fprintf('Average Lap Time: %s\n', convertTime(stint_avg_full_time));
    fprintf('Median Lap Time: %s\n', convertTime(stint_median_full_time));
    fprintf('St Dev: %s\n', convertTime(stint_std_dev_full));
    fprintf('Consistency: %.2f%%\n', stint_consistency_perc);
    fprintf('Degradation: %s\n', deg_str);
end
fprintf('--------------------------------------\n');


%% 6. PLOTS AND VISUALIZATIONS

% 6.0 Tire Color Configuration (Moved setup here for clarity)
TireData = table(...
    {'SOFT'; 'MEDIUM'; 'HARD' ; 'INTERMEDIATE'; 'FULL WET'}, ...
    {[1.0 0.0 0.0]; [1.0 1.0 0.0]; [0.4 0.4 0.4]; [0.0 0.5 0.0]; [0.0 0.0 1.0]}, ...
    'VariableNames', {'Compound', 'ColorName'});

% 6.1 FIGURE 1: Race Pace by Stint and Compound
figure('Renderer','painters', 'Position', [100 100 1200 550])
hold on
grid on
title(['Race Pace by Stint and Compound - ' DRIVER_NAME], 'FontSize', 16)
xlabel('Race Laps', 'FontSize', 14)
ylabel('Lap Time (s)', 'FontSize', 14)
legend_handles = plotRacePaceByStint(T, TireData); 
legend(legend_handles, 'Location', 'best', 'FontSize', 11);
hold off

% 6.2 FIGURE 2: Clear Laps per Stint with Regression
figure('Renderer', 'painters', 'Position', [100 100 1200 550])
hold on
grid on
title(['Clear Laps per Stint (Regression Analysis) - ' DRIVER_NAME], 'FontSize', 16)
xlabel('Race Laps', 'FontSize', 14)
ylabel('Lap Time (s)', 'FontSize', 14)

legend_handles = [];
for i = 1:length(stints)
    current_stint_number = stints(i);
    stint_data = clearLapsDataset(clearLapsDataset.NOR_STINT == current_stint_number, :);

    if ~isempty(stint_data)
        current_compound = stint_data.NOR_COMPOUND{1};
        stint_color = getCompoundColor(current_compound, TireData);

        % Scatter Plot
        h_scatter = scatter(stint_data.LAP, stint_data.NOR_TIME, ...
        'Marker', 'o', 'MarkerFaceColor', stint_color, 'MarkerEdgeColor', stint_color, ...
        'DisplayName', ['Stint ' num2str(current_stint_number) ' : ' current_compound]);

        % Median Line
        median_time = median(stint_data.NOR_TIME);
        yline(median_time, '--', 'Color', stint_color, 'LineWidth', 1.5, 'HandleVisibility','off');

        % 4th-Degree Polynomial Regression Line (Smoothing)
        if height(stint_data) >= 5 % Polynomial fit requires enough points
             x_local = (stint_data.LAP - min(stint_data.LAP)) + 1;
             p = polyfit(x_local, stint_data.NOR_TIME, 4);
             x_fit_local = linspace(min(x_local), max(x_local), 100);
             y_fit = polyval(p, x_fit_local);
             x_global_fit = x_fit_local + min(stint_data.LAP) - 1;
             plot(x_global_fit, y_fit, '-', 'Color', stint_color, 'LineWidth', 2, 'HandleVisibility','off');
        end
        legend_handles = [legend_handles, h_scatter];
    end
end
legend(legend_handles, 'Location', 'best', 'FontSize', 11);
hold off

% 6.3 FIGURE 3: Stint Pace Distribution (Function call)
plotStintDistribution(clearLapsDataset, DRIVER_NAME, TireData);

% 6.4 FIGURE 4: Pace vs. Tire Life (Raw Lap Time)
figure('Renderer','painters', 'Position', [100 100 1200 550])
hold on
grid on
title(['Pace vs. Tire Life (Raw Lap Time) - ' RACE_TITLE], 'FontSize', 16, 'FontWeight', 'bold');
subtitle(DRIVER_NAME, "FontSize", 14, 'FontWeight','normal');
xlabel('Tire Life (Laps)','FontSize',14); 
ylabel('Lap Time (s)','FontSize',14);

% Temporary Data Modification: Map X-axis to Tire Life, Y-axis to Raw Time
temp_data_fig4 = clearLapsDataset;
temp_data_fig4.LAP = temp_data_fig4.NOR_TIRE_LIFE; % X-axis
temp_data_fig4.NOR_TIME = temp_data_fig4.NOR_SECTOR_SUM; % Y-axis (using Sector Sum for consistency with pace)
legend_handles = plotRacePaceByStint(temp_data_fig4, TireData);
legend(legend_handles, 'Location', 'northeast', 'FontSize', 11);
hold off

% 6.5 FIGURE 5: Race Laps vs Driver Position
figure('Renderer','painters', 'Position', [100 100 1200 550])
grid on
title(['Position During Race - ' DRIVER_NAME], 'FontSize', 16)
subtitle(RACE_TITLE)
xlabel('Race Laps', 'FontSize', 14)
ylabel('Race Position', 'FontSize', 14)
xlim([1 height(T)])
ylim([0 20])
set(gca, 'YDir', 'reverse') % Invert Y-axis
hold on
plot(T.LAP, T.NOR_POSITION, "LineWidth", 2, "Marker", 'o', "Color", [1.0 0.6471 0.0]) % McLaren Orange/Papaya
hold off

% 6.6 FIGURE 6: Tire Life vs. Fuel Corrected Pace
figure('Renderer','painters', 'Position', [100 100 1200 550])
hold on
grid on
title(['Normalized Pace (Fuel Corrected) vs. Tire Life - ' DRIVER_NAME], 'FontSize', 16)
subtitle(RACE_TITLE)
xlabel('Tire Life (Laps)', 'FontSize', 14)
ylabel('Fuel Corrected Lap Time (s)', 'FontSize', 14)

% Temporary Data Modification: Map X-axis to Tire Life, Y-axis to Fuel Corrected Time
temp_data_fig6 = clearLapsDataset;
temp_data_fig6.LAP = temp_data_fig6.NOR_TIRE_LIFE; % X-axis
temp_data_fig6.NOR_TIME = temp_data_fig6.NOR_FUEL_CORR_TIME; % Y-axis (Critical: plots the corrected time)

legend_handles = plotRacePaceByStint(temp_data_fig6, TireData);
legend(legend_handles, 'Location', 'best', 'FontSize', 11);
hold off





%% --- 7. HELPER FUNCTIONS ---
% These functions have been cleaned up for better variable naming and robustness.

function consistency_perc = calculate_consinsency_cv(lap_times)
% CALCULATE_CONSINSENCY_CV Calculates consistency as 100% minus the Coefficient of Variation (CV).
    if length(lap_times) < 2
        consistency_perc = 0;
        return;
    end
    
    sigma = std(lap_times);
    mu = mean(lap_times);
    CV = sigma / mu;
    consistency_perc = 100 - (CV * 100);
    consistency_perc = max(0, consistency_perc); % Ensure consistency is non-negative
end


function timing_string = convertTime(total_seconds)
% CONVERTTIME Converts a total time in seconds into a M:SS:MMM format string.
    m = floor(total_seconds / 60);
    remaining_seconds = total_seconds - (m * 60);
    s = floor(remaining_seconds);
    ms = round((remaining_seconds - s) * 1000); % Round to nearest millisecond
    
    timing_string = sprintf('%d:%02d:%03d', m, s, ms);
end


function h_legend = plotRacePaceByStint(T_data, TireData)
% PLOTRACEPACEBYSTINT Draws a segmented plot (lap time vs. race lap or tire life) 
% colored by the tire compound, suitable for Figures 1, 4, and 6.
    
    hold on;
    unique_stints = unique(T_data.NOR_STINT);
    h_legend = []; 
    compounds_plotted = {}; % Tracks compounds already in the legend

    for i = 1:length(unique_stints)
        current_stint_number = unique_stints(i);
        data_for_stint = T_data(T_data.NOR_STINT == current_stint_number, :);
        
        if isempty(data_for_stint)
            continue;
        end
        
        current_compound = data_for_stint.NOR_COMPOUND{1};
        
        % Look up RGB color
        color_idx = strcmp(TireData.Compound, current_compound); % Compare strings ( 1 if same, 0 if not)
        if any(color_idx)
            current_compound_rgb = TireData.ColorName{color_idx};
        else
            current_compound_rgb = [0 0 0]; % Black fallback
        end
        
        % Plot the segment
        h_plot = plot(data_for_stint.LAP, data_for_stint.NOR_TIME, ...
            'Color', current_compound_rgb, ...
            'LineStyle', '-', ...
            'LineWidth', 1.5, ...
            'Marker', 'o', ...
            'MarkerSize', 6, ...
            'MarkerFaceColor', current_compound_rgb);
        
        % Manage Legend: Only add one entry per compound type
        if ~ismember(current_compound, compounds_plotted) % Lia= ismember(A,B). Determine which elements of A are also in B. 
            h_plot.DisplayName = current_compound;
            h_legend = [h_legend, h_plot];
            compounds_plotted = [compounds_plotted, current_compound];
        else
            h_plot.HandleVisibility = 'off';
        end
    end
end


function rgb_color = getCompoundColor(compound_name, TireData)
% GETCOMPOUNDCOLOR Looks up the RGB color for a given tire compound.
    color_idx = strcmp(TireData.Compound, compound_name);
    
    if any(color_idx)
        rgb_color = TireData.ColorName{color_idx};
    else
        rgb_color = [0 0 0];
    end
end


function plotStintDistribution(clearLapsDataset, Driver_Name, TireData)
% PLOTSTINTDISTRIBUTION Generates the Stint Pace Scatter plot (Figure 3).
% Plots jittered lap times, mean/median lines, and shows data distribution.

    rng('default'); %  Control random number generator
    average_line_width = 0.5;
    
    stints = unique(clearLapsDataset.NOR_STINT);
    num_stints = length(stints);
    
    % Pre-allocate storage
    mean_times = zeros(1, num_stints);
    median_times = zeros(1, num_stints);
    all_stint_times = cell(1, num_stints);
    stint_plot_positions = zeros(1, num_stints);
    stint_compounds = cell(1, num_stints);

    for i = 1:num_stints
        current_stint_number = stints(i);
        stint_data = clearLapsDataset(clearLapsDataset.NOR_STINT == current_stint_number, :);
        
        if ~isempty(stint_data)
            mean_times(i) = mean(stint_data.NOR_TIME);
            median_times(i) = median(stint_data.NOR_TIME);
            all_stint_times{i} = stint_data.NOR_TIME;
            stint_plot_positions(i) = i;
            stint_compounds{i} = stint_data.NOR_COMPOUND{1};
        else
            % Use NaN to filter out empty stints after loop
            stint_plot_positions(i) = NaN; 
        end
    end

    valid_stints_idx = ~isnan(stint_plot_positions);
    stint_plot_positions = stint_plot_positions(valid_stints_idx);
    mean_times = mean_times(valid_stints_idx);
    median_times = median_times(valid_stints_idx);
    stints_valid = stints(valid_stints_idx);
    all_stint_times_filtered = all_stint_times(valid_stints_idx);
    stint_compounds_filtered = stint_compounds(valid_stints_idx);

    % Create Figure
    figure('Renderer', 'painters', 'Position', [100 100 1200 550])
    hold on
    grid on
    title(['Stint Pace Distribution (Variability and Central Tendency) - ' Driver_Name], 'FontSize', 16)
    xlabel('Stint Compound', 'FontSize', 14)
    ylabel('Lap Time (s)', 'FontSize', 14)
    
    h_mean_ref = [];
    h_median_ref = [];
    h_data_ref = [];

    for i = 1:length(stints_valid)
        current_stint_plot_pos = stint_plot_positions(i);
        current_stint_times = all_stint_times_filtered{i};
        current_compound = stint_compounds_filtered{i};
        current_color = getCompoundColor(current_compound, TireData);
        
        % JITTERED SCATTER PLOT
        jitter = (rand(size(current_stint_times)) * 0.4) - 0.2;
        h_scatter = scatter(current_stint_plot_pos + jitter, current_stint_times, ...
                            30, current_color, 'filled', 'MarkerFaceAlpha', 0.5);
        
        % MEAN Line
        h_mean = plot([current_stint_plot_pos - average_line_width/2, current_stint_plot_pos + average_line_width/2], ...
                      [mean_times(i), mean_times(i)], ...
                      ':', 'LineWidth', 2, 'Color', current_color);
        
        % MEDIAN Marker
        h_median = scatter(current_stint_plot_pos, median_times(i), ...
                           150, current_color, 's', 'filled', 'Marker', 'diamond');
        
        % Legend Management (Reference Handles)
        if isempty(h_mean_ref)
            h_mean_ref = h_mean;
            h_median_ref = h_median;
            h_data_ref = h_scatter;
        end
        h_scatter.HandleVisibility = 'off';
        h_mean.HandleVisibility = 'off';
        h_median.HandleVisibility = 'off';
    end

    % Final Formatting
    xlim([min(stint_plot_positions)-0.5 max(stint_plot_positions)+0.5]);
    xticks(stint_plot_positions);
    xticklabels(stint_compounds_filtered);
    
    legend_elements = [h_data_ref, h_mean_ref, h_median_ref];
    legend_names = {'Lap Times (Jittered)', 'Stint Mean', 'Stint Median'};
    legend(legend_elements, legend_names, 'Location', 'best', 'FontSize', 11);
    hold off
end