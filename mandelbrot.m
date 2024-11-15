function mandelbrot(numberOfFrames, resolution, maxIterations)
    if ~exist('numberOfFrames', 'var')
        % How many frames do we want to render
        numberOfFrames = 800;
    end
    if ~exist('resolution', 'var')
        % The number of calculated points. There's no significant difference
        % between 1000 and 10000;
        resolution = 800;
    end
    if ~exist('maxIterations', 'var')
        % Maximum number of iterations for checking convergence
        maxIterations = 500;
    end
    % FOR BENCHMARKING

    fps = zeros(numberOfFrames,1);
    
    % Initial range of real and imaginary parts
    realRange = gpuArray([-2 2]);
    imagRange = gpuArray([-2 2]);
   
    % We consider the sequence to be bounded if it's elements are less then
    % this value
    maxValSquared = 4;
    
    % Factor by which we reduce the range of data on each frame
    % Basically the speed of the zoom effect
    zoomFactor = 0.99;
    currentZoomFactor = 1;
    
    % The point on which we zoom in.
    % Point near origin
    % center = -0.75 + 0i;
    % Spiral region
    % center = -0.01015 + 0.633i;
    % Feigenbaum Point
    % center = -1.40115 + 0i;
    % Elephant valley
    % center = 0.285 + 0.01i;
    % Seahorse valley
    %center = -0.75 + 0.1i;
    
    center = -0.21503361460851339 + 0.67999116792639069i;
    
    % Calculate the current grid
    % linspace(from, to, stepsize)
    realVals = gpuArray.linspace(realRange(1), single(realRange(2)), resolution);
    imagVals = gpuArray.linspace(imagRange(1), single(imagRange(2)), resolution);
    
    % Create the components of the cartesian plane
    [Re, Im] = meshgrid(realVals, imagVals);
    
    % Combine the two components to form the cartesian plane
    initialComplexPlane = gpuArray(complex(Re, Im));
    
    % Opens a figure
    fig = figure;
    fig.WindowState = 'maximized';
    % iterations(800,800) = gpuArray(single(eps*1i));
    %iterations = gpuArray.zeros([800,800], 'single');
    iterations = gpuArray.zeros(size(initialComplexPlane), 'single');
    h = imagesc(realRange, imagRange, iterations);
    colormap("turbo");
    %while isvalid(fig)
    for curFrame = 1:numberOfFrames
        tic;
    
        % Subtracting the center from initalComplexPlane gives an origin
        % centered grid
        % Multiplying with currentZoomFactor does the zoom
        % Readding center translates the grid to be centered around the given
        % point
        complexPlane = center + (initialComplexPlane - center) * currentZoomFactor;
    
        % Preallocating the matrix for better efficiency
        iterations = gpuArray.zeros(size(complexPlane), 'single');
    
        % Calculating the iterations for each point
        % This decides whether a point is an element of the Mandelbrot set or
        % not
        currentVal = complexPlane;
        for i = 0:1:maxIterations
            currentVal = currentVal.^2 + complexPlane;
            % Calculating the square of the absolute value is faster than abs()
            stillBounded = real(currentVal).^2 + imag(currentVal).^2 <= maxValSquared;
            iterations = iterations + stillBounded;
        end
    
        % Display the image
        set(h, 'CData', gather(iterations));
    
        % Update the figure
        drawnow;
    
        % Dynamically updating the zoom factor
        currentZoomFactor = currentZoomFactor * zoomFactor;
    
        % Zoom speed 60fps -> 0.016
        % pause(0.001); 
        fps(curFrame) = 1/toc;
    end
    disp(mean(fps));
end