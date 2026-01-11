
classdef Tetromino < handle
    properties
        name
        rotations   
        rotIndex = 1
        pos = [1 1] 
        id          
    end

    methods (Static)
        function obj = random()
            names = {'I','O','T','S','Z','J','L'};
            idx = randi(7);
            obj = Tetromino(names{idx});
        end
    end

    methods
        function this = Tetromino(name)
            this.name = upper(name);
            [rots, id] = Tetromino.getShape(this.name);
            this.rotations = rots;
            this.id = id;
            this.rotIndex = 1;
            this.pos = [1, 1];
        end

        function cells = getCells(this, pos, rotIndex)
            if nargin < 2, pos = this.pos; end
            if nargin < 3, rotIndex = this.rotIndex; end
            mask = this.rotations{rotIndex};
            [rs, cs] = find(mask);
            cells = [rs + pos(1) - 1, cs + pos(2) - 1];
        end

        function newIndex = rotatedIndex(this, dir)
            if nargin < 2, dir = 1; end 
            n = numel(this.rotations);
            newIndex = mod(this.rotIndex - 1 + dir, n) + 1;
        end
    end

    methods (Static)
        function [rots, id] = getShape(name)
            switch upper(name)
                case 'I'
                    id = 1; base = [1 1 1 1];
                    rots = {base; base'}; 
                case 'O'
                    id = 2; base = [1 1; 1 1];
                    rots = {base};
                case 'T'
                    id = 3;
                    rots = { [1 1 1; 0 1 0], ...
                             [0 1; 1 1; 0 1], ...
                             [0 1 0; 1 1 1], ...
                             [1 0; 1 1; 1 0] };
                case 'S'
                    id = 4;
                    rots = { [0 1 1; 1 1 0], ...
                             [1 0; 1 1; 0 1] };
                case 'Z'
                    id = 5;
                    rots = { [1 1 0; 0 1 1], ...
                             [0 1; 1 1; 1 0] };
                case 'J'
                    id = 6;
                    rots = { [1 0 0; 1 1 1], ...
                             [1 1; 1 0; 1 0], ...
                             [1 1 1; 0 0 1], ...
                             [0 1; 0 1; 1 1] };
                case 'L'
                    id = 7;
                    rots = { [0 0 1; 1 1 1], ...
                             [1 0; 1 0; 1 1], ...
                             [1 1 1; 1 0 0], ...
                             [1 1; 0 1; 0 1] };
                otherwise
                    error('Unknown tetromino name: %s', name);
            end
            for i = 1:numel(rots)
                rots{i} = rots{i} ~= 0; 
            end
        end
    end
end
