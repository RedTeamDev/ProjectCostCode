ALTER PROCEDURE [dbo].[Budget_pa]
  @CustomerFacilityIDParam varchar(5)
, @WorkorderIDParam varchar(7)
, @WorkorderModParam char(2) = null
, @sortBy varchar(15) = 'ChangeOrder'
, @rollTypeFlag int = 0
, @AssemblyNumber varchar(25) = null
, @ShowOnlyTotals varchar(3) = null
, @ShowOnlyAssemblies varchar(3) = null

AS

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

IF @ShowOnlyTotals = 'no'
SET @ShowOnlyTotals = NULL

IF @ShowOnlyAssemblies = 'no'
SET @ShowOnlyAssemblies = NULL

CREATE TABLE #AllData
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
, ProjectCostCodeID int
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
, ProjectCostCodeID int
)

CREATE TABLE #ResultData
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
, ProjectCostCodeID int
)

CREATE TABLE #OverheadData
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

CREATE TABLE #TotalDirectData
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



IF NOT @AssemblyNumber IS NULL
BEGIN
	INSERT INTO #AllData
	EXEC dbo.BudgetAndActualCosts_pa @CustomerFacilityIDParam, @WorkorderIDParam, @WorkorderModParam, 'yes', @AssemblyNumber

END
ELSE
BEGIN
	INSERT INTO #AllData
	EXEC dbo.BudgetAndActualCosts_pa @CustomerFacilityIDParam, @WorkorderIDParam, @WorkorderModParam
END


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
	, 'Overhead' as AssemblyDescription
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
	AND (@ShowOnlyAssemblies IS NULL)

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
	AND (@ShowOnlyAssemblies IS NULL)
	

	IF @sortBy = 'ChangeOrder'
	BEGIN

	INSERT INTO #ResultData
	SELECT * 
	FROM #AllData t
	WHERE t.WorkorderMod = @WorkorderMod 
	AND (t.CategoryNumber IS NULL OR CategoryNumber COLLATE Modern_Spanish_CI_AS IN (SELECT CategoryNumber FROM CostType WHERE [Status] = 'on'))
	
	UNION ALL

	SELECT WorkorderID as WorkorderID
	, WorkorderMod as WorkorderMod
	, null as CategoryName
	, null as CategoryNumber
	, 'Z555555' as AssemblyNumber
	, null as ItemName
	, 'Subtotal:' as AssemblyDescription
	, Estimate as Estimate
	, null as Estimate_band
	, isnull(Adjust,Estimate) as Budget 
	, null as Budget_band
	, Adjust as Adjust
	, Contingency as Contingency
	, ActualCost as ActualCost
	, OpenCost as OpenCost
	, GoalCost as GoalCost
	, CASE WHEN ModStatus = 'Authorized' THEN AtRiskCost ELSE 0 END as AtRiskCost
	, null as AtRiskCost_band
	, CompleteCost as CompleteCost
	, OverUnder as OverUnder
	, null as Notes
	, null as ModStatus
	, 2 as Show
	, ProjectCostCodeID
	FROM #AllData t
	WHERE t.WorkorderMod = @WorkorderMod 
	AND (t.CategoryNumber IS NULL OR CategoryNumber COLLATE Modern_Spanish_CI_AS IN (SELECT CategoryNumber FROM CostType WHERE [Status] = 'on'))
	AND (@ShowOnlyAssemblies IS NULL)

	END

	ELSE

	BEGIN

	INSERT INTO #ResultData
	SELECT * 
	FROM #AllData t
	WHERE t.WorkorderMod = @WorkorderMod 
	AND (t.CategoryNumber IS NULL OR CategoryNumber COLLATE Modern_Spanish_CI_AS IN (SELECT CategoryNumber FROM CostType WHERE [Status] = 'on'))
	
	END

	UPDATE #ChangeOrds SET readed = 1 WHERE WorkorderMod = @WorkorderMod

END

TRUNCATE TABLE #AllData

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
, sum(CompleteCost) as CompleteCost
, sum(OverUnder) as OverUnder
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
, sum(CompleteCost) as CompleteCost
, sum(OverUnder) as OverUnder
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



UPDATE #ResultData SET Budget = isnull(Adjust,Estimate)



/********* DATA PARA CALCULAR LAS DISCREPANCIAS *******/

IF @sortBy = 'ChangeOrder'
BEGIN

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
	, sum(CompleteCost) as CompleteCost
	, sum(OverUnder) as OverUnder
	, min(Notes) as Notes
	, min(ModStatus) as ModStatus
	, null as Show
	, null as ProjectCostCodeID
	FROM #ResultData
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
	, sum(CompleteCost) as CompleteCost
	, sum(OverUnder) as OverUnder
	, min(Notes) as Notes
	, min(ModStatus) as ModStatus
	, null as Show
	, null as ProjectCostCodeID 
	FROM #TotalDirectData
	GROUP BY AssemblyDescription

END

