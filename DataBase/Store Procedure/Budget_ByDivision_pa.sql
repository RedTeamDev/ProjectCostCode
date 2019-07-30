CREATE PROCEDURE [dbo].[Budget_ByDivision_pa]
	@CustomerFacilityIDParam varchar(5)
,	@WorkorderIDParam varchar(7)
,	@WorkorderModParam char(2) = null
,	@rollTypeFlag int = 0

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
, Estimate DECIMAL(19,8)
, Estimate_band char(1)
, Budget DECIMAL(19,8)
, Budget_band char(1)
, Adjust DECIMAL(19,8)
, Contingency DECIMAL(19,8)
, ActualCost DECIMAL(19,8)
, OpenCost DECIMAL(19,8)
, GoalCost DECIMAL(19,8)
, AtRiskCost DECIMAL(19,8)
, AtRiskCost_band char(1)
, CompleteCost DECIMAL(19,8)
, OverUnder DECIMAL(19,8)
, Notes varchar(max)
, ModStatus varchar(25)
, Show varchar(5)
)

CREATE TABLE #AllDataFinal
(
  WorkorderID varchar(7)
, WorkorderMod char(2)
, CategoryName varchar(50)
, CategoryNumber varchar(5)
, AssemblyNumber varchar(25)
, ItemName varchar(100)
, AssemblyDescription varchar(200)
, Estimate DECIMAL(19,8)
, Estimate_band char(1)
, Budget DECIMAL(19,8)
, Budget_band char(1)
, Adjust DECIMAL(19,8)
, Contingency DECIMAL(19,8)
, ActualCost DECIMAL(19,8)
, OpenCost DECIMAL(19,8)
, GoalCost DECIMAL(19,8)
, AtRiskCost DECIMAL(19,8)
, AtRiskCost_band char(1)
, CompleteCost DECIMAL(19,8)
, OverUnder DECIMAL(19,8)
, Notes varchar(max)
, ModStatus varchar(25)
, Show varchar(5)
, DivID varchar(20)
)


CREATE TABLE #AllDataDiv
(
  WorkorderID varchar(7)
, WorkorderMod char(2)
, CategoryName varchar(50)
, CategoryNumber varchar(5)
, AssemblyNumber varchar(25)
, ItemName varchar(100)
, AssemblyDescription varchar(200)
, Estimate DECIMAL(19,8)
, Estimate_band char(1)
, Budget DECIMAL(19,8)
, Budget_band char(1)
, Adjust DECIMAL(19,8)
, Contingency DECIMAL(19,8)
, ActualCost DECIMAL(19,8)
, OpenCost DECIMAL(19,8)
, GoalCost DECIMAL(19,8)
, AtRiskCost DECIMAL(19,8)
, AtRiskCost_band char(1)
, CompleteCost DECIMAL(19,8)
, OverUnder DECIMAL(19,8)
, Notes varchar(max)
, ModStatus varchar(25)
, Show varchar(5)
, DivID varchar(20)
, Division varchar(100)
)

CREATE TABLE #TotalsAux
(
  WorkorderID varchar(7)
, WorkorderMod char(2)
, CategoryName varchar(50)
, CategoryNumber varchar(5)
, AssemblyNumber varchar(25)
, ItemName varchar(max)
, AssemblyDescription varchar(max)
, Estimate DECIMAL(19,8)
, Estimate_band char(1)
, Budget DECIMAL(19,8)
, Budget_band char(1)
, Adjust DECIMAL(19,8)
, Contingency DECIMAL(19,8)
, ActualCost DECIMAL(19,8)
, OpenCost DECIMAL(19,8)
, GoalCost DECIMAL(19,8)
, AtRiskCost DECIMAL(19,8)
, AtRiskCost_band char(1)
, CompleteCost DECIMAL(19,8)
, OverUnder DECIMAL(19,8)
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
, Estimate DECIMAL(19,8)
, Estimate_band char(1)
, Budget DECIMAL(19,8)
, Budget_band char(1)
, Adjust DECIMAL(19,8)
, Contingency DECIMAL(19,8)
, ActualCost DECIMAL(19,8)
, OpenCost DECIMAL(19,8)
, GoalCost DECIMAL(19,8)
, AtRiskCost DECIMAL(19,8)
, AtRiskCost_band char(1)
, CompleteCost DECIMAL(19,8)
, OverUnder DECIMAL(19,8)
, Notes varchar(max)
, ModStatus varchar(25)
, Show varchar(5)
)

