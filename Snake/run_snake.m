
function run_snake(gridRows, gridCols, fps, wrapWalls)
%RUN_SNAKE Snake oyununu başlatır.
%   run_snake()                 -> 20x20, 7 FPS, wrap=false
%   run_snake(25, 30)           -> 25x30, 7 FPS
%   run_snake(20, 20, 10)       -> 20x20, 10 FPS
%   run_snake(20, 20, 12, true) -> duvarlardan sarma açık

if nargin < 1, gridRows  = 20; end
if nargin < 2, gridCols  = 20; end
if nargin < 3, fps       = 7;  end
if nargin < 4, wrapWalls = false; end

SnakeGameApp([gridRows gridCols], fps, wrapWalls);
end