/********************************************************************/


IF EXISTS (SELECT TOP 1 * FROM #ResultData) AND (@ShowOnlyAssemblies IS NULL)
BEGIN

	INSERT INTO #AllData

	SELECT * 
	FROM #ResultData
	
	UNION ALL

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
	, aux1.ProjectCostCodeID as ProjectCostCodeID
	from #TotalsAux aux1
	inner join (select * from #TotalsAux where AssemblyDescription = 'SubTotals') aux2 on aux2.WorkorderID = aux1.WorkorderID
	where aux1.AssemblyDescription = 'TotalDirect'
	
	UNION ALL

	SELECT 'Z777777' as WorkorderID
	, '00' as WorkorderMod
	, null as CategoryName
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
	, sum(CompleteCost) as CompleteCost
	, sum(OverUnder) as OverUnder
	, null as Notes
	, null as ModStatus
	, 4 as Show
	, null as ProjectCostCodeID
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
	, null as CategoryName
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
	, case when sum(OpenCost) < 0 then 0 else sum(OpenCost) end as OpenCost
	, sum(GoalCost) as GoalCost
	, sum(AtRiskCost) as AtRiskCost
	, null as AtRiskCost_band
	, sum(CompleteCost) as CompleteCost
	, sum(OverUnder) as OverUnder
	, null as Notes
	, null as ModStatus
	, 5 as Show
	, null as ProjectCostCodeID
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
	, null as CategoryName
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
	, null as ProjectCostCodeID
	FROM #TotalCostData

	
	/**********************************************************************************/

	IF @sortBy = 'ChangeOrder'
	BEGIN

		
		SELECT WorkorderID
		, WorkorderMod
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
		, sum(CompleteCost) as CompleteCost
		, sum(OverUnder) as OverUnder
		, min(Notes) as Notes
		, min(ModStatus) as ModStatus
		, (select WorkorderStatus from Workorders where WorkorderID = a.WorkorderID collate Modern_Spanish_CI_AS and WorkorderMod = a.WorkorderMod collate Modern_Spanish_CI_AS) as WorkorderStatus
		, Show
		, (select top 1 isnull(ba.LA_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_GoalAmount
		, (select top 1 isnull(ba.MA_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_GoalAmount
		, (select top 1 isnull(ba.SU_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_GoalAmount
		, (select top 1 isnull(ba.EQ_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_GoalAmount
		, (select top 1 ba.LA_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_GoalDate
		, (select top 1 ba.MA_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_GoalDate
		, (select top 1 ba.SU_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_GoalDate
		, (select top 1 ba.EQ_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_GoalDate
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.LA_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_Responsible
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.MA_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_Responsible
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.SU_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_Responsible
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.EQ_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_Responsible
		, (select top 1 ba.LA_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_Notes
		, (select top 1 ba.MA_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_Notes
		, (select top 1 ba.SU_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_Notes
		, (select top 1 ba.EQ_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_Notes
		FROM #AllData a
		WHERE isnull(AssemblyDescription,'') <> 'Adjustments:'
		AND (CategoryNumber IS NULL OR CategoryNumber COLLATE Modern_Spanish_CI_AS IN (SELECT CategoryNumber FROM CostType WHERE [Status] = 'on'))
		AND (@ShowOnlyTotals IS NULL OR (@ShowOnlyTotals = 'yes' AND WorkorderID IN ('Z555555','Z666666','Z777777','Z888888','Z999999')))
		GROUP BY WorkorderID
		, WorkorderMod
		, CategoryName
		, CategoryNumber
		, AssemblyNumber
		, ItemName
		, AssemblyDescription
		, Estimate_band
		, Budget_band
		, AtRiskCost_band
		, Show
		
		ORDER BY WorkorderID, WorkorderMod, AssemblyNumber, CategoryNumber, Show

	END
	ELSE
	BEGIN

		
		SELECT WorkorderID
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
		, sum(OpenCost) OpenCost
		, sum(GoalCost) as GoalCost
		, sum(AtRiskCost) as AtRiskCost
		, AtRiskCost_band
		, sum(CompleteCost) as CompleteCost
		, sum(OverUnder) as OverUnder
		, (SELECT case when t.Notes <> '-' then t.Notes + ';' else t.Notes end FROM #AllData t WHERE t.AssemblyNumber = a.AssemblyNumber and t.CategoryNumber = a.CategoryNumber ORDER BY t.WorkorderMod, t.Notes ASC for xml path('')) as Notes
		, min(ModStatus) as ModStatus
		, (select WorkorderStatus from Workorders where WorkorderID = a.WorkorderID collate Modern_Spanish_CI_AS and WorkorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS) as WorkorderStatus
		, Show
		, (SELECT COUNT(1) FROM (SELECT DISTINCT t.WorkorderMod FROM #AllData t WHERE t.AssemblyNumber = a.AssemblyNumber and t.CategoryNumber = a.CategoryNumber) x ) as ModsFlag
		, (SELECT DISTINCT t.WorkorderMod + ';' FROM #AllData t WHERE t.AssemblyNumber = a.AssemblyNumber and t.CategoryNumber = a.CategoryNumber for xml path('')) as ModsStr
		, (select top 1 isnull(ba.LA_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_GoalAmount
		, (select top 1 isnull(ba.MA_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_GoalAmount
		, (select top 1 isnull(ba.SU_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_GoalAmount
		, (select top 1 isnull(ba.EQ_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_GoalAmount
		, (select top 1 ba.LA_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_GoalDate
		, (select top 1 ba.MA_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_GoalDate
		, (select top 1 ba.SU_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_GoalDate
		, (select top 1 ba.EQ_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_GoalDate
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.LA_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_Responsible
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.MA_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_Responsible
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.SU_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_Responsible
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.EQ_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_Responsible
		, (select top 1 ba.LA_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_Notes
		, (select top 1 ba.MA_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_Notes
		, (select top 1 ba.SU_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_Notes
		, (select top 1 ba.EQ_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_Notes
		FROM #AllData a
		WHERE (CategoryNumber IS NULL OR CategoryNumber COLLATE Modern_Spanish_CI_AS IN (SELECT CategoryNumber FROM CostType WHERE [Status] = 'on'))
		AND (@ShowOnlyTotals IS NULL OR (@ShowOnlyTotals = 'yes' AND WorkorderID IN ('Z555555','Z666666','Z777777','Z888888','Z999999')))
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
		ORDER BY AssemblyNumber, CategoryNumber, WorkorderID, WorkorderMod, Show

	END

END

ELSE

BEGIN

	
	SELECT WorkorderID
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
		, sum(OpenCost) OpenCost
		, sum(GoalCost) as GoalCost
		, sum(AtRiskCost) as AtRiskCost
		, AtRiskCost_band
		, sum(CompleteCost) as CompleteCost
		, sum(OverUnder) as OverUnder
		, (SELECT case when t.Notes <> '-' then t.Notes + ';' else t.Notes end FROM #ResultData t WHERE t.AssemblyNumber = a.AssemblyNumber and t.CategoryNumber = a.CategoryNumber ORDER BY t.WorkorderMod, t.Notes ASC for xml path('')) as Notes
		, min(ModStatus) as ModStatus
		, (select WorkorderStatus from Workorders where WorkorderID = a.WorkorderID collate Modern_Spanish_CI_AS and WorkorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS) as WorkorderStatus
		, Show
		, (SELECT COUNT(1) FROM (SELECT DISTINCT t.WorkorderMod FROM #ResultData t WHERE t.AssemblyNumber = a.AssemblyNumber and t.CategoryNumber = a.CategoryNumber) x ) as ModsFlag
		, (SELECT DISTINCT t.WorkorderMod + ';' FROM #ResultData t WHERE t.AssemblyNumber = a.AssemblyNumber and t.CategoryNumber = a.CategoryNumber for xml path('')) as ModsStr
		, (select top 1 isnull(ba.LA_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_GoalAmount
		, (select top 1 isnull(ba.MA_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_GoalAmount
		, (select top 1 isnull(ba.SU_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_GoalAmount
		, (select top 1 isnull(ba.EQ_GoalAmount,0) from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_GoalAmount
		, (select top 1 ba.LA_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_GoalDate
		, (select top 1 ba.MA_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_GoalDate
		, (select top 1 ba.SU_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_GoalDate
		, (select top 1 ba.EQ_GoalDate from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_GoalDate
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.LA_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_Responsible
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.MA_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_Responsible
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.SU_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_Responsible
		, (select top 1 case when isnull(u.title,'') = '' then u.LastName + ', ' + u.FirstName else u.LastName + ', ' + u.FirstName + ' (' + u.title + ')' end from BuyoutAssemblies ba inner join Users u on u.UserID = ba.EQ_Responsible LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_Responsible
		, (select top 1 ba.LA_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as LA_Notes
		, (select top 1 ba.MA_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as MA_Notes
		, (select top 1 ba.SU_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as SU_Notes
		, (select top 1 ba.EQ_Notes from BuyoutAssemblies ba LEFT JOIN dbo.ProjectCostCodes pcc ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID AND pcc.Status = 'on' where ba.status = 'show' and ba.workorderID = a.WorkorderID collate Modern_Spanish_CI_AS and ba.workorderMod = min(a.WorkorderMod) collate Modern_Spanish_CI_AS and pcc.CostCodeNumber = a.AssemblyNumber collate Modern_Spanish_CI_AS) as EQ_Notes
	FROM #ResultData a
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

END

DROP TABLE #AllData
DROP TABLE #ChangeOrds
DROP TABLE #ResultData
DROP TABLE #TotalDirectData
DROP TABLE #OverheadData
DROP TABLE #TotalCostData
DROP TABLE #TotalsAux

SET NOCOUNT OFF


go