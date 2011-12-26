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
	,@numStatementsInView int
	,@numStatementsInProc int
	,@viewBodyStatementText varchar(max)
	,@procBodyStatementText varchar(max)
	,@tableColumns varchar(max)
	,@objectCount int
	,@objectName varchar(max)
	,@sql varchar(max)
	,@dropSql varchar(max)
	,@i int
	
	
set @numViews = 4000
SET @numProcs = 2000
set @numStatementsInView = 25
set @numStatementsInProc = 50
set @numTables = 4000
	

--set @numViews = 30
--SET @numProcs = 20
--set @numStatementsInView = 25
--set @numStatementsInProc = 50
--set @numTables = 4
	
set @viewBodyStatementText = 'select Id = NewID(), TextStuff = ''Some Text output column'', SomeNumber = number from master.dbo.spt_values where type=''P'''
set @procBodyStatementText = @viewBodyStatementText
SET @tableColumns = '
Id int primary key clustered
,ColumnA int
,ColumnB int
,ColumnC int
,ColumnD int
,ColumnE int
,ColumnF int
,ColumnG int
,ColumnH int
,ColumnI int
,ColumnJ int
,ColumnK varchar(40)
,ColumnL varchar(40)
,ColumnM varchar(40)
,ColumnN varchar(40)
,ColumnO varchar(40)
,ColumnP varchar(40)
,ColumnQ varchar(40)'

	
--	
-- Create views	
--

set @objectCount=0

while (@objectCount < @numViews)
BEGIN
	set @objectName = 'dbo.GeneratedView_' + right('000000' + convert(varchar,@objectCount + 1), 6)
	set @sql = 'create view ' + @objectName + ' as' + char(13) + char(10)
	set @i = 0
	while (@i < @numStatementsInView)
	BEGIN
		set @sql = @sql + @viewBodyStatementText
		if (@i < @numStatementsInView - 1) set @sql = @sql + char(13) + char(10) + 'union all' + char(13) + char(10) 
		set @i = @i + 1
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
	while (@i < @numStatementsInProc)
	BEGIN
		set @sql = @sql + @procBodyStatementText
		if (@i < @numStatementsInProc - 1) set @sql = @sql + char(13) + char(10) + 'union all' + char(13) + char(10) 
		set @i = @i + 1
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
	set @objectCount = @objectCount + 1
	
END


-- Display totals

SELECT ObjectType = o.type, TotalLinesOfText = count(len(definition)) from sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
GROUP by o.type

SELECT ObjectType = type_desc, NumObjects = count(*) from sys.objects where type in ('V', 'P', 'U') GROUP BY type_desc