CREATE TABLE #OverheadData
(
  WorkorderID varchar(7)
, WorkorderMod char(2)
, CategoryName varchar(50)
, CategoryNumber varchar(5)
, AssemblyNumber varchar(25)
, ItemName varchar(100)
, AssemblyDescription varchar(200)
, Estimate DECIMAL(19,8)
, Estimate_band char(1)
, Budget DECIMAL(19,8)
, Budget_band char(1)
, Adjust DECIMAL(19,8)
, Contingency DECIMAL(19,8)
, ActualCost DECIMAL(19,8)
, OpenCost DECIMAL(19,8)
, GoalCost DECIMAL(19,8)
, AtRiskCost DECIMAL(19,8)
, AtRiskCost_band char(1)
, CompleteCost DECIMAL(19,8)
, OverUnder DECIMAL(19,8)
, Notes varchar(max)
, ModStatus varchar(25)
, Show varchar(5)
)

CREATE TABLE #TotalDirectData
(
  WorkorderID varchar(7)
, WorkorderMod char(2)
, CategoryName varchar(50)
, CategoryNumber varchar(5)
, AssemblyNumber varchar(25)
, ItemName varchar(100)
, AssemblyDescription varchar(200)
, Estimate DECIMAL(19,8)
, Estimate_band char(1)
, Budget DECIMAL(19,8)
, Budget_band char(1)
, Adjust DECIMAL(19,8)
, Contingency DECIMAL(19,8)
, ActualCost DECIMAL(19,8)
, OpenCost DECIMAL(19,8)
, GoalCost DECIMAL(19,8)
, AtRiskCost DECIMAL(19,8)
, AtRiskCost_band char(1)
, CompleteCost DECIMAL(19,8)
, OverUnder DECIMAL(19,8)
, Notes varchar(max)
, ModStatus varchar(25)
, Show varchar(5)
)

/******************************************************************************/

INSERT INTO #AllData
EXEC dbo.BudgetAndActualCosts_pa @CustomerFacilityIDParam, @WorkorderIDParam, @WorkorderModParam

--select * from #AllData

/******************************************************************************/

SELECT DISTINCT WorkorderID, WorkorderMod, 0 AS readed
INTO #ChangeOrds
FROM #AllData

DECLARE @WorkorderID varchar(7), @WorkorderMod char(2)
DECLARE @LaborRate DECIMAL(19,8), @MaterialRate DECIMAL(19,8), @SubcontractRate DECIMAL(19,8), @EquipmentRate DECIMAL(19,8)

