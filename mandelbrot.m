function mandelbrot(varargin)
    programTimer = tic;
    %% Default parameters & input parsing
    defaultNumberOfFrames = 800;
    defaultWidth = 800;
    defaultHeight = defaultWidth;
    % Maximum number of iterations for checking convergence
    defaultMaxIterations = 500;
    % Live render or create video
    defaultCreateVideo = true;

    % Input validation
    % Parser setup
    p = inputParser;
    addParameter(p, 'numberOfFrames', defaultNumberOfFrames);
    addParameter(p, 'maxIterations', defaultMaxIterations);
    addParameter(p, 'createVideo', defaultCreateVideo);
    addParameter(p, 'width', defaultWidth);
    addParameter(p, 'height', defaultHeight);
    % Parse input
    parse(p, varargin{:});

    % Parameters
    numberOfFrames = p.Results.numberOfFrames;
    maxIterations = p.Results.maxIterations;
    createVideo = p.Results.createVideo;
    width = p.Results.width;
    height = p.Results.height;

    %% Initializing

    if(createVideo)
        v = VideoWriter("mandelbrot", "MPEG-4");
        open(v);
    end

    % FOR BENCHMARKING
    fps = zeros(numberOfFrames,1);
    
    % Initial range of real and imaginary parts
    realRange = gpuArray([-2 2]);
    imagRange = gpuArray([-2 2]);

    % SSAA parameters
    oversamplingFactor = 2;
    oversamplingWidth = oversamplingFactor * width;
    oversamplingHeight = oversamplingFactor * height;

    % Calculate the current grid
    % linspace(from, to, stepsize)
    realVals = gpuArray.linspace(single(realRange(1)), single(realRange(2)), oversamplingWidth);
    imagVals = gpuArray.linspace(single(imagRange(1)), single(imagRange(2)), oversamplingHeight);
    
    % Create the components of the cartesian plane
    [Re, Im] = meshgrid(realVals, imagVals);
    
    % Combine the two components to form the cartesian plane
    initialComplexPlane = gpuArray(complex(Re, Im));
    
    % Factor by which we reduce the range of data on each frame
    % Basically the speed of the zoom effect
    zoomFactor = 0.995;
    currentZoomLevel = 1;
     
    %% Choosing zoom Center point
    % The point on which we zoom in.
    % Feigenbaum Point
    % center = -1.40115 + 0i;
    % Elephant valley
    % center = 0.285 + 0.01i;
    % Seahorse valley
    center = -0.75 + 0.1i;
    % Nautilus
    % center = -0.21503361460851339 + 0.67999116792639069i;
    
    %% Main loop

    iterations = gpuArray.zeros(size(initialComplexPlane), 'single');
    if (~createVideo)
        fig = figure;
        fig.WindowState = 'maximized';
        h = imagesc(realRange, imagRange, iterations);
        % sky, hsv, turbo look pretty
        colormap("turbo")
    end
    for curFrame = 1:numberOfFrames
        fpsTimer = tic;
    
        % Subtracting the center from initalComplexPlane gives an origin
        % centered grid
        % Multiplying with currentZoomFactor does the zoom
        % Readding center translates the grid to be centered around the given
        % point
        complexPlane = center + (initialComplexPlane - center) * currentZoomLevel;
    
        % Calculating the iterations for each point
        % This decides whether a point is an element of the Mandelbrot set or
        % not
        iterations = arrayfun(@calculateIters, complexPlane, maxIterations);
    
        if(createVideo)
            iterations = imresize(iterations, [height width], 'bilinear');
            % Normalize iterations to a scale of 0-1
            iterations = iterations / maxIterations;
            
            % LAPLACE FILTER - REMOVES CHAOTIC DETAILS
            % iterations = gather(iterations);
            % iterations = single(iterations);
            % sigma = 0.1;
            % alpha = 4;
            % iterations = locallapfilt(iterations, sigma, alpha);
            % iterations = gpuArray(iterations);
            
            % Convert to rgb
            rgbFrame = ind2rgb(uint8(iterations * 255), turbo(256));
            
            sigma = 0.5;
            rgbFrame = imgaussfilt(rgbFrame, sigma);
            % Write frame to video
            % Note: when using 'Archival' or 'Motion JPEG 2000' video profile convert to uint8
            writeVideo(v, gather(rgbFrame));

            % Display progress bar and timer
            progressBar(1) = '[';
            progressBar(11) = ']';
            progressBar(2:floor(curFrame/numberOfFrames*10)) = "=";
            progressBar(ceil(curFrame/numberOfFrames*10)+1:10) = ".";
            disp(progressBar);
            disp([num2str(toc(programTimer)) 's elapsed']);
        else
            % Display the image
            set(h, 'CData', gather(iterations));
            drawnow;
        end
    
        % Dynamically updating the zoom factor
        currentZoomLevel = currentZoomLevel * zoomFactor;

        fps(curFrame) = 1/toc(fpsTimer);
    end
    disp(mean(fps));
    % Notification
    if(createVideo)
        beep;
    end
end

%% Iteration function
function iterations = calculateIters(c, maxIterations)
    z = c;
    iterations = 0;
    while real(z)^2 + imag(z)^2 <= 4 && iterations < maxIterations
        z = z^2 + c;
        iterations = iterations + 1;
    end
end