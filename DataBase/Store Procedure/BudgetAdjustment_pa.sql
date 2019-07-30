CREATE PROCEDURE [dbo].[BudgetAdjustment_pa]
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
, AssemblyDescription varchar(200)
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
  WorkorderID varchar(7)
, WorkorderMod char(2)
, CategoryName varchar(50)
, CategoryNumber varchar(5)
, AssemblyNumber varchar(25)
, ItemName varchar(100)
, AssemblyDescription varchar(200)
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

DECLARE @Delete_AtRisk_cero varchar(3)
DECLARE @SQLquery varchar(1000)

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

	INSERT INTO #ResultData
	SELECT * FROM #AllData WHERE WorkorderMod = @WorkorderMod
	
	UPDATE #ResultData 
	SET Budget = isnull(Adjust,Estimate)
	, OverUnder = isnull(Adjust,Estimate) - CompleteCost


	UPDATE #ChangeOrds SET readed = 1 WHERE WorkorderMod = @WorkorderMod
end


IF EXISTS (SELECT TOP 1 * FROM #ResultData)
BEGIN

set @SQLquery = 'SELECT WorkorderID ' +
', WorkorderMod ' +
', CategoryName ' +
', CategoryNumber ' +
', AssemblyNumber ' +
', ItemName ' +
', AssemblyDescription ' +
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
', MAX(Notes) AS Notes ' +
', ModStatus ' +
', Show ' +
' FROM #ResultData ' +   
' WHERE 1 = 1 '

if @MAstatus = 'off'
	set @SQLquery = @SQLquery + ' AND CategoryName not in (''Material'') '
if @LAstatus = 'off'
	set @SQLquery = @SQLquery + ' AND CategoryName not in (''LAbor'') '
if @SUstatus = 'off'
	set @SQLquery = @SQLquery + ' AND CategoryName not in (''Subcontract'') '
if @EQstatus = 'off'
	set @SQLquery = @SQLquery + ' AND CategoryName not in (''Equipment'') '

set @SQLquery = @SQLquery + 'GROUP BY WorkorderID ' +
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
'ORDER BY WorkorderID, WorkorderMod, AssemblyNumber, Show'

exec (@SQLquery)

END

ELSE

	SELECT * FROM #ResultData


DROP TABLE #AllData
DROP TABLE #ChangeOrds
DROP TABLE #ResultData
SET NOCOUNT OFF


GO