
IF NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N''tempResults'' AND ss.name = N''dbo'') 
CREATE TYPE [dbo].[tempResults] AS TABLE ( 
	[colName] varchar(100)
,	[originalValue] varchar(1000)
,	[newValue] varchar(1000)
); 
GO
IF NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N''TriggerItem'' AND ss.name = N''dbo'') 
CREATE TYPE [dbo].[TriggerItem] AS TABLE ( 
	[itemID] nvarchar(255)
); 
GO
IF NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N''ReportData'' AND ss.name = N''dbo'') 
CREATE TYPE [dbo].[ReportData] AS TABLE ( 
	[ReportDate] nvarchar(255)
,	[ReportField] nvarchar(255)
,	[ReportValue] int
); 
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION fn_xmlEscape
(
	@string    nvarchar(max)
)
RETURNS nvarchar(max)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @result nvarchar(max)

	set @result = REPLACE(@string,'&','&amp;')
	set @result = REPLACE(@result,'<','&lt;')
	set @result = REPLACE(@result,'>','&gt;')
	set @result = REPLACE(@result,'"','&quot;')

	-- array('&amp;', '&lt;', '&gt;', '&apos;', '&quot;')


	-- Return the result of the function
	RETURN  @result

END

GO

CREATE FUNCTION [dbo].[AppGroupPackageAutoMapWhereClause] 
(
	@AppGroupID as int,
	@nominate nvarchar(10) = ''
)
RETURNS nvarchar(3000)
AS
BEGIN
	DECLARE @AppGroupType smallint;
	DECLARE @GrabAll bit;

	SET @AppGroupType = 0

	select @AppGroupType = IsNull(g.AppGroupType,0), @GrabAll = gt.[GrabAll] from [ARM_CORE]..[AppGroup] g LEFT JOIN [ARM_CORE]..[A_AppGroupType] gt on gt.AppGroupType = g.AppGroupType where AppGroupID = @AppGroupID
	
	DECLARE @WHERE nvarchar(3000);

    DECLARE @AppCriteriaID int
    DECLARE @AppCriteriaType nvarchar(50)
    DECLARE @AppCriteriaScope nvarchar(500)
    DECLARE @AppCriteriaTerm nvarchar(1000)
    DECLARE @Label nvarchar(1000)
    DECLARE @Criteria nvarchar(1000)
    DECLARE @AltLogicGroup int
    DECLARE @currentGroup int

	DECLARE app_criteria CURSOR FOR 
		SELECT [AppCriteriaID] , [AppCriteriaType],[AppCriteriaTerm] ,[Label], [AltLogicGroup], [AppCriteriaScope]
		FROM [ARM_CORE]..[A_AppCriteria] c LEFT JOIN [ARM_CORE]..[A_Lookup] l on l.[Lookup] = c.AppCriteriaType
		where c.AppGroupID = @AppGroupID and IsNull(c.[nominate],'') = @nominate and l.[Table] = 'A_Appcriteria' and l.[Column] = 'AppCriteriaType' 
		and IsNull([AppCriteriaScope],'Application') = 'Application' order by [AltLogicGroup], [AppCriteriaID]

	
	OPEN app_criteria  
    FETCH NEXT FROM app_criteria INTO @AppCriteriaID, @AppCriteriaType, @AppCriteriaTerm, @Label, @AltLogicGroup, @AppCriteriaScope

	set @currentGroup = -1
	set @WHERE = ''

    WHILE @@FETCH_STATUS = 0  
    BEGIN 
		set @Criteria = Replace(@AppCriteriaType,'{X}',Replace(@AppCriteriaTerm,'''',''''''))

		if CHARINDEX('like',@AppCriteriaType) > 0 
		BEGIN
			set @Criteria = @Criteria + ' ESCAPE ''\'' '
		END

		if @currentGroup <> @AltLogicGroup 
		BEGIN
			if @currentGroup = -1
				set @WHERE = @WHERE + ' ( ( 1=1 ' 
			else
				set @WHERE = @WHERE + ' ) or ( 1=1 '

			set @currentGroup = @AltLogicGroup
		END

		if @AppCriteriaScope = 'Vendor' 
			set @WHERE = @WHERE + ' and s.[Vendor] ' + @Criteria + ' '
		else
			set @WHERE = @WHERE + ' and s.[ApplicationID] ' + @Criteria + ' '

		FETCH NEXT FROM app_criteria INTO @AppCriteriaID, @AppCriteriaType, @AppCriteriaTerm, @Label, @AltLogicGroup, @AppCriteriaScope
	END

	if @currentGroup <> -1 
	BEGIN
		set @WHERE = @WHERE + ' ) )'

		if @nominate = '' SET @WHERE = ' WHERE ' + @WHERE 
		if @nominate = 'Package' SET @WHERE = ' and ' + @WHERE 
		if @nominate = 'Common' SET @WHERE = ' and ' + @WHERE 
	END

	CLOSE app_criteria  
	DEALLOCATE app_criteria 

	if @GrabAll = 0 set @WHERE = @WHERE + ' and (IsNull(a.AppGroupID,0) = ' + cast(@AppGroupID as nvarchar(20)) + ' or IsNull(a.AppGroupID,0) = 0 or IsNull(gt.[AutoMapProcess],0) =0) '
--	if @AppGroupType >=20 and @AppGroupType < 30 set @WHERE = @WHERE + ' and (IsNull(a.AppGroupID,0) = ' + cast(@AppGroupID as nvarchar(20)) + ' or IsNull(a.AppGroupID,0) = 0 or IsNull(g.[AppGroupType],0) >= 30) '



	RETURN @WHERE

END



GO

CREATE function [dbo].[fn_removeAlpha] (@text  NVARCHAR(300))
RETURNS BIGINT
AS

BEGIN
DECLARE @bigX BIGINT
 WHILE PATINDEX('%[^0-9]%', @text) > 0
    BEGIN
        SET @text =  REPLACE(STUFF(@text, PATINDEX('%[^0-9]%', @text), 1, ''),'-','') 
    END
	
	set @bigX = CAST(LEFT( @text,15) as bigint)

RETURN @bigX

END

GO

CREATE FUNCTION [dbo].[fnColourClasstoRGB](@class AS NVARCHAR(20)) RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @RGB AS NVARCHAR(20)

    SELECT @RGB = RGB from [A_ColourPalette] where [Class] = @class

	if @RGB <> '' RETURN @RGB

	RETURN @class
END

GO
create function [dbo].[fn_DescribeSqlVariant] (
 @p sql_variant
 , @n sysname)
returns xml
with schemabinding
as
begin
 return (
 select @n as [@Name]
  , sql_variant_property(@p, 'BaseType') as [@BaseType]
  , sql_variant_property(@p, 'Precision') as [@Precision]
  , sql_variant_property(@p, 'Scale') as [@Scale]
  , sql_variant_property(@p, 'MaxLength') as [@MaxLength]
  , @p
  for xml path('parameter'), type)
end

GO

CREATE FUNCTION [dbo].[AppGroupAutoMapWhereClause] 
(
	@AppGroupID as int,
	@nominate nvarchar(10) = ''
)
RETURNS nvarchar(3000)
AS
BEGIN
	DECLARE @AppGroupType smallint;
	DECLARE @GrabAll bit;

	SET @AppGroupType = 0

	select @AppGroupType = IsNull(g.AppGroupType,0), @GrabAll = gt.[GrabAll] from [ARM_CORE]..[AppGroup] g LEFT JOIN [ARM_CORE]..[A_AppGroupType] gt on gt.AppGroupType = g.AppGroupType where AppGroupID = @AppGroupID
	
	DECLARE @WHERE nvarchar(3000);

    DECLARE @AppCriteriaID int
    DECLARE @AppCriteriaType nvarchar(50)
    DECLARE @AppCriteriaScope nvarchar(500)
    DECLARE @AppCriteriaTerm nvarchar(1000)
    DECLARE @Label nvarchar(1000)
    DECLARE @Criteria nvarchar(1000)
    DECLARE @AltLogicGroup int
    DECLARE @currentGroup int

	DECLARE app_criteria CURSOR 
	LOCAL STATIC
	FOR 
		SELECT [AppCriteriaID] , [AppCriteriaType],[AppCriteriaTerm] ,[Label], [AltLogicGroup], [AppCriteriaScope]
		FROM [ARM_CORE]..[A_AppCriteria] c LEFT JOIN [ARM_CORE]..[A_Lookup] l on l.[Lookup] = c.AppCriteriaType
		where c.AppGroupID = @AppGroupID and IsNull(c.[nominate],'') = @nominate and l.[Table] = 'A_Appcriteria' and l.[Column] = 'AppCriteriaType' order by [AltLogicGroup], [AppCriteriaID]

	
	OPEN app_criteria  
    FETCH NEXT FROM app_criteria INTO @AppCriteriaID, @AppCriteriaType, @AppCriteriaTerm, @Label, @AltLogicGroup, @AppCriteriaScope

	set @currentGroup = -1
	set @WHERE = ''

    WHILE @@FETCH_STATUS = 0  
    BEGIN 
		set @Criteria = Replace(@AppCriteriaType,'{X}',Replace(@AppCriteriaTerm,'''',''''''))

		if CHARINDEX('like',@AppCriteriaType) > 0 
		BEGIN
			set @Criteria = @Criteria + ' ESCAPE ''\'' '
		END

		if @currentGroup <> @AltLogicGroup 
		BEGIN
			if @currentGroup = -1
				set @WHERE = @WHERE + ' ( ( 1=1 ' 
			else
				set @WHERE = @WHERE + ' ) or ( 1=1 '

			set @currentGroup = @AltLogicGroup
		END

		if @AppCriteriaScope = 'Vendor' 
			set @WHERE = @WHERE + ' and s.[Vendor] ' + @Criteria + ' '
		else
			set @WHERE = @WHERE + ' and s.[ApplicationID] ' + @Criteria + ' '

		FETCH NEXT FROM app_criteria INTO @AppCriteriaID, @AppCriteriaType, @AppCriteriaTerm, @Label, @AltLogicGroup, @AppCriteriaScope
	END

	if @currentGroup <> -1 
	BEGIN
		set @WHERE = @WHERE + ' ) )'

		if @nominate = '' SET @WHERE = ' WHERE ' + @WHERE 
		if @nominate = 'Package' SET @WHERE = ' and ' + @WHERE 
		if @nominate = 'Common' SET @WHERE = ' and ' + @WHERE 
	END

	CLOSE app_criteria  
	DEALLOCATE app_criteria 

	if @GrabAll = 0 set @WHERE = @WHERE + ' and (IsNull(a.AppGroupID,0) = ' + cast(@AppGroupID as nvarchar(20)) + ' or IsNull(a.AppGroupID,0) = 0 or IsNull(gt.[AutoMapProcess],0) =0) '
--	if @AppGroupType >=20 and @AppGroupType < 30 set @WHERE = @WHERE + ' and (IsNull(a.AppGroupID,0) = ' + cast(@AppGroupID as nvarchar(20)) + ' or IsNull(a.AppGroupID,0) = 0 or IsNull(g.[AppGroupType],0) >= 30) '



	RETURN @WHERE

END



GO

	CREATE FUNCTION dbo.fn_diagramobjects() 
	RETURNS int
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		declare @id_upgraddiagrams		int
		declare @id_sysdiagrams			int
		declare @id_helpdiagrams		int
		declare @id_helpdiagramdefinition	int
		declare @id_creatediagram	int
		declare @id_renamediagram	int
		declare @id_alterdiagram 	int 
		declare @id_dropdiagram		int
		declare @InstalledObjects	int

		select @InstalledObjects = 0

		select 	@id_upgraddiagrams = object_id(N'dbo.sp_upgraddiagrams'),
			@id_sysdiagrams = object_id(N'dbo.sysdiagrams'),
			@id_helpdiagrams = object_id(N'dbo.sp_helpdiagrams'),
			@id_helpdiagramdefinition = object_id(N'dbo.sp_helpdiagramdefinition'),
			@id_creatediagram = object_id(N'dbo.sp_creatediagram'),
			@id_renamediagram = object_id(N'dbo.sp_renamediagram'),
			@id_alterdiagram = object_id(N'dbo.sp_alterdiagram'), 
			@id_dropdiagram = object_id(N'dbo.sp_dropdiagram')

		if @id_upgraddiagrams is not null
			select @InstalledObjects = @InstalledObjects + 1
		if @id_sysdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 2
		if @id_helpdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 4
		if @id_helpdiagramdefinition is not null
			select @InstalledObjects = @InstalledObjects + 8
		if @id_creatediagram is not null
			select @InstalledObjects = @InstalledObjects + 16
		if @id_renamediagram is not null
			select @InstalledObjects = @InstalledObjects + 32
		if @id_alterdiagram  is not null
			select @InstalledObjects = @InstalledObjects + 64
		if @id_dropdiagram is not null
			select @InstalledObjects = @InstalledObjects + 128
		
		return @InstalledObjects 
	END
	
GO
CREATE FUNCTION [dbo].[fn_split_string]
(
    @string    nvarchar(max),
    @delimiter nvarchar(100)
)
/*
    The same as STRING_SPLIT for compatibility level < 130
    https://docs.microsoft.com/en-us/sql/t-sql/functions/string-split-transact-sql?view=sql-server-ver15
*/
RETURNS TABLE AS RETURN
(
    SELECT 
      --ROW_NUMBER ( ) over(order by (select 0))                            AS id     --  intuitive, but not correect
        Split.a.value('let $n := . return count(../*[. << $n]) + 1', 'int') AS id
      , Split.a.value('.', 'NVARCHAR(MAX)')                                 AS value
    FROM
    (
        SELECT CAST('<X>'+REPLACE(@string, @delimiter, '</X><X>')+'</X>' AS XML) AS String
    ) AS a
    CROSS APPLY String.nodes('/X') AS Split(a)
)

GO

Create FUNCTION [dbo].[uftReadfileAsTable]
(
@Path VARCHAR(255),
@Filename VARCHAR(100)
)
RETURNS 
@File TABLE
(
[LineNo] int identity(1,1), 
line varchar(8000)) 

AS
BEGIN

DECLARE  @objFileSystem int
        ,@objTextStream int,
		@objErrorObject int,
		@strErrorMessage Varchar(1000),
	    @Command varchar(1000),
	    @hr int,
		@String VARCHAR(8000),
		@YesOrNo INT

select @strErrorMessage='opening the File System Object'
EXECUTE @hr = sp_OACreate  'Scripting.FileSystemObject' , @objFileSystem OUT


if @HR=0 Select @objErrorObject=@objFileSystem, @strErrorMessage='Opening file "'+@path+'\'+@filename+'"',@command=@path+'\'+@filename

if @HR=0 execute @hr = sp_OAMethod   @objFileSystem  , 'OpenTextFile'
	, @objTextStream OUT, @command,1,false,0--for reading, FormatASCII

WHILE @hr=0
	BEGIN
	if @HR=0 Select @objErrorObject=@objTextStream, 
		@strErrorMessage='finding out if there is more to read in "'+@filename+'"'
	if @HR=0 execute @hr = sp_OAGetProperty @objTextStream, 'AtEndOfStream', @YesOrNo OUTPUT

	IF @YesOrNo<>0  break
	if @HR=0 Select @objErrorObject=@objTextStream, 
		@strErrorMessage='reading from the output file "'+@filename+'"'
	if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Readline', @String OUTPUT
	INSERT INTO @file(line) SELECT @String
	END

if @HR=0 Select @objErrorObject=@objTextStream, 
	@strErrorMessage='closing the output file "'+@filename+'"'
if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Close'


if @hr<>0
	begin
	Declare 
		@Source varchar(255),
		@Description Varchar(255),
		@Helpfile Varchar(255),
		@HelpID int
	
	EXECUTE sp_OAGetErrorInfo  @objErrorObject, 
		@source output,@Description output,@Helpfile output,@HelpID output
	Select @strErrorMessage='Error whilst '
			+coalesce(@strErrorMessage,'doing something')
			+', '+coalesce(@Description,'')
	insert into @File(line) select @strErrorMessage
	end
EXECUTE  sp_OADestroy @objTextStream
	-- Fill the table variable with the rows for your result set
	
	RETURN 
END

GO
CREATE FUNCTION [dbo].[udf_List2Table]
(
@List VARCHAR(MAX),
@Delim CHAR
)
RETURNS
@ParsedList TABLE
(
item VARCHAR(MAX)
 )
AS
 BEGIN
 DECLARE @item VARCHAR(MAX), @Pos INT
 SET @List = LTRIM(RTRIM(@List))+ @Delim
SET @Pos = CHARINDEX(@Delim, @List, 1)
WHILE @Pos > 0
BEGIN
 SET @item = LTRIM(RTRIM(LEFT(@List, @Pos - 1)))
IF @item <> ''
BEGIN
 INSERT INTO @ParsedList (item)
VALUES (CAST(@item AS VARCHAR(MAX)))
END
 SET @List = RIGHT(@List, LEN(@List) - @Pos)
SET @Pos = CHARINDEX(@Delim, @List, 1)
END
 RETURN
 END

GO

CREATE FUNCTION [dbo].[TrimTree2](
@String varchar(8000),
@Delimiter char(1),
@Start int = 1,
@Count int = 1
)
returns varchar(8000)
as     
begin

       declare @idx int     
       declare @slice varchar(8000)    

       select @idx = 1     

       if len(@String)<1 or @String is null  return null

       declare @ColCnt int
       declare @pos int

       set @ColCnt = 1
       set @pos = 0

       set @slice = @String

       if @Start > 1 
       BEGIN
             while (@idx != 0)
             begin     
                    set @idx = charindex(@Delimiter,@slice)     
                    if @idx!=0 begin
                           if (@ColCnt = @Start -1 ) 
                           BEGIN
                                 set @String = right(@String,len(@String) - @idx - @pos)  
                                 break
                           END     

                           set @ColCnt = @ColCnt + 1

                           set @slice = right(@slice,len(@slice) - @idx)  
                           set @pos = @pos + @idx

                           if len(@slice) = 0 break
                    end
             end 
       END

       set @slice = @String
       set @ColCnt = 1
       set @pos = 0

       while (@idx != 0)
       begin     
             set @idx = charindex(@Delimiter,@slice)     
             if @idx!=0 begin
                    if (@ColCnt = @Count) return left(@String,@pos + @idx - 1)        
                    
                    set @pos = @pos + @idx
                    set @ColCnt = @ColCnt + 1
             end

             set @slice = right(@String,len(@slice) - @idx)     
             if len(@slice) = 0 break
       end 
       return @String  


end

GO
CREATE FUNCTION [dbo].[SplitOrderIDs]
(
	@OrderList varchar(500)
)
RETURNS 
@ParsedList table
(
	OrderID int
)
AS
BEGIN
	DECLARE @OrderID varchar(10), @Pos int

	SET @OrderList = LTRIM(RTRIM(@OrderList))+ ','
	SET @Pos = CHARINDEX(',', @OrderList, 1)

	IF REPLACE(@OrderList, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @OrderID = LTRIM(RTRIM(LEFT(@OrderList, @Pos - 1)))
			IF @OrderID <> ''
			BEGIN
				INSERT INTO @ParsedList (OrderID) 
				VALUES (CAST(@OrderID AS int)) --Use Appropriate conversion
			END
			SET @OrderList = RIGHT(@OrderList, LEN(@OrderList) - @Pos)
			SET @Pos = CHARINDEX(',', @OrderList, 1)

		END
	END	
	RETURN
END



GO
CREATE Function [dbo].[RemoveNonAlphaCharacters](@Temp VarChar(1000))

Returns VarChar(1000)

AS

Begin

 

    Declare @KeepValues as varchar(50)

    Set @KeepValues = '%[^a-z0-9!"£$%^&*#?()_+-=\,./;-][ ][_]%'

    While PatIndex(@KeepValues, @Temp) > 0

        Set @Temp = Stuff(@Temp, PatIndex(@KeepValues, @Temp), 1, '#')

 

    return @Temp

End

GO
CREATE FUNCTION [dbo].[fnGlobalProperty]
(
	@Property nvarchar(1000)
)
RETURNS nvarchar(1000)
AS
BEGIN
	Declare @Value as nvarchar(1000) = NULL
	Declare @Root as nvarchar(1000) = NULL
	Declare @PropGroup as nvarchar(1000) = NULL

	select @Value = Trim([PropertyValue]), @PropGroup = Trim([PropertyGroup]) from [ARM_CORE]..[SystemGlobalProperties] where [PropertyName] = @Property

	select @Root = Trim(IsNull((select [PropertyValue] from [ARM_CORE]..[SystemGlobalProperties] where [PropertyName] = 'APPROOT'),''))
	if Right(@Root,1) = '\' set @Root = Left(@Root,Len(@Root)-1)
	set @Value = replace(@Value,'{APPROOT}',@Root)

	select @Root = Trim(IsNull((select [PropertyValue] from [ARM_CORE]..[SystemGlobalProperties] where [PropertyName] = 'DATAROOT'),''))
	if Right(@Root,1) = '\' set @Root = Left(@Root,Len(@Root)-1)
	set @Value = replace(@Value,'{DATAROOT}',@Root)

	select @Root = Trim(IsNull((select [PropertyValue] from [ARM_CORE]..[SystemGlobalProperties] where [PropertyName] = 'WWWROOT'),''))
	if Right(@Root,1) = '\' set @Root = Left(@Root,Len(@Root)-1)
	set @Value = replace(@Value,'{WWWROOT}',@Root)

	select @Root = Trim(IsNull((select [PropertyValue] from [ARM_CORE]..[SystemGlobalProperties] where [PropertyName] = 'HTTPSERVER'),''))
	if Right(@Root,1) = '/' set @Root = Left(@Root,Len(@Root)-1)
	set @Value = replace(@Value,'{HTTPSERVER}',@Root)


	if @PropGroup = 'Folder'
	BEGIN
		if Right(@Value,1) <> '\' set @Value = @Value + '\'
	END
	if @PropGroup = 'WebFolder'
	BEGIN
		if Right(@Value,1) <> '/' set @Value = @Value + '/'
	END
	RETURN @Value
END



GO

CREATE FUNCTION [dbo].[fnIntIPv4](@ip AS VARCHAR(15)) RETURNS int
AS
BEGIN
    DECLARE @bin AS BINARY(4)

    SELECT @bin = CAST( PARSENAME( @ip, 4 ) AS INTEGER) 
                + CAST( PARSENAME( @ip, 3 ) AS INTEGER) 
                + CAST( PARSENAME( @ip, 2 ) AS INTEGER) 
                + CAST( PARSENAME( @ip, 1 ) AS INTEGER) 

    RETURN @bin
END

GO


CREATE FUNCTION [dbo].[fnDisplayIPv4](@ip AS BINARY(4)) RETURNS VARCHAR(15)
AS
BEGIN
    DECLARE @str AS VARCHAR(15) 

    SELECT @str = CAST( CAST( SUBSTRING( @ip, 1, 1) AS INTEGER) AS VARCHAR(3) ) + '.'
                + CAST( CAST( SUBSTRING( @ip, 2, 1) AS INTEGER) AS VARCHAR(3) ) + '.'
                + CAST( CAST( SUBSTRING( @ip, 3, 1) AS INTEGER) AS VARCHAR(3) ) + '.'
                + CAST( CAST( SUBSTRING( @ip, 4, 1) AS INTEGER) AS VARCHAR(3) );

    RETURN @str
END;

GO

CREATE FUNCTION [dbo].[fnBinaryIPv4](@ip AS VARCHAR(15)) RETURNS BINARY(4)
AS
BEGIN
    DECLARE @bin AS BINARY(4)

    SELECT @bin = CAST( CAST( PARSENAME( @ip, 4 ) AS INTEGER) AS BINARY(1))
                + CAST( CAST( PARSENAME( @ip, 3 ) AS INTEGER) AS BINARY(1))
                + CAST( CAST( PARSENAME( @ip, 2 ) AS INTEGER) AS BINARY(1))
                + CAST( CAST( PARSENAME( @ip, 1 ) AS INTEGER) AS BINARY(1))

    RETURN @bin
END

GO

CREATE FUNCTION [dbo].[CSVToTable] (@InStr VARCHAR(MAX))
RETURNS @TempTab TABLE
   (id VARCHAR(MAX) not null)
AS
BEGIN
    ;-- Ensure input ends with comma
	SET @InStr = REPLACE(@InStr + ',', ',,', ',')
	DECLARE @SP INT
DECLARE @VALUE VARCHAR(1000)
WHILE PATINDEX('%,%', @INSTR ) <> 0 
BEGIN
   SELECT  @SP = PATINDEX('%,%',@INSTR)
   SELECT  @VALUE = LEFT(@INSTR , @SP - 1)
   SELECT  @INSTR = STUFF(@INSTR, 1, @SP, '')
   INSERT INTO @TempTab(id) VALUES (@VALUE)
END
	RETURN
END



GO
-- =============================================
-- Author:             <Author,,Name>
-- Create date: <Create Date,,>
-- Description:        <Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Criteria-Class-fn]
(
	@ClassID int = 0,
	@CType nvarchar(100) = 'ASSET'
)
RETURNS nvarchar(max)
AS
BEGIN



	Declare @CollectionID int
	Declare @Criteria bit
	Declare @Mode bit
	Declare @brackets bit
	Declare @X int

	Declare @SQL nvarchar(3000)

	set @SQL = 'SELECT a.[' + @CType + 'ID], 1  as [RESULT] from [ARM_CORE]..[' + @CType + '] a '
	 
	DECLARE Collections SCROLL CURSOR FOR 
		select c.CollectionID, c.CriteriaState, cc.CriteriaState as [Mode] from [ARM_CORE]..[A_Collection] c LEFT JOIN [ARM_CORE]..[A_CollectionClass] cc on cc.CollectionCLassID = c.CollectionClassID where c.CollectionClassID = @ClassID
		   and c.[Type] = @CType and NOT c.CriteriaState IS NULL order by c.CriteriaState desc, c.[Order]

	OPEN Collections 
    
	FETCH NEXT FROM Collections INTO @CollectionID, @Criteria, @Mode

	set @X = 0
	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		
			set @SQL = @SQL + ' LEFT JOIN [ARM_CORE]..[A_CollectionItem] c' + convert(nvarchar(16),@X) + ' on c' + convert(nvarchar(16),@X) + '.[ItemID] = a.[' + @CType + 'ID] and c' + convert(nvarchar(16),@X) + '.CollectionID = ' + convert(nvarchar(16),@CollectionID)

			FETCH NEXT FROM Collections INTO @CollectionID, @Criteria, @Mode
			set @X = @X + 1
		
	END 

	CLOSE Collections  



	OPEN Collections 
    
	FETCH NEXT FROM Collections INTO @CollectionID, @Criteria, @Mode

	set @SQL = @SQL + ' where '

	set @X = 0
	set @brackets = 0


	if @Mode = 0 
	BEGIN
		set @SQL = @SQL + ' ( '
		set @brackets = 1
	END


	WHILE @@FETCH_STATUS = 0  
	BEGIN 
		
			if @X > 0  
			BEGIN
				if @Criteria = 1 and @mode = 0
				BEGIN
					set @SQL = @SQL + ' OR ' 
				END
				else
				BEGIN
					IF @brackets = 1 
					BEGIN
						set @SQL = @SQL + ' ) ' 
						set @brackets = 0
					END

					set @SQL = @SQL + ' AND ' 
				END
			END 

			if @Criteria = 1  
			BEGIN
				set @SQL = @SQL + ' NOT '
			END 
						
			set @SQL = @SQL + ' c' + convert(nvarchar(16),@X) + '.ItemID IS NULL ' 

			FETCH NEXT FROM Collections INTO @CollectionID, @Criteria, @Mode
			set @X = @X + 1
		
	END 

	IF @brackets = 1 
	BEGIN
		set @SQL = @SQL + ' ) ' 
		set @brackets = 0
	END

	CLOSE Collections  
	DEALLOCATE Collections 

		

	RETURN @SQL 
END

GO
CREATE FUNCTION [dbo].[CheckCollectionItem]
(
	@CollectionID int,
	@ItemID nvarchar(255)
)
RETURNS bit
AS
BEGIN
	Declare @BitValue as bit


	IF Exists (select * from [ARM_CORE]..[A_CollectionItem] i  where i.CollectionID = @CollectionID and i.ItemID = @ItemID)
		set @BitValue = 1
	ELSE
		set @BitValue = 0


	RETURN @BitValue

END



GO
CREATE FUNCTION [dbo].[CheckBitStatus]
(
	@BitStatus bigInt,
	@GroupName nvarchar(255),
	@Attribute nvarchar(255)
)
RETURNS bigInt
AS
BEGIN
	Declare @BitValue as bigInt


	select @BitValue = @BitStatus & Power(CONVERT(bigint,2),(SELECT IsNull(b.BitPosition,1) -1 from [ARM_CORE]..[A_BITCONDITION] b where GroupName = @GroupName and Attribute = @Attribute))


	RETURN @BitValue

END



GO
CREATE FUNCTION [dbo].[BAreaWithMostInstalls]
(
	@ApplicationID nvarchar(255)
)
RETURNS nvarchar(255)
AS
BEGIN
	Declare @BArea as nvarchar(255)


	select top 1  @BArea = x.BArea from (
            select IsNull(a.BArea,'NOT SPECIFIED') as BArea, count(s.AssetID) AS Counter
            from [ARM_CORE]..AppAstToBe s 
            LEFT JOIN [ARM_CORE]..Asset a on a.AssetID = s.AssetID
            where s.ApplicationID = @ApplicationID and IsNull(a.Live,0) = 1
            Group By IsNull(a.BArea,'NOT SPECIFIED')   
	) x order by x.Counter Desc


	RETURN @BArea

END



GO
CREATE FUNCTION [dbo].[AppReleasePathByStatus]
(
	@base nvarchar(255) = '%',
	@CurrentCount int = 0,
	@STATUSID int = 0
)
RETURNS 
@ParsedList table
(
	[App ID] [nvarchar](500) NULL,
	[Status] [nvarchar](255) NULL,
	[Type] [nvarchar](255) NULL,
	[Installs] [int] NULL,
	[Release] [int] NULL,
	[Max] [int] NULL,
	[Impact] [int] NULL,
	[Total] int
)
AS
BEGIN



	INSERT INTO @ParsedList ([App ID],[Status],[Type],[Installs],[Release],[Impact],[Total]) 
	select top 1 z.*, 100 * z.Installs / h.[Count] as Impact, @CurrentCount + z.Release from (
	 select r.*,
	(
		select count(*) from (
			select b.AssetID, count(b.ApplicationID) AppsNotReady from [ARM_CORE]..[AppAstToBe] b 
			LEFT JOIN [ARM_CORE]..[Application] a on a.ApplicationID = b.ApplicationID
			LEFT JOIN [ARM_CORE]..[Asset] t on t.AssetID = b.AssetID
			where IsNull(a.DeployType,'-') <> 'B' and IsNull(a.DeployType,'-') <> 'X' and IsNull(a.Ready,0) = 0 and IsNull(a.Exclude,0) = 0
				and t.[BArea] like  @base  and t.Live = 1 
			group by b.AssetID 
		) q LEFT JOIN (
			select x.AssetID from [ARM_CORE]..[AppAstToBe] x where x.ApplicationID = r.[App ID]
		) s on s.AssetID = q.AssetID 
		where q.AppsNotReady = 1 and NOT s.AssetID IS NULL 
	) as Release 
	from (
	
		select distinct  top 1 b.ApplicationID as [App ID]
		, c.Name as [Status] 
		, a.DeployType
		, CUT_IC.IC as [Installs] 
		from  [ARM_CORE]..[Asset] t 	
		LEFT JOIN [ARM_CORE]..[AppAstToBe] b on b.AssetID = t.AssetID
		LEFT JOIN [ARM_CORE]..[Application] a on a.ApplicationID = b.ApplicationID 
		LEFT JOIN [ARM_CORE]..[A_CollectionItem] i on i.ItemID = b.ApplicationID
		LEFT JOIN [ARM_CORE]..[A_Collection] c on c.CollectionID = i.CollectionID
		LEFT JOIN ( 

			SELECT z.ApplicationID, count(distinct z.AssetID) as IC from [ARM_CORE]..[AppAstToBe] z 
			LEFT JOIN [ARM_CORE]..[Asset] y on y.AssetID = z.AssetID 
			where y.[BArea] like  @base and y.Live = 1 group by z.ApplicationID 

		) AS CUT_IC on CUT_IC.ApplicationID = b.ApplicationID 
		where NOT b.[ApplicationID] IS NULL  and IsNull(a.DeployType,'-') <> 'B' and IsNull(a.DeployType,'-') <> 'X' and IsNull(a.Ready,0) = 0 and IsNull(a.Exclude,0) = 0
			and t.[BArea] like @base and t.Live = 1 and i.CollectionID = @STATUSID
		order by [Installs] Desc, [App ID]


	) r )  z 
	LEFT JOIN [ARM_CORE]..[s_ApplicationToBeInstallCount] h on h.ApplicationID = z.[App ID] 
	order by z.[Installs] desc


	RETURN
END





GO
CREATE FUNCTION [dbo].[AppReleasePathByReleaseCID]
(
	@CID int = 0,
	@CurrentCount int = 0
)
RETURNS 
@ParsedList table
(
	[App ID] [nvarchar](500) NULL,
	[Status] [nvarchar](255) NULL,
	[Type] [nvarchar](255) NULL,
	[Installs] [int] NULL,
	[Release] [int] NULL,
	[Max] [int] NULL,
	[Impact] [int] NULL,
	[Total] int
)
AS
BEGIN
	INSERT INTO @ParsedList ([App ID],[Status],[Type],[Installs],[Release],[Impact],[Total]) 
	select top 1 z.*, 100 * z.Installs / h.[Count] as Impact, @CurrentCount + z.Release from (
	 select r.*,
	(
		select count(*) from (
			select b.AssetID, count(b.ApplicationID) AppsNotReady 
			from  [ARM_CORE]..[A_CollectionItem] yi  
			LEFT JOIN [ARM_CORE]..[AppAstToBe] b on b.AssetID = yi.ItemID
			LEFT JOIN [ARM_CORE]..[Application] a on a.ApplicationID = b.ApplicationID
			LEFT JOIN [ARM_CORE]..[Asset] t on t.AssetID = b.AssetID
			where IsNull(a.DeployType,'-') <> 'B' and IsNull(a.DeployType,'-') <> 'X' and IsNull(a.Ready,0) = 0 and IsNull(a.Exclude,0) = 0
				and yi.CollectionID = @CID   and t.Live = 1 
			group by b.AssetID 
		) q LEFT JOIN (
			select x.AssetID from [ARM_CORE]..[AppAstToBe] x where x.ApplicationID = r.[App ID]
		) s on s.AssetID = q.AssetID 
		where q.AppsNotReady = 1 and NOT s.AssetID IS NULL 
	) as Release 
	from (
	
		select distinct  top 12 b.ApplicationID as [App ID]
		, (SELECT top 1 c.Name from [ARM_CORE]..[A_Collection] c LEFT JOIN [ARM_CORE]..[A_CollectionClass] cc on cc.CollectionClassID = c.CollectionClassID LEFT JOIN [ARM_CORE]..[A_CollectionItem] i on i.CollectionID = c.CollectionID where i.ItemID = a.ApplicationID and cc.CLASSREF = 'ApplicationReadiness' ) as [Status] 
		, a.DeployType
		, CUT_IC.IC as [Installs] 
		from  [ARM_CORE]..[A_CollectionItem] i 
		LEFT JOIN [ARM_CORE]..[Asset] t on t.AssetID = i.ItemID
		LEFT JOIN [ARM_CORE]..[AppAstToBe] b on b.AssetID = t.AssetID
		LEFT JOIN [ARM_CORE]..[Application] a on a.ApplicationID = b.ApplicationID 
		LEFT JOIN ( 

			SELECT z.ApplicationID, count(distinct z.AssetID) as IC 
			from  [ARM_CORE]..[A_CollectionItem] zi  
			LEFT JOIN [ARM_CORE]..[AppAstToBe] z on z.AssetID = zi.ItemID
			LEFT JOIN [ARM_CORE]..[Asset] y on y.AssetID = z.AssetID 
			where zi.CollectionID = @CID and y.Live = 1 group by z.ApplicationID 

		) AS CUT_IC on CUT_IC.ApplicationID = b.ApplicationID 
		where NOT b.[ApplicationID] IS NULL  and IsNull(a.DeployType,'-') <> 'B' and IsNull(a.DeployType,'-') <> 'X' and IsNull(a.Ready,0) = 0 and IsNull(a.Exclude,0) = 0
			and i.CollectionID = @CID and t.Live = 1
		order by [Installs] Desc, [App ID]


	) r )  z 
	LEFT JOIN [ARM_CORE]..[s_ApplicationToBeInstallCount] h on h.ApplicationID = z.[App ID] order by z.[Release] desc


	RETURN
END





GO
CREATE FUNCTION [dbo].[AppReleasePathByRelease]
(
	@base nvarchar(255) = '%',
	@CurrentCount int = 0
)
RETURNS 
@ParsedList table
(
	[App ID] [nvarchar](500) NULL,
	[Status] [nvarchar](255) NULL,
	[Type] [nvarchar](255) NULL,
	[Installs] [int] NULL,
	[Release] [int] NULL,
	[Max] [int] NULL,
	[Impact] [int] NULL,
	[Total] int
)
AS
BEGIN



	INSERT INTO @ParsedList ([App ID],[Status],[Type],[Installs],[Release],[Impact],[Total]) 
	select top 1 z.*, 100 * z.Installs / h.[Count] as Impact, @CurrentCount + z.Release from (
	 select r.*,
	(
		select count(*) from (
			select b.AssetID, count(b.ApplicationID) AppsNotReady from [ARM_CORE]..[AppAstToBe] b
			LEFT JOIN [ARM_CORE]..[Application] a on a.ApplicationID = b.ApplicationID
			LEFT JOIN [ARM_CORE]..[Asset] t on t.AssetID = b.AssetID
			where IsNull(a.DeployType,'-') <> 'B' and IsNull(a.DeployType,'-') <> 'X' and IsNull(a.Ready,0) = 0 and IsNull(a.Exclude,0) = 0
				and t.[BArea] like  @base  and t.Live = 1 
			group by b.AssetID 
		) q LEFT JOIN (
			select x.AssetID from [ARM_CORE]..[AppAstToBe] x where x.ApplicationID = r.[App ID]
		) s on s.AssetID = q.AssetID 
		where q.AppsNotReady = 1 and NOT s.AssetID IS NULL 
	) as Release 
	from (
	
		select distinct  top 12 b.ApplicationID as [App ID]
		, (SELECT top 1 c.Name from [ARM_CORE]..[A_Collection] c LEFT JOIN [ARM_CORE]..[A_CollectionClass] cc on cc.CollectionClassID = c.CollectionClassID LEFT JOIN [ARM_CORE]..[A_CollectionItem] i on i.CollectionID = c.CollectionID where i.ItemID = a.ApplicationID and cc.CLASSREF = 'ApplicationReadiness' ) as [Status] 
		, a.DeployType
		, CUT_IC.IC as [Installs] 
		from  [ARM_CORE]..[Asset] t 	
		LEFT JOIN [ARM_CORE]..[AppAstToBe] b on b.AssetID = t.AssetID
		LEFT JOIN [ARM_CORE]..[Application] a on a.ApplicationID = b.ApplicationID 
		LEFT JOIN ( 

			SELECT z.ApplicationID, count(distinct z.AssetID) as IC from [ARM_CORE]..[AppAstToBe] z 
			LEFT JOIN [ARM_CORE]..[Asset] y on y.AssetID = z.AssetID 
			where y.[BArea] like  @base and y.Live = 1 group by z.ApplicationID 

		) AS CUT_IC on CUT_IC.ApplicationID = b.ApplicationID 
		where NOT b.[ApplicationID] IS NULL  and IsNull(a.DeployType,'-') <> 'B' and IsNull(a.DeployType,'-') <> 'X' and IsNull(a.Ready,0) = 0 and IsNull(a.Exclude,0) = 0
			and t.[BArea] like @base and t.Live = 1
		order by [Installs] Desc, [App ID]


	) r )  z 
	LEFT JOIN [ARM_CORE]..[s_ApplicationToBeInstallCount] h on h.ApplicationID = z.[App ID] order by z.[Release] desc


	RETURN
END





GO
CREATE FUNCTION [dbo].[AppReleasePath]
(
	@base nvarchar(255) = '%',
	@CurrentCount int = 0
)
RETURNS 
@ParsedList table
(
	[App ID] [nvarchar](500) NULL,
	[Status] [nvarchar](255) NULL,
	[Type] [nvarchar](255) NULL,
	[Installs] [int] NULL,
	[Release] [int] NULL,
	[Max] [int] NULL,
	[Impact] [int] NULL,
	[Total] int
)
AS
BEGIN



	INSERT INTO @ParsedList ([App ID],[Status],[Type],[Installs],[Release],[Impact],[Total]) 
	select top 1 z.*, 100 * z.Installs / h.[Count] as Impact, @CurrentCount + z.Release from (
	 select r.*,
	(
		select count(*) from (
			select b.AssetID, count(b.ApplicationID) AppsNotReady from [ARM_CORE]..[AppAstToBe] b
			LEFT JOIN [ARM_CORE]..[Application] a on a.ApplicationID = b.ApplicationID
			LEFT JOIN [ARM_CORE]..[Asset] t on t.AssetID = b.AssetID
			where IsNull(a.DeployType,'-') <> 'B' and IsNull(a.DeployType,'-') <> 'X' and IsNull(a.Ready,0) = 0 and IsNull(a.Exclude,0) = 0
				and t.[BArea] like  @base  and t.Live = 1 
			group by b.AssetID 
		) q LEFT JOIN (
			select x.AssetID from [ARM_CORE]..[AppAstToBe] x where x.ApplicationID = r.[App ID]
		) s on s.AssetID = q.AssetID 
		where q.AppsNotReady = 1 and NOT s.AssetID IS NULL 
	) as Release 
	from (
	
		select distinct  top 1 b.ApplicationID as [App ID]
		, (SELECT top 1 c.Name from [ARM_CORE]..[A_Collection] c LEFT JOIN [ARM_CORE]..[A_CollectionClass] cc on cc.CollectionClassID = c.CollectionClassID LEFT JOIN [ARM_CORE]..[A_CollectionItem] i on i.CollectionID = c.CollectionID where i.ItemID = a.ApplicationID and cc.CLASSREF = 'ApplicationReadiness' ) as [Status] 
		, a.DeployType
		, CUT_IC.IC as [Installs] 
		from  [ARM_CORE]..[Asset] t 	
		LEFT JOIN [ARM_CORE]..[AppAstToBe] b on b.AssetID = t.AssetID
		LEFT JOIN [ARM_CORE]..[Application] a on a.ApplicationID = b.ApplicationID 
		LEFT JOIN ( 

			SELECT z.ApplicationID, count(distinct z.AssetID) as IC from [ARM_CORE]..[AppAstToBe] z 
			LEFT JOIN [ARM_CORE]..[Asset] y on y.AssetID = z.AssetID 
			where y.[BArea] like  @base and y.Live = 1 group by z.ApplicationID 

		) AS CUT_IC on CUT_IC.ApplicationID = b.ApplicationID 
		where NOT b.[ApplicationID] IS NULL  and IsNull(a.DeployType,'-') <> 'B' and IsNull(a.DeployType,'-') <> 'X' and IsNull(a.Ready,0) = 0 and IsNull(a.Exclude,0) = 0
			and t.[BArea] like @base and t.Live = 1
		order by [Installs] Desc, [App ID]


	) r )  z 
	LEFT JOIN [ARM_CORE]..[s_ApplicationToBeInstallCount] h on h.ApplicationID = z.[App ID] order by z.[Installs] desc


	RETURN
END





GO
