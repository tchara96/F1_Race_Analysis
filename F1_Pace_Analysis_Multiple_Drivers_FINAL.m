% License -- COPYRIGHT
% Copyright (c) 2025 Thanasis Charalambous
% Licensed under the MIT License. See LICENSE file in the project root.

% Author: Thanasis Charalambous
% Role: Data Analysis Engineer
% DATE:  09/12/2025

% PURPOSE: Analyzes Abu Dhabi's 2025 all 3 practice sessions performance.
% Focused on the 3 title contenters
% Norris, Verstappen, Norris
% For Pace comparison 

clc
clear
close all

%% 1. CONFIGURATION AND DATA LOADING
FILE_PATH ='abu-dhabi-grand-prix-practice-1';
RACE_TITLE ='2025 Abu Dhabi Practice 1';
fprintf('Loading Data...\n %s\n',RACE_TITLE);
% Data Import from csv file
try
DATA = readtable(FILE_PATH, 'Delimiter',',');
catch ME
    error('DATA LOAD ERROR: Could not load the CSV file. Check path and permissions. MATLAB Error: %s', ME.message);
end

%% 2. DATA PRE-PROCESSING & FILTERING
% number of data columns per driver
data_columns = 13; % 13 columns for each driver
% Data information
laps = DATA(:,1); % 1st column: Laps
number_drivers = (width(DATA)-1)/data_columns;

% Change for Drivers based on order of DATA
drivers_names = {'VER','NOR'};
% Get data for each driver specifically
driver_data_cell = cell(1, number_drivers); % Preallocate the cell array
for i = 1:number_drivers
    low_num(i) = data_columns * (i-1) + 2;
    high_num(i) = data_columns * (i-1) + 14;
    current_low_num = low_num(i);
    current_high_num = high_num(i);
    driver_data_cell{i} = DATA(:, current_low_num:current_high_num);
    % Create the new variable name,  'driver1', 'driver2'
    variable_name = ['data_driver_', num2str(i)];
    % Use eval to assign the data slice to the dynamic variable name
    eval([variable_name, ' = DATA(:, current_low_num : current_high_num);']);
end
% Connect data to DRIVERS
driver_data_struct = struct(); % Initialize an empty structure
for i = 1:number_drivers
    % Get the current driver's name string,  'NORRIS'
    name_str = drivers_names{i};
    low_num = data_columns * (i - 1) + 2;
    high_num = data_columns * (i - 1) + 14;
    % Store the data slice in a field named after the driver
    %  driver_data_struct.NORRIS = DATA(:, 2:14);
    driver_data_struct.(name_str) = DATA(:, low_num : high_num);
end
% Define constants used by the function
PITSTOP_SOURCE_COL = 6;
TRACK_STATUS_SOURCE_COL = 12;
for i = 1:number_drivers
    current_driver_name = drivers_names{i};
    % 1. Access the table
    driver_table = driver_data_struct.(current_driver_name);
    % 2. Process ALL operations in one function call
    driver_table_processed = processAllDriverData(driver_table, PITSTOP_SOURCE_COL, TRACK_STATUS_SOURCE_COL);
    % 3. Update the struct field
    driver_data_struct.(current_driver_name) = driver_table_processed;
end
% Define the column indices for the pre-calculated masks
INLAP_COL = 15;    % IsInlap mask column
OUTLAP_COL = 16;   % IsOutlap mask column
CLEAR_STATUS_COL = 17; % IsClearTrack (Status '1' inclusive) mask column
for i = 1:number_drivers
    current_driver_name = drivers_names{i};
    current_data_table = driver_data_struct.(current_driver_name); % Access the table once
    % 1. Extract the raw logical content using curly braces {:, index}
    in_lap = current_data_table{:, INLAP_COL};
    out_lap = current_data_table{:, OUTLAP_COL};
    clear_status = current_data_table{:, CLEAR_STATUS_COL};
    % 2. Calculate the Final Clear Lap Mask
    % Clear Lap = (Clear Status is TRUE) AND (NOT In-Lap) AND (NOT Out-Lap)
    clear_laps_mask = clear_status & ~in_lap & ~out_lap;
    % 3. Store the result back into the driver's data table
    % Convert the logical array to a single-column table
    clear_laps_table = table(clear_laps_mask, 'VariableNames', {'IsClearLap'});
    % Horizontally concatenate the new table column
    current_data_table = [current_data_table, clear_laps_table];
    % 4. Update the structure field
    driver_data_struct.(current_driver_name) = current_data_table;
