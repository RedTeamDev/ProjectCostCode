CREATE PROCEDURE [dbo].[RTS_ProjectSummary_BudgetTotals_pa]
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
, Estimate DECIMAL(19,9)
, Estimate_band char(1)
, Budget DECIMAL(19,9)
, Budget_band char(1)
, Adjust DECIMAL(19,9)
, Contingency DECIMAL(19,9)
, ActualCost DECIMAL(19,9)
, OpenCost DECIMAL(19,9)
, GoalCost DECIMAL(19,9)
, AtRiskCost DECIMAL(19,9)
, AtRiskCost_band char(1)
, CompleteCost DECIMAL(19,9)
, OverUnder DECIMAL(19,9)
, Notes varchar(max)
, ModStatus varchar(25)
, Show varchar(5)

)

CREATE TABLE #TotalsData
(
  CategoryNumber varchar(5)
, CategoryName varchar(50)
, BudgetCost DECIMAL(19,9)
, ActualCost DECIMAL(19,9)
, OpenCost DECIMAL(19,9)
, AtRiskCost DECIMAL(19,9)
, ContingencyCost DECIMAL(19,9)
, CompleteCost DECIMAL(19,9)
)

CREATE TABLE #OverheadData
(
  CategoryNumber varchar(5)
, CategoryName varchar(50)
, BudgetCost DECIMAL(19,9)
, ActualCost DECIMAL(19,9)
, OpenCost DECIMAL(19,9)
, AtRiskCost DECIMAL(19,9)
, ContingencyCost DECIMAL(19,9)
, CompleteCost DECIMAL(19,9)
)

/******************************************************************************/

SELECT CategoryNumber, CategoryName, 0 as readed
INTO #Categories
FROM CostType
WHERE Status = 'on'

--select * from #Categories

INSERT INTO #AllData
EXEC dbo.BudgetAndActualCosts_pa @CustomerFacilityIDParam, @WorkorderIDParam, @WorkorderModParam

/***********Recalculo de la columna Budget*********************/
UPDATE #AllData SET Budget = isnull(Adjust,Estimate)
/**************************************************************/

SELECT DISTINCT WorkorderID, WorkorderMod, 0 AS readed
INTO #ChangeOrds
FROM #AllData


DECLARE @WorkorderID varchar(7), @WorkorderMod char(2)
DECLARE @LaborRate DECIMAL(19,9), @MaterialRate DECIMAL(19,9), @SubcontractRate DECIMAL(19,9), @EquipmentRate DECIMAL(19,9)

