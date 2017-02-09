classdef MyTwitterAPI < twitty
    %MYTWITTERAPI Adds a download method for long tweet histories to twitty
    %API
    % --------
    % METHODS
    % --------
    % downloadAllTweets:
    % Repeatedly calls the search method of the twitty API with the maximum
    % of 100 allowed tweets to get the full results
    
    
    properties
        TweetArray
        TweetArray_Last
        blnKeepFullTweets
    end
    
    methods
        
        function obj = MyTwitterAPI(Inputs)
            obj = obj@twitty(Inputs);
            obj.TweetArray = cell(1000,1);
            obj.jsonParser = @loadjson;
            obj.TweetArray_Last = 0;
        end
        
        function obj = downloadAllTweets(obj,varargin)
            if any(cellfun(@(x) strcmp(x,'count') || strcmp(x,'result_type') || strcmp(x,'max_id'),varargin))
                error('Do not pass count, max_id or result_type argument')
            end
            
            %% Get first 100 tweets
            NewTweets = obj.search(varargin{:},'count',100,'result_type','recent');
            [obj,blnLoop,last_id] = handleDownloadedTweets(obj,NewTweets);
            
            %% Loop to get remaining tweets
            while blnLoop
                NewTweets = obj.search(varargin{:},'count',100,'result_type','recent','max_id',last_id);
                [obj,blnLoop,last_id] = handleDownloadedTweets(obj,NewTweets);
            end
        end
        
    end
    
    methods (Access = private)
        function [obj,blnLoop,last_id] = handleDownloadedTweets(obj,NewTweets)
            NewTweets = NewTweets{1};
            NewTweets = NewTweets.statuses;
            
            if length(NewTweets) < 100
                blnLoop = false;
                last_id = '';
            else
                blnLoop = true;
                LastTweet = NewTweets{end};
                last_id = num2str(LastTweet.id,'%u');
            end
            
            if obj.TweetArray_Last+length(NewTweets) > length(obj.TweetArray)
                obj.TweetArray = [obj.TweetArray; cell(1000,1)];
            end
            
            obj.TweetArray(obj.TweetArray_Last+1:obj.TweetArray_Last+length(NewTweets)) = NewTweets;
            obj.TweetArray_Last = obj.TweetArray_Last+length(NewTweets);
        end
    end
    
end

