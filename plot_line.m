clear

% Define the time steps
tid_list = [3831, 5108, 6385];

% Define markers and colors for each time step
markers = {'o', '^', 's'};  % Circle, triangle, square for time steps
colors = {'b', 'r', 'g'};   % Blue, red, green for time steps

% Create a single figure
figure, clf
hold on

% Set the spacing for markers (e.g., every 10th point)
marker_spacing = 10;  % Adjust this value as needed

% Loop over each time step
for i = 1:length(tid_list)
    tid = tid_list(i);
    marker = markers{i};    % Select marker for this time step
    color = colors{i};      % Select color for this time step
    
    % --- Read Serial Data ---
    file_ser = sprintf('T_x_y_%06d.dat', tid);
    data_ser = readmatrix(file_ser);
    a_ser = sortrows(data_ser, [2, 1]); % Sort by y, then x
    x_ser = unique(a_ser(:, 1));
    y_ser = unique(a_ser(:, 2));
    nx_ser = length(x_ser);
    ny_ser = length(y_ser);
    T_ser = reshape(a_ser(:, 3), [ny_ser, nx_ser]);
    
    % --- Read Parallel Data ---
    filePattern = sprintf('T_x_y_%06d_*.dat', tid);
    files = dir(filePattern);
    combinedData = [];
    for k = 1:length(files)
        filePath = fullfile(files(k).folder, files(k).name);
        rankData = readmatrix(filePath);
        combinedData = [combinedData; rankData];
    end
    
    % Remove duplicates by averaging T for each (x, y)
    [unique_xy, ~, ic] = unique(combinedData(:, 1:2), 'rows');
    T_mean = accumarray(ic, combinedData(:, 3), [], @mean);
    a_par = [unique_xy, T_mean];
    
    % Sort by y then x
    a_par = sortrows(a_par, [2, 1]);
    
    % Define grid dimensions
    x_par = unique(a_par(:, 1));
    y_par = unique(a_par(:, 2));
    nx_par = length(x_par);
    ny_par = length(y_par);
    
    % Verify the data matches the grid size
    if size(a_par, 1) ~= nx_par * ny_par
        error('Data does not form a complete grid: %d points found, %d expected.', ...
            size(a_par, 1), nx_par * ny_par);
    end
    
    % Reshape the temperature data
    T_par = reshape(a_par(:, 3), [ny_par, nx_par]);
    
    % --- Assume grids are identical ---
    x = x_ser; % Assuming x_ser == x_par
    y = y_ser; % Assuming y_ser == y_par
    
    % --- Interpolate at mid-y (y = 0.5) ---
    mid_y = 0.5;
    for j = 1:ny_ser-1
        if y(j) <= mid_y && y(j+1) >= mid_y
            j1 = j;
            j2 = j+1;
            break;
        end
    end
    w = (mid_y - y(j1)) / (y(j2) - y(j1));
    Tmid_ser = (1 - w) * T_ser(j1, :) + w * T_ser(j2, :);
    Tmid_par = (1 - w) * T_par(j1, :) + w * T_par(j2, :);
    
    % --- Define marker indices ---
    % Space out markers by selecting every 10th point
    marker_indices = 1:marker_spacing:length(x);
    
    % --- Plot Serial Data ---
    % Solid line with spaced markers
    plot(x, Tmid_ser, '-', 'Color', color, 'LineWidth', 2, ...
        'Marker', marker, 'MarkerIndices', marker_indices, 'MarkerSize', 6, ...
        'DisplayName', sprintf('Serial, t=%d', tid));
    
    % --- Plot Parallel Data ---
    % Dashed line with spaced markers
    plot(x, Tmid_par, '--', 'Color', color, 'LineWidth', 2, ...
        'Marker', marker, 'MarkerIndices', marker_indices, 'MarkerSize', 6, ...
        'DisplayName', sprintf('Parallel, t=%d', tid));
end

% Finalize the plot
hold off
xlabel('x')
ylabel('T')
title('Temperature Profiles along Mid-y for Different Time Steps')
legend('Location', 'best') % Display legend with all labels
xlim([-0.05 1.05])
set(gca, 'FontSize', 14)
print('line_midy_T_all', '-dpng') % Save the figure