WHILE EXISTS (SELECT TOP 1 * FROM #ChangeOrds WHERE readed = 0)
begin
	SELECT TOP 1 @WorkorderID = WorkorderID, @WorkorderMod = WorkorderMod 
	FROM #ChangeOrds 
	WHERE readed = 0

	SELECT @LaborRate = isnull(LAohRate,0)
	, @MaterialRate = isnull(MAohRate,0)
	, @SubcontractRate = isnull(SUohRate,0)
	, @EquipmentRate = isnull(EQohRate,0)
	FROM Workorders
	WHERE WorkorderID = @WorkorderID AND WorkorderMod = @WorkorderMod

	INSERT INTO #OverheadData
	SELECT null as CategoryNumber
	, null as CategoryName
	, CASE CategoryName
		WHEN 'Labor' THEN Budget * @LaborRate
		WHEN 'Material' THEN Budget * @MaterialRate
		WHEN 'Subcontract' THEN Budget * @SubcontractRate
		WHEN 'Equipment' THEN Budget * @EquipmentRate
	  END AS BudgetCost
	, CASE CategoryName
		WHEN 'Labor' THEN ActualCost * @LaborRate
		WHEN 'Material' THEN ActualCost * @MaterialRate
		WHEN 'Subcontract' THEN ActualCost * @SubcontractRate
		WHEN 'Equipment' THEN ActualCost * @EquipmentRate
	  END AS ActualCost
	, CASE CategoryName
		WHEN 'Labor' THEN OpenCost * @LaborRate
		WHEN 'Material' THEN OpenCost * @MaterialRate
		WHEN 'Subcontract' THEN OpenCost * @SubcontractRate
		WHEN 'Equipment' THEN OpenCost * @EquipmentRate
	  END AS OpenCost
	, CASE
		WHEN CategoryName = 'Labor' AND ModStatus = 'Authorized' THEN AtRiskCost * @LaborRate
		WHEN CategoryName = 'Material' AND ModStatus = 'Authorized' THEN AtRiskCost * @MaterialRate
		WHEN CategoryName = 'Subcontract' AND ModStatus = 'Authorized' THEN AtRiskCost * @SubcontractRate
		WHEN CategoryName = 'Equipment' AND ModStatus = 'Authorized' THEN AtRiskCost * @EquipmentRate
		ELSE 0
	  END AS AtRiskCost
	, CASE CategoryName
		WHEN 'Labor' THEN Contingency * @LaborRate
		WHEN 'Material' THEN Contingency * @MaterialRate
		WHEN 'Subcontract' THEN Contingency * @SubcontractRate
		WHEN 'Equipment' THEN Contingency * @EquipmentRate
	  END AS ContingencyCost
	, CASE CategoryName
		WHEN 'Labor' THEN CompleteCost * @LaborRate
		WHEN 'Material' THEN CompleteCost * @MaterialRate
		WHEN 'Subcontract' THEN CompleteCost * @SubcontractRate
		WHEN 'Equipment' THEN CompleteCost * @EquipmentRate
	  END AS CompleteCost
	FROM #AllData 
	WHERE WorkorderMod = @WorkorderMod

	UPDATE #ChangeOrds SET readed = 1 WHERE WorkorderMod = @WorkorderMod
end


DECLARE @CategoryNumber varchar(5), @CategoryName varchar(50)

WHILE EXISTS (SELECT TOP 1 CategoryName FROM #Categories WHERE readed = 0)
begin
	SELECT TOP 1 @CategoryNumber = CategoryNumber, @CategoryName = CategoryName FROM #Categories WHERE readed = 0

	INSERT INTO #TotalsData
	SELECT @CategoryNumber
	, @CategoryName
	, isnull(SUM(isnull(Budget,0)),0) as BudgetCost
	, isnull(SUM(isnull(ActualCost,0)),0) as ActualCos
	, isnull(SUM(isnull(OpenCost,0)),0) as OpenCost
	, isnull(SUM(CASE WHEN ModStatus = 'Authorized' THEN isnull(AtRiskCost,0) ELSE 0 END),0) as AtRiskCost
	, isnull(SUM(isnull(Contingency,0)),0) as ContingencyCost
	, isnull(SUM(isnull(CompleteCost,0)),0) as CompleteCost
	FROM #AllData
	WHERE CategoryNumber = @CategoryNumber

	UPDATE #Categories SET readed = 1 WHERE CategoryNumber = @CategoryNumber
end


SELECT * FROM #TotalsData
UNION
SELECT 'Z99' as CategoryNumber
, 'Overhead' as CategoruName
, isnull(SUM(isnull(BudgetCost,0)),0) as BudgetCost
, isnull(SUM(isnull(ActualCost,0)),0) as ActualCost
, isnull(SUM(isnull(OpenCost,0)),0) as OpenCost
, isnull(SUM(isnull(AtRiskCost,0)),0) as AtRiskCost
, isnull(SUM(isnull(ContingencyCost,0)),0) as ContingencyCost
, isnull(SUM(isnull(CompleteCost,0)),0) as CompleteCost
FROM #OverheadData

DROP TABLE #Categories
DROP TABLE #AllData
DROP TABLE #TotalsData
DROP TABLE #OverheadData
DROP TABLE #ChangeOrds

SET NOCOUNT OFF

GO