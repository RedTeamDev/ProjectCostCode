
CREATE PROCEDURE [dbo].[RTS_Budget_Import]

	@WorkorderID_From varchar(7)
,	@WorkorderMod_From char(2)
,	@WorkorderID_To varchar(7)
,	@WorkorderMod_To char(2)
,	@chkImportBudget varchar(5)
,	@chkImportAtRisk varchar(5)
,	@chkImportContingency varchar(5)
,	@rollTypeFlag int = 0
,	@EnteredBy int

AS


SET NOCOUNT ON


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
)


/******************************************************************************/

INSERT INTO #AllData
EXEC dbo.BudgetAndActualCosts_pa NULL, @WorkorderID_From, @WorkorderMod_From

--select * from #AllData

/******************************************************************************/

	
INSERT INTO #ResultData
SELECT * 
FROM #AllData t
WHERE (t.CategoryNumber IS NULL OR CategoryNumber COLLATE Modern_Spanish_CI_AS IN (SELECT CategoryNumber FROM CostType WHERE [Status] = 'on'))
	
--SELECT * FROM #ResultData

TRUNCATE TABLE #AllData

UPDATE #ResultData SET Budget = isnull(Adjust,Estimate)

/**********************************************************************************/


IF EXISTS (SELECT TOP 1 * FROM #ResultData)
BEGIN

	INSERT INTO #AllData
	SELECT * FROM #ResultData
	
	TRUNCATE TABLE #ResultData


	INSERT INTO #ResultData
	SELECT a.WorkorderID
	, a.WorkorderMod
	, a.CategoryName
	, a.CategoryNumber
	, a.AssemblyNumber
	, a.ItemName
	, a.AssemblyDescription
	, sum(a.Estimate) as Estimate
	, a.Estimate_band
	, sum(a.Budget) as Budget
	, a.Budget_band
	, sum(a.Adjust) as Adjust
	, CASE WHEN @chkImportContingency = 'on' THEN sum(a.Contingency) ELSE 0 END as Contingency
	, sum(a.ActualCost) as ActualCost
	, sum(a.OpenCost) as OpenCost
	, sum(a.GoalCost) as GoalCost
	, CASE WHEN @chkImportAtRisk = 'on' THEN sum(a.AtRiskCost) ELSE 0 END as AtRiskCost
	, a.AtRiskCost_band
	, sum(a.ActualCost) + sum(a.OpenCost) + sum(a.Contingency) + sum(a.AtRiskCost) as CompleteCost
	, sum(a.Budget) - (sum(a.ActualCost) + sum(a.OpenCost) + sum(a.Contingency) + sum(a.AtRiskCost)) as OverUnder
	, min(a.Notes) as Notes
	, min(a.ModStatus) as ModStatus
	, a.Show
	FROM #AllData a
	WHERE (CategoryNumber IS NULL OR CategoryNumber COLLATE Modern_Spanish_CI_AS IN (SELECT CategoryNumber FROM CostType WHERE [Status] = 'on'))
	GROUP BY a.WorkorderID
	, a.WorkorderMod
	, a.CategoryName
	, a.CategoryNumber
	, a.AssemblyNumber
	, a.ItemName
	, a.AssemblyDescription
	, a.Estimate_band
	, a.Budget_band
	, a.AtRiskCost_band
	, a.Show
	ORDER BY a.WorkorderID, a.WorkorderMod, a.AssemblyNumber, a.CategoryNumber, a.Show

END

--SELECT * FROM #ResultData

DECLARE @WorkorderMod CHAR(2), @AdjustCostCode VARCHAR(25), @AdjustCategory VARCHAR(50), @AdjustCostCodeDesc VARCHAR(1000)
DECLARE @BudgetAmt DECIMAL(19,8), @AdjustBudgetAmt DECIMAL(19,8), @AdjustContingencyAmt DECIMAL(19,8), @AtRiskAmt DECIMAL(19,8)

WHILE EXISTS (SELECT TOP 1 AssemblyNumber, CategoryName FROM #ResultData WHERE Show = 1)
BEGIN

	SELECT TOP 1 @WorkorderMod = WorkorderMod, @AdjustCostCode = AssemblyNumber, @AdjustCategory = CategoryName, @AdjustCostCodeDesc = AssemblyDescription
	, @BudgetAmt = Budget, @AdjustBudgetAmt = ISNULL(Adjust,0), @AdjustContingencyAmt = ISNULL(Contingency,0), @AtRiskAmt = ISNULL(AtRiskCost,0)
	FROM #ResultData WHERE Show = 1

	DECLARE @CustomerFacilityID VARCHAR(5), @DivID VARCHAR(4)
	SELECT @CustomerFacilityID = CustomerFacilityID FROM Workorders WHERE @WorkorderID_To = WorkorderID AND @WorkorderMod_To = WorkorderMod
	SELECT TOP 1 @DivID = DivID FROM [Assemblies] WHERE AssemblyNumber = @AdjustCostCode

	/*IMPORT ESTIMATE BUDGET TO ADJUSTMENTS TABLE*/
	IF NOT EXISTS (
		SELECT TOP 1 WaID
		FROM WorkorderAssemblies
		WHERE @WorkorderID_To = WorkorderID AND @WorkorderMod_To = WorkorderMod AND @AdjustCostCode = AssemblyNumber 
		AND (
			(@AdjustCategory = 'Material' AND MATotal <> 0)
			OR
			(@AdjustCategory = 'Labor' AND LATotal <> 0)
			OR
			(@AdjustCategory = 'Subcontract' AND SUTotal <> 0)
			OR
			(@AdjustCategory = 'Equipment' AND EQTotal <> 0)
		)
	)
	BEGIN
		IF @BudgetAmt <> 0 AND NOT EXISTS (SELECT TOP 1 AdjustID FROM Adjustments WHERE @WorkorderID_To = WorkorderID AND @WorkorderMod_To = WorkorderMod AND @AdjustCostCode = AdjustCostCode AND @AdjustCategory = AdjustCategory)
		BEGIN

			INSERT INTO Adjustments (
			  WorkorderID
			, WorkorderMod
			, AdjustCostCode
			, AdjustCategory
			, AdjustCostCodeDesc
			, AdjustAmount
			, AdjustContingency
			, AdjustEnteredBy
			, AdjustEnteredDate
			)
	
			SELECT @WorkorderID_To
			, @WorkorderMod_To
			, @AdjustCostCode
			, @AdjustCategory
			, @AdjustCostCodeDesc
			, @BudgetAmt
			, 0
			, @EnteredBy
			, getdate()

		END
	END

	/*IMPORT ADJUST BUDGET AND CONTINGENCY TO ADJUSTMENTS TABLE*/
	IF NOT EXISTS (SELECT TOP 1 AdjustID FROM Adjustments WHERE @WorkorderID_To = WorkorderID AND @WorkorderMod_To = WorkorderMod AND @AdjustCostCode = AdjustCostCode AND @AdjustCategory = AdjustCategory)
	BEGIN

		IF @AdjustBudgetAmt <> 0 OR @AdjustContingencyAmt <> 0
		BEGIN

			INSERT INTO Adjustments (
			  WorkorderID
			, WorkorderMod
			, AdjustCostCode
			, AdjustCategory
			, AdjustCostCodeDesc
			, AdjustAmount
			, AdjustContingency
			, AdjustEnteredBy
			, AdjustEnteredDate
			)
	
			SELECT @WorkorderID_To
			, @WorkorderMod_To
			, @AdjustCostCode
			, @AdjustCategory
			, @AdjustCostCodeDesc
			, @AdjustBudgetAmt
			, @AdjustContingencyAmt
			, @EnteredBy
			, getdate()

		END

	END

	ELSE

	BEGIN

		UPDATE Adjustments
		SET AdjustAmount = @AdjustBudgetAmt
		, AdjustContingency = @AdjustContingencyAmt
		, AdjustEnteredBy = @EnteredBy
		, AdjustEnteredDate = getdate()
		WHERE @WorkorderID_To = WorkorderID AND @WorkorderMod_To = WorkorderMod AND @AdjustCostCode = AdjustCostCode AND @AdjustCategory = AdjustCategory

	END
	
	/*IMPORT AT RISK TO BUYOUTASSEMBLIES TABLE*/
	IF @chkImportAtRisk = 'on'
	BEGIN
	/*
	IF EXISTS (
		SELECT TOP 1 ba.BuyoutAssembliesID
		FROM BuyoutAssemblies ba
		INNER JOIN WorkorderAssemblies wa ON wa.waID = ba.waID
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 
		AND (
			(@AdjustCategory = 'Material' AND wa.MATotal = ba.MATotal AND ba.MATotal <> @AtRiskAmt)
			OR
			(@AdjustCategory = 'Labor' AND wa.LATotal = ba.LATotal AND ba.LATotal <> @AtRiskAmt)
			OR
			(@AdjustCategory = 'Subcontract' AND wa.SUTotal = ba.SUTotal AND ba.SUTotal <> @AtRiskAmt)
			OR
			(@AdjustCategory = 'Equipment' AND wa.EQTotal = ba.EQTotal AND ba.EQTotal <> @AtRiskAmt)
		)
	)
	BEGIN
		
		UPDATE ba
		SET ba.MATotal = @AtRiskAmt
		FROM BuyoutAssemblies ba
		INNER JOIN WorkorderAssemblies wa ON wa.waID = ba.waID
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 
		AND @AdjustCategory = 'Material' AND wa.MATotal = ba.MATotal

		UPDATE ba
		SET ba.LATotal = @AtRiskAmt
		FROM BuyoutAssemblies ba
		INNER JOIN WorkorderAssemblies wa ON wa.waID = ba.waID
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 
		AND @AdjustCategory = 'Labor' AND wa.LATotal = ba.LATotal

		UPDATE ba
		SET ba.SUTotal = @AtRiskAmt
		FROM BuyoutAssemblies ba
		INNER JOIN WorkorderAssemblies wa ON wa.waID = ba.waID
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 
		AND @AdjustCategory = 'Subcontract' AND wa.SUTotal = ba.SUTotal
		
		UPDATE ba
		SET ba.EQTotal = @AtRiskAmt
		FROM BuyoutAssemblies ba
		INNER JOIN WorkorderAssemblies wa ON wa.waID = ba.waID
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 
		AND @AdjustCategory = 'Equipment' AND wa.EQTotal = ba.EQTotal

		UPDATE ba
		SET AtRiskAmount = ISNULL(MATotal,0) + ISNULL(LATotal,0) + ISNULL(SUTotal,0) + ISNULL(EQTotal,0)
		FROM BuyoutAssemblies ba
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber

	END

	ELSE 
	*/
	IF EXISTS (
		SELECT TOP 1 ba.BuyoutAssembliesID
		FROM BuyoutAssemblies ba
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 
	)
	BEGIN

		UPDATE ba
		SET ba.MATotal = @AtRiskAmt
		FROM BuyoutAssemblies ba
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 
		AND @AdjustCategory = 'Material'

		UPDATE ba
		SET ba.LATotal = @AtRiskAmt
		FROM BuyoutAssemblies ba
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 
		AND @AdjustCategory = 'Labor'

		UPDATE ba
		SET ba.SUTotal = @AtRiskAmt
		FROM BuyoutAssemblies ba
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 
		AND @AdjustCategory = 'Subcontract'
		
		UPDATE ba
		SET ba.EQTotal = @AtRiskAmt
		FROM BuyoutAssemblies ba
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 
		AND @AdjustCategory = 'Equipment'

		UPDATE ba
		SET AtRiskAmount = ISNULL(MATotal,0) + ISNULL(LATotal,0) + ISNULL(SUTotal,0) + ISNULL(EQTotal,0)
		FROM BuyoutAssemblies ba
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 

	END

	ELSE IF NOT EXISTS (
		SELECT TOP 1 ba.BuyoutAssembliesID
		FROM BuyoutAssemblies ba
		WHERE @WorkorderID_To = ba.WorkorderID AND @WorkorderMod_To = ba.WorkorderMod AND @AdjustCostCode = ba.AssemblyNumber 
	)
	BEGIN

		INSERT INTO BuyoutAssemblies (
		  CustomerFacilityID
		, WorkorderID
		, WorkorderMod
		, AssemblyNumber
		, AssemblyMod
		, AssemblyDescription
		, DivID
		, AtRiskAmount
		, [Status]
		, isHidden
		, MATotal
		, LATotal
		, SUTotal
		, EQTotal
		)
		
		SELECT @CustomerFacilityID AS CustomerFacilityID
		, @WorkorderID_To AS WorkorderID
		, @WorkorderMod_To AS WorkorderMod
		, @AdjustCostCode AS AssemblyNumber
		, '00' AS AssemblyMod
		, (SELECT [dbo].[GetAssemblyDescriptions_fn](@WorkorderID_To,@WorkorderMod_To,@AdjustCostCode,'00','no')) AS AssemblyDescription
		, @DivID AS DivID
		, @AtRiskAmt AS AtRiskAmount
		, 'show' AS [Status]
		, 'no' AS isHidden
		, @AtRiskAmt AS MATotal
		, NULL AS LATotal
		, NULL AS SUTotal
		, NULL AS EQTotal
		WHERE @AdjustCategory = 'Material' AND @AtRiskAmt <> 0
		UNION
		SELECT @CustomerFacilityID AS CustomerFacilityID
		, @WorkorderID_To AS WorkorderID
		, @WorkorderMod_To AS WorkorderMod
		, @AdjustCostCode AS AssemblyNumber
		, '00' AS AssemblyMod
		, (SELECT [dbo].[GetAssemblyDescriptions_fn](@WorkorderID_To,@WorkorderMod_To,@AdjustCostCode,'00','no')) AS AssemblyDescription
		, @DivID AS DivID
		, @AtRiskAmt AS AtRiskAmount
		, 'show' AS [Status]
		, 'no' AS isHidden
		, NULL AS MATotal
		, @AtRiskAmt AS LATotal
		, NULL AS SUTotal
		, NULL AS EQTotal
		WHERE @AdjustCategory = 'Labor' AND @AtRiskAmt <> 0
		UNION
		SELECT @CustomerFacilityID AS CustomerFacilityID
		, @WorkorderID_To AS WorkorderID
		, @WorkorderMod_To AS WorkorderMod
		, @AdjustCostCode AS AssemblyNumber
		, '00' AS AssemblyMod
		, (SELECT [dbo].[GetAssemblyDescriptions_fn](@WorkorderID_To,@WorkorderMod_To,@AdjustCostCode,'00','no')) AS AssemblyDescription
		, @DivID AS DivID
		, @AtRiskAmt AS AtRiskAmount
		, 'show' AS [Status]
		, 'no' AS isHidden
		, NULL AS MATotal
		, NULL AS LATotal
		, @AtRiskAmt AS SUTotal
		, NULL AS EQTotal
		WHERE @AdjustCategory = 'Subcontract' AND @AtRiskAmt <> 0
		UNION
		SELECT @CustomerFacilityID AS CustomerFacilityID
		, @WorkorderID_To AS WorkorderID
		, @WorkorderMod_To AS WorkorderMod
		, @AdjustCostCode AS AssemblyNumber
		, '00' AS AssemblyMod
		, (SELECT [dbo].[GetAssemblyDescriptions_fn](@WorkorderID_To,@WorkorderMod_To,@AdjustCostCode,'00','no')) AS AssemblyDescription
		, @DivID AS DivID
		, @AtRiskAmt AS AtRiskAmount
		, 'show' AS [Status]
		, 'no' AS isHidden
		, NULL AS MATotal
		, NULL AS LATotal
		, NULL AS SUTotal
		, @AtRiskAmt AS EQTotal
		WHERE @AdjustCategory = 'Equipment' AND @AtRiskAmt <> 0

	END

	END

	UPDATE #ResultData SET Show = 2 WHERE @WorkorderMod = WorkorderMod AND @AdjustCostCode = AssemblyNumber AND @AdjustCategory = CategoryName

END

DROP TABLE #AllData
DROP TABLE #ResultData

SET NOCOUNT OFF




























GO