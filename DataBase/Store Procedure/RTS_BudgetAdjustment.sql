
CREATE PROCEDURE [dbo].[RTS_BudgetAdjustment]
	@CustomerFacilityIDParam varchar(5)
,	@WorkorderIDParam varchar(7)
,	@WorkorderModParam char(2) = null 

AS

SET NOCOUNT ON


CREATE TABLE #AllData
(
  WorkorderID varchar(7)
, WorkorderMod char(2)
, CategoryName varchar(50)
, CategoryNumber varchar(5)
, AssemblyNumber varchar(25)
, ItemName varchar(100)
, AssemblyDescription varchar(1000)
, Estimate decimal(18,2)
, Estimate_band char(1)
, Budget decimal(18,2)
, Budget_band char(1)
, Adjust decimal(18,2)
, Contingency decimal(18,2)
, ActualCost decimal(18,2)
, OpenCost decimal(18,2)
, GoalCost decimal(18,2)
, AtRiskCost decimal(18,2)
, AtRiskCost_band char(1)
, CompleteCost decimal(18,2)
, OverUnder decimal(18,2)
, Notes varchar(max)
, ModStatus varchar(25)
, Show varchar(5)
)

CREATE TABLE #ResultData
(
  ID int identity not null
, WorkorderID varchar(7)
, WorkorderMod char(2)
, CategoryName varchar(50)
, CategoryNumber varchar(5)
, AssemblyNumber varchar(25)
, ItemName varchar(100)
, AssemblyDescription varchar(1000)
, Estimate decimal(18,2)
, Estimate_band char(1)
, Budget decimal(18,2)
, Budget_band char(1)
, Adjust decimal(18,2)
, Contingency decimal(18,2)
, ActualCost decimal(18,2)
, OpenCost decimal(18,2)
, GoalCost decimal(18,2)
, AtRiskCost decimal(18,2)
, AtRiskCost_band char(1)
, CompleteCost decimal(18,2)
, OverUnder decimal(18,2)
, Notes varchar(max)
, ModStatus varchar(25)
, Show varchar(5)
, AdjustID int
, MetadataFlag int
)

DECLARE @Delete_AtRisk_cero varchar(3)
DECLARE @SQLquery varchar(2000)

DECLARE @MAstatus varchar(3), @LAstatus varchar(3), @SUstatus varchar(3), @EQstatus varchar(3)

select @MAstatus = [Status] from CostType where CategoryName = 'Material'
select @LAstatus = [Status] from CostType where CategoryName = 'Labor'
select @SUstatus = [Status] from CostType where CategoryName = 'Subcontract'
select @EQstatus = [Status] from CostType where CategoryName = 'Equipment'

SET @Delete_AtRisk_cero = 'no'

INSERT INTO #AllData
EXEC dbo.BudgetAndActualCosts_pa @CustomerFacilityIDParam, @WorkorderIDParam, @WorkorderModParam, @Delete_AtRisk_cero

DELETE #AllData WHERE ModStatus <> 'authorized'
 
SELECT DISTINCT WorkorderID, WorkorderMod, 0 AS readed
INTO #ChangeOrds
FROM #AllData
WHERE ModStatus = 'authorized'

DECLARE @WorkorderID varchar(7), @WorkorderMod char(2)