end

%% Filter Laptimes 108%
% not 107%, not to lose high fuel runs
% Define column indices/names for required data
LAP_TIMES_COL = 11;
IS_CLEAR_LAP_COL_NAME = 'IsClearLap'; % The name of the final combined mask (Col 17)
for i = 1:number_drivers
    current_driver_name = drivers_names{i};
    current_data_table = driver_data_struct.(current_driver_name); % Access the table
    % 1. Extract necessary data (Lap Times and Clear Lap Mask)
    lap_times = current_data_table{:, LAP_TIMES_COL};
    is_clear_lap_mask = current_data_table{:, IS_CLEAR_LAP_COL_NAME};
    % 2. Calculate the 107% Threshold
    % Find the fastest time ONLY from the laps that were marked as clear.
    clear_lap_times = lap_times(is_clear_lap_mask);
    % Handle case where no clear laps exist
    if isempty(clear_lap_times)
        fastest_clear_lap = NaN;
    else
        % Find the absolute minimum time among clear laps
        fastest_clear_lap = min(clear_lap_times);   
    end

    lap_108_limit = fastest_clear_lap * 1.08;
    % 3. Create the Final Validity Mask (Vectorized)
    % Mask A: Lap time must be less than or equal to the 107% limit.
    is_faster_than_limit = (lap_times <= lap_108_limit);
    % Mask B: The lap must also be a clear lap (no pit stops/cautions).
    % The final valid lap must meet BOTH conditions.
    is_valid_lap_mask = is_faster_than_limit & is_clear_lap_mask;
    % 4. Store the result back into the driver's data table
    % Convert the logical array to a single-column table
    valid_laps_table = table(is_valid_lap_mask, 'VariableNames', {'IsValidLap'});
    % Horizontally concatenate the new table column
    current_data_table = [current_data_table, valid_laps_table];
    % 5. Update the structure field
    driver_data_struct.(current_driver_name) = current_data_table;
end

%% 3. VALID-CLEAR LAPS DATA FILTERING
% Column index for the IsValidLap mask
VALID_COL = 19;
% Create a new struct to hold the filtered data (recommended)
filtered_driver_data_struct = struct();
for i = 1:number_drivers
    current_driver_name = drivers_names{i};
    current_data_table = driver_data_struct.(current_driver_name); % Access the table
    % 1. Extract the raw logical mask from the table column
    % Use curly braces {:, VALID_COL} to extract the TRUE/FALSE data contents.
    valid_lap_mask = current_data_table{:, VALID_COL};
    % 2. Apply the mask to the table
    % Use table indexing (parentheses) with the logical mask to select only TRUE rows.
    % This keeps all columns but only the rows where the mask is TRUE.
    valid_data_table = current_data_table(valid_lap_mask, :);
    % 3. Store the result in a new struct field
    filtered_driver_data_struct.(current_driver_name) = valid_data_table;
end