WHILE EXISTS (SELECT TOP 1 * FROM #ChangeOrds WHERE readed = 0)
BEGIN

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
	SELECT WorkorderID
	, WorkorderMod
	, CategoryName as CategoryName
	, CategoryNumber as CategoryNumber
	, AssemblyNumber as AssemblyNumber
	, null as ItemName
	, null as AssemblyDescription
	, CASE CategoryName
		WHEN 'Labor' THEN Estimate * @LaborRate
		WHEN 'Material' THEN Estimate * @MaterialRate
		WHEN 'Subcontract' THEN Estimate * @SubcontractRate
		WHEN 'Equipment' THEN Estimate * @EquipmentRate
	  END AS Estimate
	, null as Estimate_band
	, CASE CategoryName
		WHEN 'Labor' THEN Budget * @LaborRate
		WHEN 'Material' THEN Budget * @MaterialRate
		WHEN 'Subcontract' THEN Budget * @SubcontractRate
		WHEN 'Equipment' THEN Budget * @EquipmentRate
	  END AS Budget
	, null as Budget_band
	, CASE CategoryName
		WHEN 'Labor' THEN Adjust * @LaborRate
		WHEN 'Material' THEN Adjust * @MaterialRate
		WHEN 'Subcontract' THEN Adjust * @SubcontractRate
		WHEN 'Equipment' THEN Adjust * @EquipmentRate
	  END AS Adjust
	, CASE CategoryName
		WHEN 'Labor' THEN Contingency * @LaborRate
		WHEN 'Material' THEN Contingency * @MaterialRate
		WHEN 'Subcontract' THEN Contingency * @SubcontractRate
		WHEN 'Equipment' THEN Contingency * @EquipmentRate
	  END AS Contingency
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
	, CASE CategoryName
		WHEN 'Labor' THEN GoalCost * @LaborRate
		WHEN 'Material' THEN GoalCost * @MaterialRate
		WHEN 'Subcontract' THEN GoalCost * @SubcontractRate
		WHEN 'Equipment' THEN GoalCost * @EquipmentRate
	  END AS GoalCost
	, CASE
		WHEN CategoryName = 'Labor' AND ModStatus = 'Authorized' THEN AtRiskCost * @LaborRate
		WHEN CategoryName = 'Material' AND ModStatus = 'Authorized' THEN AtRiskCost * @MaterialRate
		WHEN CategoryName = 'Subcontract' AND ModStatus = 'Authorized' THEN AtRiskCost * @SubcontractRate
		WHEN CategoryName = 'Equipment' AND ModStatus = 'Authorized' THEN isnull(AtRiskCost,0) * @EquipmentRate
		ELSE 0
	  END AS AtRiskCost
	, null as AtRiskCost_band
	, CASE CategoryName
		WHEN 'Labor' THEN CompleteCost * @LaborRate
		WHEN 'Material' THEN CompleteCost * @MaterialRate
		WHEN 'Subcontract' THEN CompleteCost * @SubcontractRate
		WHEN 'Equipment' THEN CompleteCost * @EquipmentRate
	  END AS CompleteCost
	, CASE CategoryName
		WHEN 'Labor' THEN OverUnder * @LaborRate
		WHEN 'Material' THEN OverUnder * @MaterialRate
		WHEN 'Subcontract' THEN OverUnder * @SubcontractRate
		WHEN 'Equipment' THEN OverUnder * @EquipmentRate
	  END AS OverUnder
	, null as Notes
	, null as ModStatus
	, null as Show
	FROM #AllData t
	WHERE t.WorkorderMod = @WorkorderMod 
	AND (t.CategoryNumber IS NULL OR CategoryNumber COLLATE Modern_Spanish_CI_AS IN (SELECT CategoryNumber FROM CostType WHERE [Status] = 'on'))
	
	INSERT INTO #TotalDirectData
	SELECT WorkorderID as WorkorderID
	, WorkorderMod as WorkorderMod
	, CategoryName as CategoryName
	, CategoryNumber as CategoryNumber
	, AssemblyNumber as AssemblyNumber
	, null as ItemName
	, 'Subtotal:' as AssemblyDescription
	, Estimate as Estimate
	, null as Estimate_band
	, Budget as Budget
	, null as Budget_band
	, Adjust as Adjust
	, Contingency as Contingency
	, ActualCost as ActualCost
	, OpenCost
	, GoalCost as GoalCost
	, CASE WHEN ModStatus = 'Authorized' THEN AtRiskCost ELSE 0 END as AtRiskCost
	, null as AtRiskCost_band
	, CompleteCost as CompleteCost
	, OverUnder as OverUnder
	, null as Notes
	, null as ModStatus
	, 0 as Show
	FROM #AllData t
	WHERE t.WorkorderMod = @WorkorderMod 
	AND (t.CategoryNumber IS NULL OR CategoryNumber COLLATE Modern_Spanish_CI_AS IN (SELECT CategoryNumber FROM CostType WHERE [Status] = 'on'))
	
	/**********************************************************/

	INSERT INTO #ResultData
	SELECT WorkorderID
	, WorkorderMod
	, CategoryName
	, CategoryNumber
	, AssemblyNumber
	, ItemName
	, AssemblyDescription
	, Estimate
	, Estimate_band
	, Budget
	, Budget_band
	, Adjust
	, Contingency
	, ActualCost
	, OpenCost
	, GoalCost
	, AtRiskCost
	, AtRiskCost_band
	, CompleteCost
	, OverUnder
	, Notes
	, ModStatus
	, Show
	FROM #AllData t
	WHERE t.WorkorderMod = @WorkorderMod 
	AND (t.CategoryNumber IS NULL OR CategoryNumber COLLATE Modern_Spanish_CI_AS IN (SELECT CategoryNumber FROM CostType WHERE [Status] = 'on'))
	
	/**********************************************************************************/

	UPDATE #ResultData SET Budget = isnull(Adjust,Estimate)

	/**********************************************************************************/


	UPDATE #ChangeOrds SET readed = 1 WHERE WorkorderMod = @WorkorderMod

END

TRUNCATE TABLE #AllData


/**********************************************************************************/

SELECT null as WorkorderID
, null as WorkorderMod
, null as CategoryName
, null as CategoryNumber
, null as AssemblyNumber
, null as ItemName
, null as AssemblyDescription
, sum(Estimate) as Estimate
, null as Estimate_band
, isnull(sum(Adjust),sum(Estimate)) as Budget  
, null as Budget_band
, sum(Adjust) as Adjust
, sum(Contingency) as Contingency
, sum(ActualCost) as ActualCost
, sum(OpenCost) as OpenCost
, sum(GoalCost) as GoalCost
, sum(AtRiskCost) as AtRiskCost
, null as AtRiskCost_band
, sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost) as CompleteCost
, sum(Budget) - (sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost)) as OverUnder
, null as Notes
, null as ModStatus
, null as Show
INTO #TotalCostData
FROM #OverheadData
GROUP BY WorkorderID
		, CategoryName
		, CategoryNumber
		, AssemblyNumber
		, ItemName
		, AssemblyDescription
		, Estimate_band
		, Budget_band
		, AtRiskCost_band
		, Show

