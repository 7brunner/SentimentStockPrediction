classdef MyTwitterAPI < twitty
    %MYTWITTERAPI Adds a download method for long tweet histories to twitty
    %API
    % --------
    % METHODS
    % --------
    % downloadAllTweets:
    % Repeatedly calls the search method of the twitty API with the maximum
    % of 100 allowed tweets to get the full results. Pauses for 16 minutes
    % after API limit is reached
    %
    
    
    properties
        TweetArray
        TweetArray_Last
        blnKeepFullTweets
        numAPICalls
    end
    
    methods
        
        %%  Constructor method
        % Set JSON parser and include tweetarray
        function obj = MyTwitterAPI(Inputs)
            obj = obj@twitty(Inputs);
            obj.TweetArray = cell(1000,1);
            obj.jsonParser = @loadjson;
            obj.TweetArray_Last = 0;
            obj.numAPICalls = 0;
        end
        
        function obj = downloadAllTweets(obj,varargin)
            %% Check inputs
            if any(cellfun(@(x) strcmp(x,'count') || strcmp(x,'result_type') || strcmp(x,'max_id'),varargin))
                error('Do not pass count, max_id or result_type argument')
            end
            
            pos = ismember(varargin,'since');
            
            if ~any(pos)
                error('Since argument is needed')
            end
            
            strSince = varargin{find(pos)+1};
            intSince = str2double(strSince([1:4 6:7 9:10]));
            
            %% Get first 100 tweets
            time = clock;
            disp([num2str(time(4)) ':' num2str(time(5)) ' - starting'])
            NewTweets = obj.trySearch(varargin{:},'count',100,'result_type','recent');
            [obj,blnLoop,last_id] = handleDownloadedTweets(obj,NewTweets,intSince);
            
            %% Loop to get remaining tweets
            while blnLoop
                NewTweets = obj.trySearch(varargin{:},'count',100,'result_type','recent','max_id',last_id);
                [obj,blnLoop,last_id] = handleDownloadedTweets(obj,NewTweets,intSince);
            end
        end
        
        %% Call twitty search function
        function Tweets = trySearch(obj,varargin)
            try
                obj.numAPICalls = obj.numAPICalls + 1;
                Tweets = obj.search(varargin{:});
            catch e
                time = clock;
%                 disp([num2str(obj.numAPICalls) ' API calls, ' ...
%                     num2str(obj.TweetArray_Last) ' tweets downloaded'])
                disp([num2str(time(4)) ':' num2str(time(5)) ' - pausing for 16 mins'])
                pause(960)
                Tweets = obj.trySearch(varargin{:});                
            end
        end
        
    end
    
    methods (Access = private)
        %% Handle downloaded tweets
        function [obj,blnLoop,last_id] = handleDownloadedTweets(obj,NewTweets,intSince)
            %%%
            % Check if any new tweets were downloaded
            NewTweets = NewTweets{1};
            NewTweets = NewTweets.statuses;
            
            if obj.numAPICalls >= 39
                a=1;
            end
            
            if isempty(NewTweets)
                blnLoop = false;
                last_id = '';
            else
                if obj.TweetArray_Last > 0
                    FirstTweet = NewTweets{1};
                    first_id = num2str(FirstTweet.id,'%u');

                    LastTweetInArry = obj.TweetArray{obj.TweetArray_Last};
                    lastInArray_id = num2str(LastTweetInArry.id,'%u');

                    if strcmp(first_id,lastInArray_id)
                        NewTweets(1) = [];
                    else
                        a=1;
                    end
                end
                                
                if isempty(NewTweets)
                    blnLoop = false;
                    last_id = '';
                elseif length(NewTweets) == 1
                    a=1;
                else
                    %%%
                    % Check if last tweet is younger than since date
                    LastTweet = NewTweets{end};
                    last_id = num2str(LastTweet.id,'%u');
                    strIn = LastTweet.created_at;

                    strYear = strIn(27:end);
                    strDay = strIn(9:10);
                    strMonthText = strIn(5:7);
                    switch strMonthText
                        case 'Jan'
                            strMonth = '01';
                        case 'Feb'
                            strMonth = '02';
                        case 'Mar'
                            strMonth = '03';
                        case 'Apr'
                            strMonth = '04';
                        case 'May'
                            strMonth = '05';
                        case 'Jun'
                            strMonth = '06';
                        case 'Jul'
                            strMonth = '07';
                        case 'Aug'
                            strMonth = '08';
                        case 'Sep'
                            strMonth = '09';
                        case 'Oct'
                            strMonth = '10';
                        case 'Nov'
                            strMonth = '11';
                        case 'Dec'
                            strMonth = '12';
                    end
                    last_date = str2double([strYear strMonth strDay]);

                    if last_date <= intSince
                        blnLoop = false;
                    else
                        blnLoop = true;
                    end

                    %%%
                    % Store new tweets in tweet array
                    disp([num2str(obj.numAPICalls) ' API calls, ' ...
                        num2str(obj.TweetArray_Last+length(NewTweets)) ...
                        ' Tweets downloaded, o.w. ' num2str(length(NewTweets))...
                        ' at latest call, latest tweet: ' LastTweet.created_at])

                    if obj.TweetArray_Last+length(NewTweets) > length(obj.TweetArray)
                        obj.TweetArray = [obj.TweetArray; cell(1000,1)];
                    end

                    obj.TweetArray(obj.TweetArray_Last+1:obj.TweetArray_Last+length(NewTweets)) = NewTweets;
                    obj.TweetArray_Last = obj.TweetArray_Last+length(NewTweets);
                end
            end
        end
        
    end
    
end