%% PACE ANALYSIS
% 1. SPLIT STINTS
% Define the column index for the Stint ID
STINT_ID_COL = 5;
TYRE_COMPOUND_COL = 4;
% Initialize the new structure to store all stint data
driver_stint_data = struct();
for i = 1:number_drivers
    current_driver_name = drivers_names{i};
    % Access the filtered valid lap data table
    current_data_table = filtered_driver_data_struct.(current_driver_name);
    % 1. Extract Stint IDs and create the array for filtering
    stint_ids_array = current_data_table{:, STINT_ID_COL};
    % Get the unique IDs to loop through (ensures we only process existing stints)
    unique_stints = unique(stint_ids_array);
    % 2. Initialize a substructure for the current driver's stints
    % This ensures the main struct is populated for every driver, even if they have no data.
    driver_stint_data.(current_driver_name) = struct();
    % 3. Loop Through Each Unique Stint ID
    for j = unique_stints' % Use transpose ' for safe iteration
        % Create the logical mask for the current stint
        stint_mask = (stint_ids_array == j);
        % Apply the mask to the table to select only the rows for the current stint
        stint_data_table = current_data_table(stint_mask, :);
        % 4. Save the stint data using dynamic field naming
        % Example field name: .NORRIS.Stint_1, .NORRIS.Stint_2
        stint_field_name = ['Stint_', num2str(j)];
        % 1. Extract the raw data (string/char array) from the first row, Column 4.
        % The use of {1, TYRE_COMPOUND_COL} extracts the content, not a 1x1 table.
        tyre_data_content = stint_data_table{1, TYRE_COMPOUND_COL};
        % 2. Convert the content (which might be a cell or string) to a standard char array.
        % If it's already a char array, this does nothing. If it's a string, it converts it.
        stint_tyre = char(tyre_data_content);
        driver_stint_data.(current_driver_name).(stint_field_name) = stint_data_table;
       % fprintf('Saved Stint %d data for %s. Laps: %d Tyre: %s\n', j, current_driver_name, size(stint_data_table, 1), stint_tyre);
    end
end
    disp('====================================')
    disp('STINTS ANALYSIS')
    disp('====================================')

% Column index for Tyre Life (already defined globally as 7)
TYRE_LIFE_COL = 7; 
% Column index for Stint ID (already defined globally as 5)
STINT_ID_COL = 5;

% 2. STINT ANALYSIS
for i = 1:number_drivers
    current_driver_name = drivers_names{i};
    % Access the filtered valid lap data table
    stints_table = driver_stint_data.(current_driver_name);
    
    %  Retrieve UNFILTERED data for full stint range lookup
    unfiltered_data_table = driver_data_struct.(current_driver_name);
    
    field_names = fieldnames(stints_table);
    number_of_tables = length(field_names);
    no_stints = number_of_tables;
    
    for j = 1:no_stints
       % 1. Access the filtered data for performance metrics
        current_stint_field_name = field_names{j};
        current_stint_data_table = stints_table.(current_stint_field_name);
        
        % Calculate performance metrics from filtered data
        stint_laps = height(current_stint_data_table);
        mean_stint_time = table2array(mean(current_stint_data_table(:,11)));
        fastest_stint_lap = table2array(min(current_stint_data_table(:,11)));
        mean_time = convertTime(mean_stint_time);
        fastest_time = convertTime(fastest_stint_lap);
        fastest_sector1 = table2array(min(current_stint_data_table(:,8)));
        fastest_sector2 = table2array(min(current_stint_data_table(:,9)));
        fastest_sector3 = table2array(min(current_stint_data_table(:,10)));
        optimal_stint_lap = fastest_sector1 + fastest_sector2 + fastest_sector3;
        fastest_sector1_disp = convertTime(fastest_sector1);
        fastest_sector2_disp = convertTime(fastest_sector2);
        fastest_sector3_disp = convertTime(fastest_sector3);
        optimal_stint_lap_disp = convertTime(optimal_stint_lap);
        
        % Stint Compound & Tyre Life from filtered data (as before)
        stint_tyre_start_life = table2array(current_stint_data_table(1,TYRE_LIFE_COL));
        tyre_life_comp = table2array(current_stint_data_table(end,TYRE_LIFE_COL));
        tyre = table2cell(current_stint_data_table(1,4));
        tyre = char(tyre);
        
        %  NEW: CALCULATE FULL TYRE LIFE RANGE FROM UNFILTERED DATA
        % Filter the UNFILTERED data for the current Stint ID (j)
        unfiltered_stint_data = unfiltered_data_table(unfiltered_data_table{:, STINT_ID_COL} == j, :);
        
        % Extract the Tyre Life of the first lap (out-lap)
        full_stint_start_life = table2array(unfiltered_stint_data(1, TYRE_LIFE_COL));
        % Extract the Tyre Life of the last lap (in-lap)
        full_stint_end_life = table2array(unfiltered_stint_data(end, TYRE_LIFE_COL));
        % Calculate total laps of each stint
        total_stint_laps = (full_stint_end_life + 1) - full_stint_start_life;

        % Format the new output string
        tyre_life_range_display = sprintf('%d-%d Laps', full_stint_start_life, full_stint_end_life);
        
        disp('------------------------------------')
        fprintf('Driver: %s \n Stint no %d - Compound: %s \n Total Stint Laps: %d Laps \n Tyre age: %s  \n Clean Laps: %d \n Stint- Start Tyre Life (Clean Laps): %d Laps \n Tyre Life up to competitive laps: %d Laps \n Average Lap Time: %s \n Fastest Lap: %s \n Fastest S1: %s \n Fastest S2: %s \n Fastest S3: %s \n Optimal Lap Time: %s \n',...
            current_driver_name, j, tyre,  total_stint_laps, tyre_life_range_display, stint_laps, stint_tyre_start_life ,tyre_life_comp, mean_time, fastest_time, fastest_sector1_disp, fastest_sector2_disp, fastest_sector3_disp, optimal_stint_lap_disp )
    end
