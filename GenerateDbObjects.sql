/*
	GenerateDbObjects.sql
	William T Jones - http://bitbucket.org/wtjones
	
	Creates a database named LotsOfStuff with a configurable amount of views, procs and tables. 
	Original purpose is to test the speed of schema versioning tools.
*/

use master
go

IF (SELECT count(*) from sys.databases where name = 'lotsofstuff') > 0 
BEGIN
	alter database LotsOfStuff set single_user with rollback immediate
	drop database lotsofstuff
END
go

CREATE database LotsOfStuff
go
use LotsOfStuff
go


Declare 
	@numViews int
	,@numTables int
	,@numProcs int	
	,@desiredCharsInView int
	,@desiredCharsInProc int
	,@desiredCharsInTrigger int	
	,@viewBodyStatementText varchar(max)
	,@procBodyStatementText varchar(max)
	,@triggerBodyStatementText varchar(max)
	,@tableColumns varchar(max)
	,@objectCount int
	,@objectName varchar(max)
	,@sql varchar(max)
	,@dropSql varchar(max)
	,@i int
	
	
set @numViews = 40
SET @numProcs = 40
set @numTables = 40
set @desiredCharsInView = 1000	
set @desiredCharsInProc = 1000
SET @desiredCharsInTrigger = 420

	
set @viewBodyStatementText = 'select Id = NewID(), TextStuff = ''Some Text output column'', SomeNumber = number from master.dbo.spt_values where type=''P'''
SET @triggerBodyStatementText = 'select * from inserted'
set @procBodyStatementText = @viewBodyStatementText
SET @tableColumns = '
Id int primary key clustered
,ColumnA int not null default(100000)
,ColumnB int not null default(100000)
,ColumnC int not null default(100000)
,ColumnD int not null default(100000)
,ColumnE int not null default(100000)
,ColumnF int not null default(100000)
,ColumnG int not null default(100000)
,ColumnH int not null default(100000)
,ColumnI int not null default(100000)
,ColumnJ int not null default(100000)
,ColumnK varchar(40) not null default(''AAAAAAAA'')
,ColumnL varchar(40) not null default(''AAAAAAAA'')
,ColumnM varchar(40) not null default(''AAAAAAAA'')
,ColumnN varchar(40) not null default(''AAAAAAAA'')
,ColumnO varchar(40) not null default(''AAAAAAAA'')
,ColumnP varchar(40) not null default(''AAAAAAAA'')
,ColumnQ varchar(40) not null default(''AAAAAAAA'')'

	
--	
-- Create views	
--

set @objectCount=0

while (@objectCount < @numViews)
BEGIN
	set @objectName = 'dbo.GeneratedView_' + right('000000' + convert(varchar,@objectCount + 1), 6)
	set @sql = 'create view ' + @objectName + ' as' + char(13) + char(10)
	set @i = 0
	
	while (len(@sql) < @desiredCharsInView)
	BEGIN
		set @sql = @sql + @viewBodyStatementText
		if (len(@sql) < @desiredCharsInView) set @sql = @sql + char(13) + char(10) + 'union all' + char(13) + char(10) 		
	END
	
	set @dropSql = 'if object_id(''' + @objectName + ''') is not null drop view ' + @objectName
	exec (@dropSql)
	EXEC (@sql)
	set @objectCount = @objectCount + 1
	
END


-- 
-- create procs
--

set @objectCount=0

while (@objectCount < @numProcs)
BEGIN
	set @objectName = 'dbo.GeneratedProc_' + right('000000' + convert(varchar,@objectCount + 1), 6)
	set @sql = 'create proc ' + @objectName + ' as' + char(13) + char(10)
	set @i = 0
	
	while (len(@sql) < @desiredCharsInProc)
	BEGIN
		set @sql = @sql + @procBodyStatementText
		if (len(@sql) < @desiredCharsInProc) set @sql = @sql + char(13) + char(10) + 'union all' + char(13) + char(10) 		
	END	
	
	set @dropSql = 'if object_id(''' + @objectName + ''') is not null drop proc ' + @objectName
	exec (@dropSql)
	EXEC (@sql)
	set @objectCount = @objectCount + 1
	
END

	
--	
-- Create tables
--

set @objectCount=0

while (@objectCount < @numTables)
BEGIN
	set @objectName = 'dbo.GeneratedTable_' + right('000000' + convert(varchar,@objectCount + 1), 6)
	set @sql = 'create table ' + @objectName + ' ( ' + @tableColumns + ' )  ' + char(13) + char(10)
	set @dropSql = 'if object_id(''' + @objectName + ''') is not null drop table ' + @objectName
	exec (@dropSql)
	EXEC (@sql)	
	
	-- add a trigger
	set @sql = 'create trigger Trig_' + replace(convert(varchar(max),newid()), '-', '') + ' on ' + @objectName + ' for update as '
	while (len(@sql) < @desiredCharsInTrigger)
	BEGIN
		set @sql = @sql + @triggerBodyStatementText
		if(len(@sql) < @desiredCharsInTrigger) set @sql = @sql + char(13) + char(10) + 'union all' + char(13) + char(10)
	end
	exec (@sql)	
	
	set @objectCount = @objectCount + 1
	
END


-- Display totals

SELECT 
	ObjectType = case WHEN grouping(o.type_desc) = 1 then 'Grand total:' ELSE o.type_desc end
	,NumObjects = count(*)
	,TotalChars = sum(len(definition)) 	
from sys.sql_modules m
	JOIN sys.objects o ON o.object_id = m.object_id
GROUP by o.type_desc
WITH rollup
order by grouping(o.type_desc) 
