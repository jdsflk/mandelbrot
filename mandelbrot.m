% Initial range of real and imaginary parts
realRange = [-2 2];
imagRange = [-2 2];

% The number of calculated points. There's no significant difference
% between 1000 and 10000;
resolution = 250;

% Maximum number of iterations for checking convergence
maxIterations = 1000;

% We consider the sequence to be bounded if it's elements are less then
% this value
maxVal = 2;

% Factor by which we reduce the range of data on each frame
% Basically the speed of the zoom effect
zoomFactor = 0.98;

% The point on which we zoom in.
% Point near origin
% center = -0.75 + 0i;
% Spiral region
% center = -0.01015 + 0.633i;
% Feigenbaum Point
%center = -1.40115 + 0i;
% Elephant valley
% center = 0.285 + 0.01i;
% Seahorse valley
center = -0.75 + 0.1i;


% Start a parallel pool with the maximum available thread workers
try
    parpool('Threads', maxNumCompThreads);
catch e
    disp('Threads already running')
end

% Opens a figure
fig = figure;
fig.WindowState = 'maximized';

while isvalid(fig)
    % Calculate the current grid
    % linspace(from, to, stepsize)
    tic;
    realVals = linspace(realRange(1), realRange(2), resolution);
    imagVals = linspace(imagRange(1), imagRange(2), resolution);

    % Create the components of the cartesian plane
    [Re, Im] = meshgrid(realVals, imagVals);

    % Combine the two components to form the cartesian plane
    complexPlane = Re + 1i * Im;

    % Preallocating the matrix for better efficiency
    iterations = zeros(size(complexPlane));

    % Calculating the iterations for each point
    % This decides whether a point is an element of the Mandelbrot set or
    % not
    % numel returns 1D size of matrix
    parfor index = 1:numel(complexPlane)
        iterations(index) = test_bounded(complexPlane(index), maxIterations, maxVal);
    end
    %iterations = arrayfun(@(x) test_bounded(x, maxIterations, maxVal), complexPlane);

    % Display the image
    imagesc(realRange, imagRange, iterations);
    colormap("turbo");
    
    % Update the figure
    drawnow;

    % Calculate the range for the next frame
    % The new size is the previous size * zoom
    % The range is calculated by adding and subtracting half of the size to
    % the center point
    rangeWidth = (realRange(2) - realRange(1)) * zoomFactor;
    rangeHeight = (imagRange(2) - imagRange(1)) * zoomFactor;
    realRange = [real(center) - rangeWidth/2, real(center) + rangeWidth/2];
    imagRange = [imag(center) - rangeHeight/2, imag(center) + rangeHeight/2];

    % Zoom speed 60fps -> 0.016
    %pause(0.02);
    toc;
end

% Close parallel pool
p = gcp;
delete(p);

% Checks if the series z^2 + c is bounded, with c as input, starting from 
% z = 0
function [y] = test_bounded(c, maxIterations, maxVal)
    prevVal = 0;
    for i = 0:1:maxIterations
        currentVal = prevVal^2 + c;
        if (abs(currentVal) > maxVal)
            break;
        end
        prevVal = currentVal;
    end
    y = i;
end