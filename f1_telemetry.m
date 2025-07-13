%% THANASIS CHARALAMBOUS
% ENGINEER
% 6/2025
%% 
clc
clear

%% PART 1: Insert Data

% Define the folder where all the CSVs are stored
dataFolder = 'C:\Users\User\Downloads\F1_archive';

% Get all .csv files in that folder
% dir lists files and folders in the current folder
% builds a full file specification from the specified folder and file names
files = dir(fullfile(dataFolder, '*.csv'));

% Initialize struct to store each dataset
f1data = struct();

% Loop through and load each file
for i = 1:length(files)
    fileName = files(i).name; % Get the name of the files
    fullPath = fullfile(dataFolder, fileName); % builds a full file specification from the specified folder and file names
    
    % Clean up the filename to use as a struct field
    fieldName = matlab.lang.makeValidName(erase(fileName, '.csv')); % Create table from file
    
    % Read the table
    f1data.(fieldName) = readtable(fullPath); % Create table from file
    
   % fprintf('Loaded: %s (%d rows)\n', fileName, height(f1data.(fieldName)));
end

disp('Part 1: SUCCESS RUN')

%% PART 2: Choose a race

races = f1data.races;

% Get all the races  of a specific year
races2024 = races(races.year==2024,:); % Change the year if you want a race from other year
disp('CHOOSE a race (raceId) for anlysis from below:')
disp(races2024(:,{'raceId', 'name', 'date'})) % Show the races of the season

% Choose the raceId of the wanted race for analysis
raceID = 1129; % Change the number for the wanted race
disp('Part 2: SUCCESS RUN')

%% PART 3: Extract and Analyze Data

laps = f1data.lap_times(f1data.lap_times.raceId == raceID,:);
pits = f1data.pit_stops(f1data.pit_stops.raceId == raceID,:);
results = f1data.results(f1data.results.raceId == raceID,:);
driversAll = f1data.drivers;
constructorsAll = f1data.constructors;

% Merge driver names into lap times, pitstops, results
laps = innerjoin(laps,driversAll,'LeftKeys','driverId','RightKeys','driverId');
pits = innerjoin(pits, driversAll, 'LeftKeys', 'driverId', 'RightKeys', 'driverId');
results = innerjoin(results, driversAll, 'LeftKeys', 'driverId', 'RightKeys', 'driverId');
results = innerjoin(results, constructorsAll,"LeftKeys","constructorId","RightKeys","constructorId");
drivers_race = f1data.results(f1data.results.raceId == raceID,:); % Merge drivers on the race results
drivers_race =innerjoin(driversAll, drivers_race,'LeftKeys','driverId','RightKeys','driverId');

% Show Drivers of the race
disp('Drivers Info:')
disp(drivers_race(:,{'driverId','forename','surname'}))
disp('Part 3: SUCCESS RUN')

%% PART 4: Plotting

% For 3 top finishers
top3Drivers = results(results.positionOrder <= 3,:);
top3Laps = laps(ismember(laps.driverId, top3Drivers.driverId),:);

% Plot
figure;
hold on;
legends = {};

for i = 1:height(top3Drivers);
    dID = top3Drivers.driverId(i);
    driverTag = top3Drivers.surname{i};
    legends{end+1} = driverTag;

    driverLaps = top3Laps(top3Laps.driverId == dID, :);
    plot(driverLaps.lap, driverLaps.milliseconds / 1000);
end

xlabel('Lap');
ylabel('Lap Time (s)');
title(['Lap Time Evolution – ', f1data.races.name{f1data.races.raceId == raceID}]);
legend(legends, 'Location', 'northeastoutside');
grid on

% Plot X for Pit Stop for each Driver
for i = 1:height(top3Drivers)
    dID = top3Drivers.driverId(i);
    driverTag = top3Drivers.driverRef{i};  % e.g., "HAM"
    driverPits = pits(pits.driverId == dID, :);

    for j = 1:height(driverPits)
        x = driverPits.lap(j);
        y = NaN;

        % Find corresponding lap time for plotting
        lapRow = top3Laps(top3Laps.driverId == dID & top3Laps.lap == x, :);
        if ~isempty(lapRow)
            y = lapRow.milliseconds / 1000;

            % Plot the pit stop marker
            plot(x, y, 'x', 'Color', 'k', 'MarkerSize', 8, 'LineWidth', 1.5, 'HandleVisibility', 'off');

            % Add pit stop label (e.g., "HAM Pit 1")
            driverShort = top3Drivers.code{i};
            text(x + 0.1, y, sprintf('%s Pit %d', driverShort, j), ...
                'FontSize', 8, 'Color', 'k', 'FontWeight', 'bold');
        end
    end
end

disp('Part 4: SUCCESS RUN')
disp('FULLY CODE: SUCCESS RUN')