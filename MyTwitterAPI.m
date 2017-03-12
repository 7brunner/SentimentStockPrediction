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
        vecTweets
        vecTweets_Timestamp
        vecTweets_Sentiment
        arrTweets_Tokenized
        Vocabulary
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
            
%             pos = ismember(varargin,'since');
%             
%             if ~any(pos)
%                 error('Since argument is needed')
%             end
%             
%             strSince = varargin{find(pos)+1};
%             intSince = str2double(strSince([1:4 6:7 9:10]));
            
            %% Get first 100 tweets
            time = clock;
            disp([num2str(time(4)) ':' num2str(time(5)) ' - starting'])
            NewTweets = obj.trySearch(varargin{:},'count',100,'result_type','recent');
            [obj,blnLoop,last_id] = handleDownloadedTweets(obj,NewTweets);
            
            %% Loop to get remaining tweets
            while blnLoop
                NewTweets = obj.trySearch(varargin{:},'count',100,'result_type','recent','max_id',last_id);
                [obj,blnLoop,last_id] = handleDownloadedTweets(obj,NewTweets);
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
        
        %% Get-methods for tweet text and timestamp
        function vec = get.vecTweets(obj)
            vec = cellfun(@(x) x.text,obj.TweetArray ...
                (1:obj.TweetArray_Last),'UniformOutput',false);
        end
        
        function vec = get.vecTweets_Timestamp(obj)
            [intYear intMonth intDay intHour intMinute inSecond] = cellfun(@(x) obj.parseTwitterDate(x.created_at),obj.TweetArray(1:obj.TweetArray_Last));
            vec = datetime([intYear intMonth intDay intHour intMinute inSecond]);
        end
        
        %% Parse twitter date format
        function [intYear,intMonth,intDay,intHour,intMinute,intSecond] = parseTwitterDate(obj,strIn)
            intYear = str2double(strIn(27:end));
            intDay = str2double(strIn(9:10));
            intHour = str2double(strIn(12:13));
            intMinute = str2double(strIn(15:16));
            intSecond = str2double(strIn(18:19));
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
            intMonth = str2double(strMonth);
        end
        
        %% Tokenize tweets
        function obj = tokenizeTweets(obj)
            if isempty(obj.arrTweets_Tokenized)
                characters = 'abcdefghijklmnopqrstuvwxyz ';
                stopwords = urlread('http://www.textfixer.com/tutorials/common-english-words.txt');
                stopwords = strsplit(stopwords,',');

                arrTweets = cell(obj.TweetArray_Last,1);

                for iTweet = 1:obj.TweetArray_Last
                    strTweet = lower(obj.vecTweets{iTweet});

                    % Remove URLs, user names, Hash Tags and line breaks
                    strTweet = regexprep(strTweet,'(http|https)://[^\s]*','');
                    strTweet = regexprep(strTweet,'(@|#|\$|&)[^\s]*','');
                    strTweet = regexprep(strTweet,'[^\s]*\\u[^\s]*','');
                    strTweet = regexprep(strTweet,char(13),' ');
                    strTweet = regexprep(strTweet,char(10),' ');

                    % Only keep lexical content
                    strTweet = strTweet(ismember(strTweet,characters));

                    % split into array
                    arrTweet = strsplit(strTweet,' ');
                    
                    % Exclude stopwords and one-letter words
                    arrTweet = arrTweet(~ismember(arrTweet,stopwords));
                    arrTweet = arrTweet(cellfun(@length,arrTweet) > 1);
                    
                    % Store result
                    arrTweets{iTweet} = arrTweet;
                    if iTweet == 1
                        vocabs = unique(arrTweet);
                    else
                        vocabs = unique([vocabs arrTweet]);
                    end
                end
                obj.arrTweets_Tokenized = arrTweets;
                obj.Vocabulary = vocabs';
            end
        end
        
        %% Assign sentiment scores based on input score table
        function obj = assignBagOfWordScores(obj,ScoreTable)
            obj.tokenizeTweets;
            obj.vecTweets_Sentiment = zeros(obj.TweetArray_Last,1);
            
            for iTweet = 1:obj.TweetArray_Last                
                % Assign scores from passed table
                arrTweet = obj.arrTweets_Tokenized{iTweet};
                pos = ismember(ScoreTable.Term,arrTweet);
                dblScore = sum(ScoreTable.Score(pos));
                if ~isnan(dblScore)
                    obj.vecTweets_Sentiment(iTweet) = dblScore / sum(pos);
                end
            end
        end
    end
    
    methods (Access = private)
        %% Handle downloaded tweets
        function [obj,blnLoop,last_id] = handleDownloadedTweets(obj,NewTweets)
            %%%
            % Check if any new tweets were downloaded
            NewTweets = NewTweets{1};
            NewTweets = NewTweets.statuses;
                        
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
                    end
                end
                
                if isempty(NewTweets)
                    blnLoop = false;
                    last_id = '';
                else
                    blnLoop = true;
                    LastTweet = NewTweets{end};
                    last_id = num2str(LastTweet.id,'%u');
%                     %%%
%                     % Check if last tweet is younger than since date
%                     last_date = obj.parseTwitterDateShort(LastTweet.created_at);
%                     
%                     if last_date <= intSince
%                         blnLoop = false;
%                     else
%                         blnLoop = true;
%                     end
                    
                    %%%
                    % Store new tweets in tweet array
                    if obj.TweetArray_Last+length(NewTweets) > length(obj.TweetArray)
                        disp([num2str(obj.numAPICalls) ' API calls, ' ...
                        num2str(obj.TweetArray_Last+length(NewTweets)) ...
                        ' Tweets downloaded, o.w. ' num2str(length(NewTweets))...
                        ' at latest call, latest tweet: ' LastTweet.created_at])
                        obj.TweetArray = [obj.TweetArray; cell(1000,1)];
                    end
                    
                    obj.TweetArray(obj.TweetArray_Last+1:obj.TweetArray_Last+length(NewTweets)) = NewTweets;
                    obj.TweetArray_Last = obj.TweetArray_Last+length(NewTweets);
                end
            end
        end
        
    end
    
end

