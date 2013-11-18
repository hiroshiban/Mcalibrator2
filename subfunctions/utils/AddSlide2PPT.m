classdef AddSlide2PPT

    % Matlab class to generate PowerPoint 2007 slides
    %
    % Example:
    % ppt = FMRIQATestPPT(); %create a powerpoint presentation
    % ppt = ppt.addTitleSlide('10 Plots of Random Data'); %adds a title slide
    %
    % for i = 1:10
    %   a = rand(1,10); %a is some data
    %   f = figure; %create a figure
    %   plot(a); %plot your data
    %   xlabel('Some x axis label'); %apply some formatting and decoration
    %   ylabel('Some y axis label');
    %   image_file_name = fullfile(pwd, ['image_' num2str(i) '.png']);
    %   saveas(f, image_file_name); %save the figure
    %   close(f);
    %   %add the figure to the powerpoint
    %   ppt = ppt.addImageSlide(['Figure ' num2str(i)], image_file_name);
    % end
    % ppt.saveAs(fullfile(pwd,'presentation.ppt')); %save the presentation.
    %
    %
    % Modified by Hiroshi Ban for Mcalibrator2
    % Last Update: "2012-03-11 14:37:08 banh"

    %layout types:
    % 1 - title
    % 2 - title and content
    % 3 - section header
    % 4 - Two Content
    % 5 - Comparison
    % 6 - Title only
    % 7 - blank
    % 8 - content with caption
    % 9 - picture with caption
    % 10 -title and vertical text
    % 11 - vertical title and text

    properties
        app_handle
        presentation
        pt = 0.0352; %point size in cm.
        newline = char(13); %the new line character.
    end

    methods
        function obj = AddSlide2PPT()
            %creates a new presentation. You must have powerpoint
            %2007 open first.
            try
              obj.app_handle = actxserver('PowerPoint.Application'); %open powerpoint
            catch %#ok
              obj.app_handle=[];
              return;
            end
            obj.presentation = obj.app_handle.Presentation.Add; %create presentation
        end

        function obj = addTitleSlide(obj, title_text, sub_title_text)
            %creates a title slide
            %   ppt = ppt.addTitleSlide(title_text, sub_title_text)
            %       title_text - the text to put in the title section.
            %       sub_title_text - the text to put in the sub title
            %       section.
            %
            % If you need to use a line break (start a new line) use the
            % ppt.newline field of this object. (aka char(13)).

            %create slide
            layout = obj.presentation.SlideMaster.CustomLayouts.Item(1); %title slide layout
            Slide = obj.presentation.Slides.AddSlide(obj.presentation.Slides.Count + 1,layout);

            %do title
            if exist('title_text', 'var') && ~isempty(title_text)
                Slide.Shapes.Item(1).TextFrame.TextRange.Text = title_text;
            end

            %do sub-title
            if exist('sub_title_text', 'var') && ~isempty(sub_title_text)
                Slide.Shapes.Item(2).TextFrame.TextRange.Text = sub_title_text;
            end
        end

        function obj = addTextSlide(obj, title_text, main_text)
            %creates a section title slide
            %   ppt = ppt.addTitleSlide(title_text, main_text)
            %       title_text - the text to put in the title section.
            %       main_text - the text to put in the sub title
            %       section.
            %
            % If you need to use a line break (start a new line) use the
            % ppt.newline field of this object. (aka char(13)).

            %create slide
            layout = obj.presentation.SlideMaster.CustomLayouts.Item(2); %section header
            Slide = obj.presentation.Slides.AddSlide(obj.presentation.Slides.Count + 1,layout);

            %do title
            if exist('title_text', 'var') && ~isempty(title_text)
                tb = Slide.Shapes.Item(1);
                tb.TextFrame.TextRange.Text = title_text;
                tb.TextFrame.TextRange.Font.Size=24;
            end

            %do footer
            if exist('main_text', 'var') && ~isempty(main_text)
                tb2 = Slide.Shapes.Item(2);
                tb2.TextFrame.TextRange.Text = main_text;
                tb2.TextFrame.TextRange.Font.Size=18;
            end
        end

        function obj = addImageSlide(obj, title_text, image_file)
            %creates a slide consisting of only a title and an image
            %   ppt = ppt.addImageOnlySlide(title_text, image_file)
            %       title_text - the text to put in the title section.
            %       image_file - the filename and path of the image to use

            %create slide
            layout = obj.presentation.SlideMaster.CustomLayouts.Item(2); %title and content
            Slide = obj.presentation.Slides.AddSlide(obj.presentation.Slides.Count + 1,layout);

            %do image
            if exist('image_file', 'var') && ~isempty(image_file)
                li = Slide.Shapes.Item(2);
                Slide.Shapes.AddPicture(image_file,'msoFalse','msoTrue', li.left, li.top, li.width, li.height);
                %Slide.Shapes.AddPicture(image_file,'msoFalse','msoTrue',...
                %                        li.left+li.width/2-li.width/4, li.top-30, li.width/2, li.height+70);
            end

            %do title
            if exist('title_text', 'var') && ~isempty(title_text)
                Slide.Shapes.Item(1).TextFrame.TextRange.Text = title_text;
                Slide.Shapes.Item(1).TextFrame.TextRange.Font.Size=24;
            end
        end

        function obj = saveAs(obj, filename)
            %saves the presentation to the specified file
            obj.presentation.SaveAs(filename);
        end

        function obj = close(obj, noQuit)
            %closes the presentation.
            %   close(noQuit)
            %       noQuit - if false function will attempt
            %       to close powerpoint if no presentations remain open.

            if ~exist('noQuit', 'var') || (exist('noQuit', 'var') && isempty(noQuit))
                noQuit = true;
            end

            obj.presentation.Close;
            if ~noQuit && obj.app_handle.Presentations.Count <= 0
                obj.app_handle.Quit;
            end
            obj.app_handle.delete;
        end
    end

end