UNION ALL

SELECT null as WorkorderID  
, null as WorkorderMod  
, null as CategoryName  
, null as CategoryNumber  
, null as AssemblyNumber  
, null as ItemName  
, null as AssemblyDescription  
, sum(Estimate) as Estimate  
, null as Estimate_band  
, isnull(sum(Adjust),sum(Estimate)) as Budget  
, null as Budget_band  
, sum(Adjust) as Adjust  
, sum(Contingency) as Contingency  
, sum(ActualCost) as ActualCost  
, sum(OpenCost) as OpenCost
, sum(GoalCost) as GoalCost  
, sum(AtRiskCost) as AtRiskCost  
, null as AtRiskCost_band  
, sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost) as CompleteCost
, sum(Budget) - (sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost)) as OverUnder
, null as Notes  
, null as ModStatus  
, null as Show  
FROM #TotalDirectData
GROUP BY WorkorderID
		, CategoryName
		, CategoryNumber
		, AssemblyNumber
		, ItemName
		, AssemblyDescription
		, Estimate_band
		, Budget_band
		, AtRiskCost_band
		, Show 

/*****************************************************************/

DECLARE @DivID varchar(20)

SELECT DISTINCT c.DivID, 0 as readed 
INTO #Divisions
FROM #ResultData t
INNER JOIN ProjectCostCodes pcc ON pcc.CostCodeNumber = t.AssemblyNumber COLLATE Modern_Spanish_CI_AS AND pcc.WorkorderID = @WorkorderID
INNER JOIN CostCode c ON c.CostCodeUniqueID = pcc.CostCodeUniqueID


--select * from #Divisions
	
WHILE EXISTS (select top 1 * from #Divisions where readed = 0)
BEGIN
	select top 1 @DivID = DivID from #Divisions where readed = 0

	INSERT INTO #AllDataFinal

	SELECT max(t.WorkorderID) as WorkorderID
	, max(WorkorderMod) as WorkorderMod
	, '' as CategoryName
	, '' as CategoryNumber
	, 'Z555555' as AssemblyNumber
	, '' as ItemName
	, 'Subtotal:' as AssemblyDescription
	, sum(Estimate) as Estimate
	, null as Estimate_band
	, sum(Budget) as Budget
	, null as Budget_band
	, sum(Adjust) as Adjust
	, sum(Contingency) as Contingency
	, sum(ActualCost) as ActualCost
	, sum(OpenCost) as OpenCost
	, sum(GoalCost) as GoalCost
	, sum(CASE WHEN ModStatus = 'Authorized' THEN AtRiskCost ELSE 0 END) as AtRiskCost
	, null as AtRiskCost_band
	, sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost) as CompleteCost
	, sum(Budget) - (sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost)) as OverUnder
	, null as Notes
	, null as ModStatus
	, 2 as Show
	, @DivID as DivID
	FROM #ResultData t
	INNER JOIN ProjectCostCodes pcc ON pcc.CostCodeNumber = t.AssemblyNumber COLLATE Modern_Spanish_CI_AS AND pcc.WorkorderID = @WorkorderID
	INNER JOIN CostCode c ON c.CostCodeUniqueID = pcc.CostCodeUniqueID
	WHERE c.DivID = @DivID

	update #Divisions set readed = 1 where DivID = @DivID
