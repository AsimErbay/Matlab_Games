
classdef Board < handle
    %BOARD Model of a 3x3 TicTacToe board.
    %   Stores marks as a 3x3 char array: 'X', 'O', or ' ' (empty space).
    
    properties (Access = private)
        grid
        winner
    end
    
    methods
        function obj = Board()
            obj.grid  = repmat(' ', 3, 3);
            obj.winner = ' ';
        end
        
        function reset(obj)
            obj.grid(:) = ' ';
            obj.winner = ' ';
        end
        
        function g = getGrid(obj)
            g = obj.grid;
        end
        
        function m = getCell(obj, r, c)
            Board.validateIndex(r, c);
            m = obj.grid(r, c);
        end
        
        function tf = isEmpty(obj, r, c)
            Board.validateIndex(r, c);
            tf = (obj.grid(r, c) == ' ');
        end
        
        function ok = placeMark(obj, r, c, mark)
            % placeMark Places 'X' or 'O' at (r,c) if empty; updates winner.
            Board.validateIndex(r, c);
            Board.validateMark(mark);
            if obj.isEmpty(r, c)
                obj.grid(r, c) = mark;
                obj.updateWinner();
                ok = true;
            else
                ok = false;
            end
        end
        
        function tf = isFull(obj)
            tf = ~any(obj.grid == ' ');
        end
        
        function w = getWinner(obj)
            w = obj.winner;
        end
        
        function moves = getAvailableMoves(obj)
            [r, c] = find(obj.grid == ' ');
            moves = [r, c];
        end
        
        function w = simulateWinnerIfPlaced(obj, r, c, mark)
            % Returns winner if 'mark' were placed at (r,c) on a copy.
            Board.validateIndex(r, c);
            Board.validateMark(mark);
            g = obj.grid;
            g(r, c) = mark;
            w = Board.winnerFromGrid(g);
        end
    end
    
    methods (Access = private)
        function updateWinner(obj)
            obj.winner = Board.winnerFromGrid(obj.grid);
        end
    end
    
    methods (Static, Access = private)
        function w = winnerFromGrid(g)
            w = ' ';
            % Rows and columns
            for k = 1:3
                if all(g(k, :) == 'X'), w = 'X'; return; end
                if all(g(k, :) == 'O'), w = 'O'; return; end
                if all(g(:, k) == 'X'), w = 'X'; return; end
                if all(g(:, k) == 'O'), w = 'O'; return; end
            end
            % Diagonals
            if all(diag(g) == 'X'), w = 'X'; return; end
            if all(diag(g) == 'O'), w = 'O'; return; end
            if all(diag(flipud(g)) == 'X'), w = 'X'; return; end
            if all(diag(flipud(g)) == 'O'), w = 'O'; return; end
        end
        
        function validateIndex(r, c)
            assert(isscalar(r) && isscalar(c) && r >= 1 && r <= 3 && c >= 1 && c <= 3, ...
                   'Indices must be in [1..3].');
        end
        
        function validateMark(mark)
            assert(ischar(mark) && numel(mark)==1 && (mark=='X' || mark=='O'), ...
                   'Mark must be ''X'' or ''O''.');
        end
    end
end
