
create PROCEDURE [dbo].[Budget_Invoice_pa]
  @WorkorderIDParam varchar(7)
, @WorkorderModParam varchar(2) = null
, @sortBy varchar(15) = 'ChangeOrder'
, @rollTypeFlag int = 0
, @AssemblyNumber varchar(25) = null
, @ShowOnlyTotals varchar(3) = null
, @ShowOnlyAssemblies varchar(3) = null

AS

SET NOCOUNT ON

DECLARE @CustomerFacilityIDParam varchar(5)
select @CustomerFacilityIDParam = wo.CustomerFacilityID from Workorders wo
where wo.WorkorderID = @WorkorderIDParam and wo.WorkorderMod = '00'

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
--, ProjectCostCodeID int
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
--, ProjectCostCodeID int
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

CREATE TABLE #Datos
(
  AssemblyNumber varchar(25)
, AssemblyDescription varchar(max)
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
WHERE CategoryNumber COLLATE Modern_Spanish_CI_AS IN (SELECT CategoryNumber FROM CostType WHERE [Status] = 'on')


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
	, CASE CategoryName
		WHEN 'Labor' THEN AtRiskCost * @LaborRate
		WHEN 'Material' THEN AtRiskCost * @MaterialRate
		WHEN 'Subcontract' THEN AtRiskCost * @SubcontractRate
		WHEN 'Equipment' THEN isnull(AtRiskCost,0) * @EquipmentRate
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
	, AtRiskCost as AtRiskCost
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
	, AtRiskCost as AtRiskCost
	, null as AtRiskCost_band
	, ActualCost + OpenCost + Contingency + AtRiskCost as CompleteCost
	, Budget - (ActualCost + OpenCost + Contingency + AtRiskCost) as OverUnder
	, null as Notes
	, null as ModStatus
	, 2 as Show
	--, ProjectCostCodeID as ProjectCostCodeID 
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
, sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost) as CompleteCost
, sum(Budget) - (sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost)) as OverUnder
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

/**********************************************************************************/
UPDATE #ResultData SET Budget = isnull(Adjust,Estimate)
/**********************************************************************************/


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
	, sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost) as CompleteCost
	, sum(Budget) - (sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost)) as OverUnder
	, min(Notes) as Notes
	, min(ModStatus) as ModStatus
	, null as Show
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
	, sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost) as CompleteCost
	, isnull(sum(Adjust),sum(Estimate)) - (sum(ActualCost) + sum(OpenCost) + sum(Contingency) + sum(AtRiskCost)) as OverUnder
	, min(Notes) as Notes
	, min(ModStatus) as ModStatus
	, null as Show
	FROM #TotalDirectData
	GROUP BY AssemblyDescription
	
END

IF EXISTS (SELECT TOP 1 * FROM #ResultData) AND (@ShowOnlyAssemblies IS NULL)
BEGIN

	INSERT INTO #AllData
	SELECT * 
	FROM #ResultData

	IF @sortBy = 'ChangeOrder'
	BEGIN

		INSERT INTO #Datos
		SELECT AssemblyNumber, AssemblyNumber + ' - ' + isnull(AssemblyDescription,'') as AssemblyDescription
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
		
		ORDER BY AssemblyNumber

	END
	ELSE
	BEGIN
		INSERT INTO #Datos
		SELECT AssemblyNumber, AssemblyNumber + ' - ' + isnull(AssemblyDescription,'') as AssemblyDescription
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
		ORDER BY AssemblyNumber

	END

END

ELSE
	INSERT INTO #Datos
	SELECT AssemblyNumber, AssemblyNumber + ' - ' + isnull(AssemblyDescription,'') as AssemblyDescription
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

SELECT distinct AssemblyNumber, AssemblyDescription FROM #Datos

DROP TABLE #AllData
DROP TABLE #ChangeOrds
DROP TABLE #ResultData
DROP TABLE #TotalDirectData
DROP TABLE #OverheadData
DROP TABLE #TotalCostData
DROP TABLE #TotalsAux
DROP TABLE #Datos

SET NOCOUNT OFF



GO