END

--select * from #AllDataFinal

/********* DATA PARA CALCULAR LAS DISCREPANCIAS *******/

INSERT INTO #TotalsAux
SELECT 1 as WorkorderID
, null as WorkorderMod
, null as CategoryName
, null as CategoryNumber
, null as AssemblyNumber
, null as ItemName
, 'SubTotals' as AssemblyDescription
, sum(Estimate) as Estimate
, null as Estimate_band
, sum(Budget) as Budget
, null as Budget_band
, sum(Adjust) as Adjust
, sum(Contingency) as Contingency
, sum(ActualCost) as ActualCost
, sum(OpenCost) as OpenCost
, sum(GoalCost) as GoalCost
, sum(AtRiskCost) as AtRiskCost
, null as AtRiskCost_band
, sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost) as CompleteCost
, sum(Budget) - (sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost)) as OverUnder
, min(Notes) as Notes
, min(ModStatus) as ModStatus
, null as Show
FROM #AllDataFinal
WHERE AssemblyDescription = 'Subtotal:'
GROUP BY AssemblyDescription
		
UNION ALL

SELECT 1 as WorkorderID
, null as WorkorderMod
, null as CategoryName
, null as CategoryNumber
, null as AssemblyNumber
, null as ItemName
, 'TotalDirect' as AssemblyDescription
, sum(Estimate) as Estimate
, null as Estimate_band
, isnull(sum(Adjust),sum(Estimate)) as Budget  
, null as Budget_band
, sum(Adjust) as Adjust
, sum(Contingency) as Contingency
, sum(ActualCost) as ActualCost
, sum(OpenCost) as OpenCost
, sum(GoalCost) as GoalCost
, sum(AtRiskCost) as AtRiskCost
, null as AtRiskCost_band
, sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost) as CompleteCost
, isnull(sum(Adjust),sum(Estimate)) - (sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost)) as OverUnder
, min(Notes) as Notes
, min(ModStatus) as ModStatus
, null as Show
FROM #TotalDirectData
GROUP BY AssemblyDescription

/*
select isnull(Adjust,Estimate) - (
	case 
	when OpenCost < 0 then ActualCost + 0 + Contingency + AtRiskCost
	else ActualCost + OpenCost + Contingency + AtRiskCost
	end) as OverUnder
from #TotalDirectData
*/

--select * from #TotalsAux

/*
select 'Z666666' as WorkorderID
, '00' as WorkorderMod
, null as CategoryName
, null as CategoryNumber
, 'Z666666' as AssemblyNumber
, null as ItemName
, 'Adjustments:' as AssemblyDescription
, aux1.Estimate - aux2.Estimate as Estimate
, null as Estimate_band
, aux1.Budget - aux2.Budget as Budget
, null as Budget_band
, aux1.Adjust - aux2.Adjust as Adjust
, aux1.Contingency - aux2.Contingency as Contingency
, aux1.ActualCost - aux2.ActualCost as ActualCost
, aux1.OpenCost - aux2.OpenCost as OpenCost
, aux1.GoalCost - aux2.GoalCost as GoalCost
, aux1.AtRiskCost - aux2.AtRiskCost as AtRiskCost
, null as AtRiskCost_band
, aux1.CompleteCost - aux2.CompleteCost as CompleteCost
, aux1.OverUnder - aux2.OverUnder as OverUnder
, null as Notes
, null as ModStatus
, 3 as Show
from #TotalsAux aux1
inner join (select * from #TotalsAux where AssemblyDescription = 'SubTotals') aux2 on aux2.WorkorderID = aux1.WorkorderID
where aux1.AssemblyDescription = 'TotalDirect'
*/

/********************************************************************/


