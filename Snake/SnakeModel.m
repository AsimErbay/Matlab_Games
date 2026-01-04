
classdef SnakeModel < handle

    
    properties (Access = private)
        nRows
        nCols
        snake      
        dir        % [dRow dCol], örn: [0 1] sağ
        food       % [row col]
        alive
        score
        wrapWalls  
    end
    
    methods
        function obj = SnakeModel(gridSize, wrapWalls)
            if nargin < 1, gridSize = [20 20]; end
            if nargin < 2, wrapWalls = false; end
            assert(numel(gridSize)==2 && all(gridSize>=5), 'gridSize en az [5 5] olmalı.');
            obj.nRows = gridSize(1);
            obj.nCols = gridSize(2);
            obj.wrapWalls = wrapWalls;
            obj.reset();
        end
        
        function reset(obj)
            % Başlangıç: ortada, sağa bakan, uzunluk 3
            r = round(obj.nRows/2);
            c = round(obj.nCols/2);
            obj.snake = [r c; r c-1; r c-2];
            obj.dir   = [0 1]; % sağ
            obj.alive = true;
            obj.score = 0;
            obj.placeFood();
        end
        
        function alive = isAlive(obj), alive = obj.alive; end
        function s = getScore(obj), s = obj.score; end
        function fs = getFood(obj), fs = obj.food; end
        function sn = getSnake(obj), sn = obj.snake; end
        function gs = getGridSize(obj), gs = [obj.nRows obj.nCols]; end
        
        function changeDirection(obj, newDir)
            % newDir: 'up','down','left','right'
            if ~obj.alive, return; end
            d = obj.dir;
            switch newDir
                case 'up',    nd = [-1 0];
                case 'down',  nd = [ 1 0];
                case 'left',  nd = [ 0 -1];
                case 'right', nd = [ 0  1];
                otherwise, return;
            end
            % Tersine dönmeyi engelle
            if size(obj.snake,1) > 1
                if all(nd == -d)
                    return;
                end
            end
            obj.dir = nd;
        end
        
        function event = step(obj)
            event = struct('ateFood',false,'gameOver',false);
            if ~obj.alive, event.gameOver = true; return; end
            
            head = obj.snake(1,:);
            next = head + obj.dir;
            
            if obj.wrapWalls
                if next(1) < 1, next(1) = obj.nRows; end
                if next(1) > obj.nRows, next(1) = 1; end
                if next(2) < 1, next(2) = obj.nCols; end
                if next(2) > obj.nCols, next(2) = 1; end
            else
                if next(1) < 1 || next(1) > obj.nRows || next(2) < 1 || next(2) > obj.nCols
                    obj.alive = false; event.gameOver = true; return;
                end
            end
            
            body = obj.snake(1:end-1,:); 
            if any(all(bsxfun(@eq, body, next), 2))
                obj.alive = false; event.gameOver = true; return;
            end
            if next(1) == obj.food(1) && next(2) == obj.food(2)
                obj.snake = [next; obj.snake]; 
                obj.score = obj.score + 1;
                event.ateFood = true;
                obj.placeFood();
            else
                
                obj.snake = [next; obj.snake(1:end-1,:)];
            end
        end
        
        function G = getGrid(obj)
            % 0: boş, 1: head, 2: body, 3: food
            G = zeros(obj.nRows, obj.nCols);
            if ~isempty(obj.food)
                G(obj.food(1), obj.food(2)) = 3;
            end
            if ~isempty(obj.snake)
                G(obj.snake(2:end,1) + (obj.snake(2:end,2)-1)*obj.nRows) = 2;
                G(obj.snake(1,1) + (obj.snake(1,2)-1)*obj.nRows) = 1;
            end
        end
    end
    
    methods (Access = private)
        function placeFood(obj)
            occ = false(obj.nRows, obj.nCols);
            if ~isempty(obj.snake)
                idx = obj.snake(:,1) + (obj.snake(:,2)-1)*obj.nRows;
                occ(idx) = true;
            end
            emptyIdx = find(~occ);
            if isempty(emptyIdx)
                obj.alive = false;
                return;
            end
            k = emptyIdx(randi(numel(emptyIdx)));
            [r,c] = ind2sub([obj.nRows obj.nCols], k);
            obj.food = [r c];
        end
    end
end