end

%% GRAPHS
% --- GLOBAL SETUP ---
% Tire Color Configuration (Remains the same)
TireData = table(...
    {'SOFT'; 'MEDIUM'; 'HARD' ; 'INTERMEDIATE'; 'FULL WET'}, ...
    {[1.0 0.0 0.0]; [1.0 1.0 0.0]; [0.4 0.4 0.4]; [0.0 0.5 0.0]; [0.0 0.0 1.0]}, ...
    'VariableNames', {'Compound', 'ColorName'});
% Define colors for specific teams/drivers (Remains the same)
DriverColorMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
DriverColorMap('VER') = [0.0 0.0 1.0];
DriverColorMap('PEREZ') = [0.0 0.0 0.5];
DriverColorMap('LECLERC') = [1.0 0.0 0.0];
DriverColorMap('ARTHUR') = [0.65 0.0 0.0];
DriverColorMap('NOR') = [0.65 0.65 0.0];
DriverColorMap('PIA') = [0.5 0.0 0.0];
DEFAULT_COLOR = [0.5 0.5 0.5];
% Define constants
TYRE_LIFE_COL = 7;
LAP_TIME_COL = 11;
COMPOUND_COL = 4;
LAP_NUMBER_COL = 1; % Column 1 in the original DATA table (before processing)
% Figure 1: All VALID Stints Pace 
figure('Renderer','painters', 'Position', [100 100 1200 550])
title('Drivers Pace: All VALID Stints')
subtitle(RACE_TITLE)
xlabel('Tyre Life (Laps)')
ylabel('Lap Time (seconds)')
grid on
hold on
% INITIALIZE ARRAYS FOR LEGEND (MOST ROBUST WAY)
legend_handles = gobjects(0); % Explicitly initialize as an empty graphics object array
legend_strings = {};     % Initialize as an empty cell array
% ------------------------------------------------------

last_point_x = containers.Map('KeyType', 'char', 'ValueType', 'double');
last_point_y = containers.Map('KeyType', 'char', 'ValueType', 'double');