IF EXISTS (SELECT TOP 1 * FROM #ResultData)
BEGIN

	INSERT INTO #AllDataFinal

	SELECT r.*, c.DivID 
	FROM #ResultData r
	INNER JOIN ProjectCostCodes pcc ON pcc.CostCodeNumber = r.AssemblyNumber COLLATE Modern_Spanish_CI_AS AND pcc.WorkorderID = @WorkorderID
	INNER JOIN CostCode c ON c.CostCodeUniqueID = pcc.CostCodeUniqueID
	
	UNION ALL

	select 'Z666666' as WorkorderID
	, '00' as WorkorderMod
	, '' as CategoryName
	, null as CategoryNumber
	, 'Z666666' as AssemblyNumber
	, null as ItemName
	, 'Adjustments:' as AssemblyDescription
	, aux1.Estimate - aux2.Estimate as Estimate
	, null as Estimate_band
	, aux1.Budget - aux2.Budget as Budget
	, null as Budget_band
	, aux1.Adjust - aux2.Adjust as Adjust
	, aux1.Contingency - aux2.Contingency as Contingency
	, aux1.ActualCost - aux2.ActualCost as ActualCost
	, aux1.OpenCost - aux2.OpenCost as OpenCost
	, aux1.GoalCost - aux2.GoalCost as GoalCost
	, aux1.AtRiskCost - aux2.AtRiskCost as AtRiskCost
	, null as AtRiskCost_band
	, aux1.CompleteCost - aux2.CompleteCost as CompleteCost
	, aux1.OverUnder - aux2.OverUnder as OverUnder
	, null as Notes
	, null as ModStatus
	, 3 as Show
	, 'Z666666' AS DivID
	from #TotalsAux aux1
	inner join (select * from #TotalsAux where AssemblyDescription = 'SubTotals') aux2 on aux2.WorkorderID = aux1.WorkorderID
	where aux1.AssemblyDescription = 'TotalDirect'

	UNION ALL

	SELECT 'Z777777' as WorkorderID
	, '00' as WorkorderMod
	, '' as CategoryName
	, null as CategoryNumber
	, 'Z777777' as AssemblyNumber
	, null as ItemName
	, 'Total Direct:' as AssemblyDescription
	, sum(Estimate) as Estimate
	, null as Estimate_band
	, isnull(sum(Adjust),sum(Estimate)) as Budget  
	, null as Budget_band
	, sum(Adjust) as Adjust
	, sum(Contingency) as Contingency
	, sum(ActualCost) as ActualCost
	, sum(OpenCost) as OpenCost
	, sum(GoalCost) as GoalCost
	, sum(AtRiskCost) as AtRiskCost
	, null as AtRiskCost_band
	, sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost) as CompleteCost
	, sum(Budget) - (sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost)) as OverUnder
	, null as Notes
	, null as ModStatus
	, 4 as Show
	, 'Z777777' as DivID
	FROM #TotalDirectData
	GROUP BY WorkorderID
		, CategoryName
		, CategoryNumber
		, AssemblyNumber
		, ItemName
		, AssemblyDescription
		, Estimate_band
		, Budget_band
		, AtRiskCost_band
		, Show

	UNION ALL

	SELECT 'Z888888' as WorkorderID
	, '00' as WorkorderMod
	, '' as CategoryName
	, null as CategoryNumber
	, 'Z888888' as AssemblyNumber
	, null as ItemName
	, 'Indirect Costs:' as AssemblyDescription
	, sum(Estimate) as Estimate
	, null as Estimate_band
	, isnull(sum(Adjust),sum(Estimate)) as Budget  
	, null as Budget_band
	, sum(Adjust) as Adjust
	, sum(Contingency) as Contingency
	, sum(ActualCost) as ActualCost
	, sum(OpenCost) as OpenCost
	, sum(GoalCost) as GoalCost
	, sum(AtRiskCost) as AtRiskCost
	, null as AtRiskCost_band
	, sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost) as CompleteCost
	, sum(Budget) - (sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost)) as OverUnder
	, null as Notes
	, null as ModStatus
	, 5 as Show
	, 'Z888888' as DivID
	FROM #OverheadData
	GROUP BY WorkorderID
		, CategoryName
		, CategoryNumber
		, AssemblyNumber
		, ItemName
		, AssemblyDescription
		, Estimate_band
		, Budget_band
		, AtRiskCost_band
		, Show

	UNION ALL

	SELECT 'Z999999' as WorkorderID
	, '00' as WorkorderMod
	, '' as CategoryName
	, null as CategoryNumber
	, 'Z999999' as AssemblyNumber
	, null as ItemName
	, 'Total Costs:' as AssemblyDescription
	, sum(Estimate) as Estimate
	, null as Estimate_band
	, sum(Budget) as Budget
	, null as Budget_band
	, sum(Adjust) as Adjust
	, sum(Contingency) as Contingency
	, sum(ActualCost) as ActualCost
	, sum(OpenCost) as OpenCost
	, sum(GoalCost) as GoalCost
	, sum(AtRiskCost) as AtRiskCost
	, null as AtRiskCost_band
	, sum(CompleteCost) as CompleteCost
	, sum(OverUnder) as OverUnder
	, null as Notes
	, null as ModStatus
	, 6 as Show
	, 'Z999999' as DivID
	FROM #TotalCostData
	
	/***********************************************************************/
	
	INSERT INTO #AllDataDiv
	SELECT t.*
	, d.DivisionID + ' - ' + d.DivisionName as Division
	FROM #AllDataFinal t
	INNER JOIN Division d ON d.DivisionID = t.DivID collate Modern_Spanish_CI_AS
	
	UNION ALL

	SELECT t.*
	, null as Division
	FROM #AllDataFinal t
	WHERE t.CategoryName = '' AND LEFT(t.DivID,1) = 'Z'


	SELECT DivID
	, Division
	, WorkorderID
	, min(WorkorderMod) as WorkorderMod
	, CategoryName
	, CategoryNumber
	, AssemblyNumber
	, ItemName
	, AssemblyDescription
	, sum(Estimate) as Estimate
	, Estimate_band
	, sum(Budget) as Budget
	, Budget_band
	, sum(Adjust) as Adjust
	, sum(Contingency) as Contingency
	, sum(ActualCost) as ActualCost
	, sum(OpenCost) as OpenCost
	, sum(GoalCost) as GoalCost
	, sum(AtRiskCost) as AtRiskCost
	, AtRiskCost_band
	, sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost) as CompleteCost
	, sum(Budget) - (sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost)) as OverUnder
	, min(Notes) as Notes
	, min(ModStatus) as ModStatus
	, Show
	, (select top 1 isnull(ba.LA_GoalAmount,0) from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_GoalAmount
	, (select top 1 isnull(ba.MA_GoalAmount,0) from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_GoalAmount
	, (select top 1 isnull(ba.SU_GoalAmount,0) from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_GoalAmount
	, (select top 1 isnull(ba.EQ_GoalAmount,0) from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_GoalAmount
	, (select top 1 ba.LA_GoalDate from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_GoalDate
	, (select top 1 ba.MA_GoalDate from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_GoalDate
	, (select top 1 ba.SU_GoalDate from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_GoalDate
	, (select top 1 ba.EQ_GoalDate from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_GoalDate
	, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.LA_Responsible where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_Responsible
	, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.MA_Responsible where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_Responsible
	, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.SU_Responsible where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_Responsible
	, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.EQ_Responsible where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_Responsible
	, (select top 1 ba.LA_Notes from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_Notes	
	, (select top 1 ba.MA_Notes from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_Notes
	, (select top 1 ba.SU_Notes from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_Notes
	, (select top 1 ba.EQ_Notes from BuyoutAssemblies ba where ba.DivID = a.DivID collate Modern_Spanish_CI_AS and ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and ba.AssemblyNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_Notes
	FROM #AllDataDiv a
	GROUP BY DivID
	, Division
	, WorkorderID
	, CategoryName
	, CategoryNumber
	, AssemblyNumber
	, ItemName
	, AssemblyDescription
	, Estimate_band
	, Budget_band
	, AtRiskCost_band
	, Show		
	ORDER BY DivID, AssemblyNumber, CategoryNumber, Show


END

ELSE

	SELECT * FROM #ResultData

DROP TABLE #AllData
DROP TABLE #ChangeOrds
DROP TABLE #ResultData
DROP TABLE #TotalDirectData
DROP TABLE #OverheadData
DROP TABLE #TotalCostData
DROP TABLE #Divisions
DROP TABLE #AllDataDiv
DROP TABLE #AllDataFinal

SET NOCOUNT OFF

GO