WHILE EXISTS (SELECT TOP 1 * FROM #ChangeOrds WHERE readed = 0)
begin
	SELECT TOP 1 @WorkorderID = WorkorderID, @WorkorderMod = WorkorderMod 
	FROM #ChangeOrds 
	WHERE readed = 0

	/**********************************************************/

	INSERT INTO #ResultData
	SELECT *, 0 as AdjustID, 0 as MetadataFlag 
	FROM #AllData 
	WHERE WorkorderMod = @WorkorderMod
	
	UPDATE #ResultData 
	SET Budget = isnull(Adjust,Estimate)
	, OverUnder = isnull(Adjust,Estimate) - CompleteCost


	/**************************************************************/

	UPDATE #ChangeOrds SET readed = 1 WHERE WorkorderMod = @WorkorderMod
end

/**********************************************************************************/

IF EXISTS (SELECT TOP 1 * FROM #ResultData)
BEGIN

set @SQLquery = 'SELECT ID as DT_RowId ' +
' , WorkorderID ' +
', WorkorderMod ' +
', WorkorderMod as Scope ' +
', CategoryName as Category ' +
', CategoryName ' +
', CategoryNumber ' +
', AssemblyNumber as CostCodeID ' +
', AssemblyNumber ' +
', ltrim(rtrim(ItemName)) as ItemName ' +
', ltrim(rtrim(AssemblyDescription)) as AssemblyDescription ' +
', SUM(Estimate) AS Estimate ' +
', Estimate_band ' +
', SUM(Budget) AS Budget ' +
', Budget_band ' +
', SUM(Adjust) AS Adjust ' +
', SUM(Contingency) AS Contingency ' +
', SUM(ActualCost) AS ActualCost ' +
', SUM(OpenCost) AS OpenCost ' +
', SUM(GoalCost) AS GoalCost ' +
', SUM(AtRiskCost) AS AtRiskCost ' +
', AtRiskCost_band ' +
', SUM(CompleteCost) AS CompleteCost ' +
', SUM(OverUnder) AS OverUnder ' +
', MAX(ltrim(rtrim(Notes))) AS Notes ' +
', ModStatus ' +
', Show ' +
', (select top 1 a.AdjustID from Adjustments a where a.WorkorderID = t.WorkorderID collate Modern_Spanish_CI_AS and a.WorkorderMod = t.WorkorderMod collate Modern_Spanish_CI_AS and a.AdjustCostCode = t.AssemblyNumber collate Modern_Spanish_CI_AS and a.AdjustCategory = t.CategoryName collate Modern_Spanish_CI_AS order by a.AdjustID desc) AS AdjustID ' +
', (select count(1) from Adjustments a inner join Metadata m on m.Source = ''Budget'' and m.SourceID = ltrim(a.AdjustID) where a.WorkorderID = t.WorkorderID collate Modern_Spanish_CI_AS and a.WorkorderMod = t.WorkorderMod collate Modern_Spanish_CI_AS and a.AdjustCostCode = t.AssemblyNumber collate Modern_Spanish_CI_AS and a.AdjustCategory = t.CategoryName collate Modern_Spanish_CI_AS) AS MetadataFlag ' +
' FROM #ResultData t ' +   
' WHERE 1 = 1 '

if @MAstatus = 'off'
	set @SQLquery = @SQLquery + ' AND CategoryName not in (''Material'') '
if @LAstatus = 'off'
	set @SQLquery = @SQLquery + ' AND CategoryName not in (''LAbor'') '
if @SUstatus = 'off'
	set @SQLquery = @SQLquery + ' AND CategoryName not in (''Subcontract'') '
if @EQstatus = 'off'
	set @SQLquery = @SQLquery + ' AND CategoryName not in (''Equipment'') '

set @SQLquery = @SQLquery + 'GROUP BY ID, WorkorderID ' +
', WorkorderMod ' +
', CategoryName ' +
', CategoryNumber ' +
', AssemblyNumber ' +
', ItemName ' +
', AssemblyDescription ' +
', Estimate_band ' +
', Budget_band ' +
', AtRiskCost_band ' +
', ModStatus ' +
', Show ' +
'ORDER BY WorkorderMod, AssemblyNumber, CategoryName, Show'

exec (@SQLquery)

END

ELSE

	SELECT * FROM #ResultData


DROP TABLE #AllData
DROP TABLE #ChangeOrds
DROP TABLE #ResultData
SET NOCOUNT OFF

/*******************************************************************************************************************/
GO