for i = 1:number_drivers
    current_driver_name = drivers_names{i};
    stints_table_struct = driver_stint_data.(current_driver_name);
    field_names = fieldnames(stints_table_struct);
     %  Determine the line color for the current driver
    if isKey(DriverColorMap, current_driver_name)
        driver_line_color = DriverColorMap(current_driver_name);
    else
        driver_line_color = DEFAULT_COLOR;
    end
    for j = 1:length(field_names)
        current_stint_field_name = field_names{j};
        current_stint_data_table = stints_table_struct.(current_stint_field_name);
     
        if isempty(current_stint_data_table)
            continue;
        end
        % ------------------------------------------
        % 1. Extract Compound String
        current_compound_cell = current_stint_data_table{1, COMPOUND_COL};
        current_compound_str = char(current_compound_cell);
        % 2. Get Stint Marker Color (Tire Color)
        stint_marker_color = getCompoundColor(current_compound_str, TireData); % Assumes this function is defined
        % 3. Extract X (Tyre Life) and Y (Lap Time) data
        x = table2array(current_stint_data_table(:, TYRE_LIFE_COL));
        y = table2array(current_stint_data_table(:, LAP_TIME_COL));
       
        num_laps = length(x);
        % Ensure index is within bounds: at least 1, max is the last element
        label_index = max(1, floor(num_laps * 0.5)); 
        if label_index > num_laps
            label_index = num_laps; 
        end
        % 4. Plot the data
        h = plot(x, y, ...
                 'Color', driver_line_color, ... 
                 'Marker', 'o', ...
                 'MarkerSize', 2,...
                 'MarkerFaceColor', stint_marker_color, ...
                 'MarkerEdgeColor', stint_marker_color, ...
                 'LineStyle', '-', ...
                 'LineWidth', 1.5);
        % 5. Create the dynamic label string for the text function
      
        stint_number_array = sscanf(current_stint_field_name, 'Stint_%d');
        if isempty(stint_number_array)
            % Fallback, though ideally sscanf works.
            stint_number = j;
        else
            stint_number = stint_number_array(1);
        end
        % Use a concise label for the graph text
        graph_label = sprintf('%s S%d %s', ...
                               current_driver_name, ...
                               stint_number, ...
                               current_compound_str);
        % 6. Place the text label on the line
        text(x(label_index), ...
             y(label_index), ...       
             graph_label, ...                     
             'Color', driver_line_color, ...       
             'FontWeight', 'bold', ...
             'FontSize', 8);
        legend_entry = sprintf('%s - Stint %d: %s', ...
                               current_driver_name, ...
                               stint_number, ...
                               current_compound_str);
        % 7. Store the handle and the string
        % Append the handle to the gobjects array (only if it's new/unique, which for this figure, is every time)
        legend_handles(end+1) = h;
        legend_strings{end+1} = legend_entry;
        % 8. Update the last point tracking for the driver name label
        last_point_x(current_driver_name) = x(end);
        last_point_y(current_driver_name) = y(end);
    end
end
% Plot the Driver Names at the End of their Final Stint
driver_names_cell = keys(last_point_x);
for k = 1:length(driver_names_cell)
    driver = driver_names_cell{k};
    % Get the driver's color for the text
    if isKey(DriverColorMap, driver)
        text_color = DriverColorMap(driver);
    else
        text_color = DEFAULT_COLOR;
    end
    text(last_point_x(driver) + 0.5, ... % X position: Last point + small offset
         last_point_y(driver), ...       % Y position: Last point
         driver, ...                      % The text to display
         'Color', text_color, ...        % Use the driver's line color
         'FontWeight', 'bold', ...
         'FontSize', 10);
end
% -------------------------------------------------------------------
% Only attempt to call legend if any data was actually plotted
if ~isempty(legend_handles)
    % Remove duplicate entries (MATLAB will automatically handle plotting the same line)
    [~, unique_indices] = unique(legend_strings);
    legend(legend_handles(unique_indices), legend_strings(unique_indices), 'Location', 'bestoutside', 'FontSize', 11);
end
hold off
% -------------------------------------------------------------------
% FIGURES FOR INDIVIDUAL COMPOUNDS (VALID LAPS) 
% -------------------------------------------------------------------
% Store all plotting configuration into a cell array for easy looping
CompoundPlots = {
    {'SOFT', 'Drivers Pace: SOFT Tyre Stints (Valid Laps Only)', [100 100 1200 550], [1.0 0.0 0.0]}
    {'MEDIUM', 'Drivers Pace: MEDIUM Tyre Stints (Valid Laps Only)', [100 100 1200 550], [1.0 1.0 0.0]}
    {'HARD', 'Drivers Pace: HARD Tyre Stints (Valid Laps Only)', [100 100 1200 550], [0.4 0.4 0.4]}
};
for k = 1:length(CompoundPlots)
    TARGET_COMPOUND = CompoundPlots{k}{1};
    FIGURE_TITLE = CompoundPlots{k}{2};
    FIGURE_POS = CompoundPlots{k}{3};
    TARGET_MARKER_COLOR = CompoundPlots{k}{4};
    figure('Renderer','painters', 'Position', FIGURE_POS)
    title(FIGURE_TITLE)
    subtitle(RACE_TITLE)
    xlabel('Tyre Life (Laps)')
    ylabel('Lap Time (seconds)')
    grid on
    hold on
    compound_legend_handles = gobjects(0);
    compound_legend_strings = {};
    for i = 1:number_drivers
        current_driver_name = drivers_names{i};
        stints_table_struct = driver_stint_data.(current_driver_name);
        field_names = fieldnames(stints_table_struct);

         % --- Retrieve UNFILTERED data for full stint range lookup ---
        unfiltered_data_table = driver_data_struct.(current_driver_name);

        % Determine the line color for the current driver
        if isKey(DriverColorMap, current_driver_name)
            driver_line_color = DriverColorMap(current_driver_name);
        else
            driver_line_color = DEFAULT_COLOR;
        end
        for j = 1:length(field_names)
            current_stint_field_name = field_names{j};
            current_stint_data_table = stints_table_struct.(current_stint_field_name);
             % --- CRITICAL FIX 1: CHECK FOR EMPTY DATA ---
            if isempty(current_stint_data_table)
                continue;
            end
            % 1. Extract Compound String and Filter
            current_compound_cell = current_stint_data_table{1, COMPOUND_COL};
            current_compound_str = char(current_compound_cell);
            if ~strcmp(current_compound_str, TARGET_COMPOUND)
                continue; % Skip this stint if it's not the target compound
            end
            % 2. Extract X (Tyre Life) and Y (Lap Time) data
            x = table2array(current_stint_data_table(:, TYRE_LIFE_COL));
            y = table2array(current_stint_data_table(:, LAP_TIME_COL));
            % --- FIX 2: Robust Label Index Calculation ---
            num_laps = length(x);
            label_index = max(1, floor(num_laps * 0.5)); 
            if label_index > num_laps
                label_index = num_laps; 
            end
            % 3. Plot the data
            h = plot(x, y, ...
                     'Color', driver_line_color, ...
                     'Marker', 'o', ...
                     'MarkerFaceColor', TARGET_MARKER_COLOR, ... % Use the target color for the marker
                     'MarkerEdgeColor', TARGET_MARKER_COLOR, ...
                     'MarkerSize', 2,...
                     'LineStyle', '-', ...
                     'LineWidth', 1.5);
            stint_number_array = sscanf(current_stint_field_name, 'Stint_%d');
            if isempty(stint_number_array)
                stint_number = j;
            else
                stint_number = stint_number_array(1);
            end
            % We only need Driver Name and Stint Number, as the compound is in the title.
            graph_label = sprintf('%s S%d', current_driver_name, stint_number); 
            
            % 5. Place the text label on the line
            text(x(label_index), ...
                 y(label_index), ...
                 graph_label, ...
                 'Color', driver_line_color, ...
                 'FontWeight', 'bold', ...
                 'FontSize', 8);
            % 6. Store the handle and the string for the legend (Legend still shows only Driver Name)
            legend_entry = current_driver_name;
            if ~ismember(legend_entry, compound_legend_strings)
                compound_legend_handles(end+1) = h;
                compound_legend_strings{end+1} = legend_entry;
            end
        end
    end
    if ~isempty(compound_legend_handles)
        legend(compound_legend_handles, compound_legend_strings, 'Location', 'bestoutside', 'FontSize', 11);
    end
    hold off
end
% -------------------------------------------------------------------
disp('-------------------------------------')



%% FIGURES FOR ALL LAPS PER DRIVER 📊
% New analysis function to group *all* laps into stints based on tire change

stint_column = 5;
driver_all_laps_stints_data = splitAllLapsIntoStints(driver_data_struct, drivers_names, stint_column);
for i = 1:number_drivers
    current_driver_name = drivers_names{i};

    % Access the all-laps stint data for the current driver
    all_laps_stints_table_struct = driver_all_laps_stints_data.(current_driver_name);
    field_names = fieldnames(all_laps_stints_table_struct);


    % 1. Figure Setup (One per driver)
    figure('Renderer','painters', 'Position', [100 + (i-1)*50 100 1000 500])
    title(sprintf('ALL Laps Pace: %s', current_driver_name))
    subtitle(RACE_TITLE)
    xlabel('Tyre Age (Laps)') 
    ylabel('Lap Time (seconds)')
    grid on
    hold on

    all_laps_legend_handles = gobjects(0);
    all_laps_legend_strings = {};

    % 2. Plotting Each Stint
    for j = 1:length(field_names)
    current_stint_field_name = field_names{j};
    current_stint_data_table = all_laps_stints_table_struct.(current_stint_field_name);

    if isempty(current_stint_data_table)
        continue;
    end
% --------------------------------------------

% Extract Compound, Lap Number, and Lap Time
current_compound_cell = current_stint_data_table{1, COMPOUND_COL};
current_compound_str = char(current_compound_cell);
        if isempty(current_compound_str)
            fprintf('WARNING: Skipping Stint %d for %s due to empty compound string.\n', j, current_driver_name);
            continue;
        end
% -------------------------------------------------------------
% Get Compound Color for LINE AND MARKER
stint_compound_color = getCompoundColor(current_compound_str, TireData);

% CRITICAL CHANGE: X-axis: Tyre Life (TYRE_LIFE_COL)
x = table2array(current_stint_data_table(:, TYRE_LIFE_COL)); 
% Y-axis: Lap Time (Column 11 of original data)
y = table2array(current_stint_data_table(:, 11));

% Plot the data
h = plot(x, y, ...
'Color', stint_compound_color, ... 
'Marker', '.', ...
'MarkerFaceColor', stint_compound_color, ... 
'MarkerEdgeColor', stint_compound_color, ... 
'LineStyle', '-', ... 
'LineWidth', 1.0);

stint_number = j;

% Calculate text position (using Tyre Age as X-axis)
num_laps_stint = length(x);
label_index = max(1, floor(num_laps_stint * 0.5));
text_x_pos = x(label_index);
min_y = min(y);
% Ensure text position is valid (not NaN or Inf)
        if isnan(min_y) || isempty(min_y)
            % Cannot place text if no valid lap times exist in the stint (e.g., all were NaN out/in laps)
            fprintf('WARNING: Skipping label for Stint %d for %s due to NaN lap times.\n', j, current_driver_name);
            continue; 
           
        end
text_y_pos = min_y - 0.05;

% Extract the Tyre Age range directly from the plotted X-axis data (x)
        % Check for valid age range before assigning and labeling
        if isempty(x)
            continue; 
        end

 % Extract the Tyre Age range directly from the plotted X-axis data (x)
% This corresponds to the 'full_stint_start_life' and 'full_stint_end_life' from  analysis
stint_start_age = x(1);
stint_end_age = x(end);

% Label: Stint #, Compound, and the CORRECT Tyre Age range
graph_label = sprintf('S%d: %s (Age %d-%d)', stint_number, current_compound_str, stint_start_age, stint_end_age);

text(text_x_pos, ...
text_y_pos, ...
graph_label, ...
'Color', stint_compound_color * 0.8, ... 
'FontWeight', 'bold', ...
'FontSize', 8, ...
'VerticalAlignment', 'top', ... 
'HorizontalAlignment', 'center');

% Add legend entry for this compound if it's new for the driver
legend_entry = sprintf('Stint %d: %s', stint_number, current_compound_str);
if ~ismember(legend_entry, all_laps_legend_strings)
all_laps_legend_handles(end+1) = h;
all_laps_legend_strings{end+1} = legend_entry;
end
end

% Finalize Figure
if ~isempty(all_laps_legend_handles)
legend(all_laps_legend_handles, all_laps_legend_strings, 'Location', 'bestoutside', 'FontSize', 9);
end
hold off
end









%% FUNCTIONS
function data_table = processAllDriverData(data_table, pitstop_source_col, track_status_source_col)
% Processes a single driver's data table to add IsPitstop, IsInlap, IsOutlap, and IsClearTrack columns.
%
% Inputs:
%   data_table (table): The driver's data table.
%   pitstop_source_col (double): Column index for the raw Pitstop/Status indicator (e.g., 6).
%   track_status_source_col (double): Column index for the Track Status code (e.g., 12).
%
% Output:
%   data_table (table): The updated table with all new columns.
    % --- 1. Standardize Pitstop Indicator ---
    new_pitstop_col_name = 'IsPitstop';
    raw_data = data_table{:, pitstop_source_col};
    if iscell(raw_data)
        is_pitstop_logical = strcmp(raw_data, 'TRUE');
    elseif isnumeric(raw_data)
        is_pitstop_logical = logical(raw_data);
    else
        is_pitstop_logical = logical(raw_data);
    end
    data_table = [data_table, table(is_pitstop_logical, 'VariableNames', {new_pitstop_col_name})];
    % --- 2. Calculate In-laps & Out-laps ---
    % The Pitstop mask is now the last column we just added
    is_pitstop = data_table.IsPitstop;
    num_laps = size(is_pitstop, 1);
    % Out-lap Mask (Lap *during* the pit stop event)
    is_outlap_mask = is_pitstop;
    % In-lap Mask (Lap *immediately before* the pit stop)
    is_inlap_mask = [is_pitstop(2:end); false];
    if length(is_inlap_mask) ~= num_laps
        is_inlap_mask = is_inlap_mask(1:num_laps);
    end
    % Convert and concatenate the new columns
    inlap_table = table(is_inlap_mask, 'VariableNames', {'IsInlap'});
    outlap_table = table(is_outlap_mask, 'VariableNames', {'IsOutlap'});
    data_table = [data_table, inlap_table, outlap_table];
    % --- 3. Calculate Clear Track Mask (Inclusive Filtering) ---
    CLEAR_CODE = "1";
    EXCLUDE_CODES = "4"; % Exclude Safety Car ('4')
    raw_status_data = data_table{:, track_status_source_col};
    status_str = string(raw_status_data);
    % Mask A: Must contain the Clear Code "1"
    has_clear_code = contains(status_str, CLEAR_CODE);
    % Mask B: Must NOT contain the Safety Car Code "4"
    is_not_compromised = ~contains(status_str, EXCLUDE_CODES);
    % Final Clear Track Mask (includes 12/21, excludes 4)
    track_clear_mask = has_clear_code & is_not_compromised;
    % Convert and concatenate the new column
    clear_track_table = table(track_clear_mask, 'VariableNames', {'IsClearTrack'});
    data_table = [data_table, clear_track_table];
end

function all_laps_stint_data = splitAllLapsIntoStints(driver_data_struct, drivers_names, tyre_compound_col)
% Splits all laps for each driver into stints based only on a change in the tire compound.
% This ignores the validity/clearance filters.
    number_drivers = length(drivers_names);
    all_laps_stint_data = struct();
    
    for i = 1:number_drivers
        current_driver_name = drivers_names{i};
        % Access the UNFILTERED data table (contains all laps)
        current_data_table = driver_data_struct.(current_driver_name);
        
        % Extract the compound column and convert to string array for easy comparison
        compound_raw = current_data_table{:, tyre_compound_col};
        compound_str = string(compound_raw);
        
        % Find where the compound changes (stint start)
        % logical vector: TRUE where compound changes from previous lap
        stint_change_mask = [true; compound_str(2:end) ~= compound_str(1:end-1)];
        
        % Determine Stint IDs (1, 1, 2, 2, 2, 3, 3, ...)
        stint_ids = cumsum(stint_change_mask);
        
        % Initialize substructure for the current driver's stints
        all_laps_stint_data.(current_driver_name) = struct();
        
        % Get unique stint IDs
        unique_stints = unique(stint_ids);
        
        for j = unique_stints'
            % Create the logical mask for the current stint ID
            stint_mask = (stint_ids == j);
            
            % Select all data for this stint
            stint_data_table = current_data_table(stint_mask, :);
            
            % Save the stint data
            stint_field_name = ['Stint_', num2str(j)];
            all_laps_stint_data.(current_driver_name).(stint_field_name) = stint_data_table;
        end
    end
end

function timing_string = convertTime(total_seconds)
% CONVERTTIME Converts a total time in seconds into a M:SS:MMM format string.
    m = floor(total_seconds / 60);
    remaining_seconds = total_seconds - (m * 60);
    s = floor(remaining_seconds);
    ms = round((remaining_seconds - s) * 1000); % Round to nearest millisecond
    timing_string = sprintf('%d:%02d:%03d', m, s, ms);
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