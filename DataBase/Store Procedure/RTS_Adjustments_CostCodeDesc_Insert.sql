CREATE PROCEDURE [dbo].[RTS_Adjustments_CostCodeDesc_Insert]
  @WorkorderID char(7)
, @WorkorderMod char(2)
, @CostCode varchar(25)
, @CostCodeDesc varchar(1000)
, @Category varchar(25)
, @AdjustEnteredBy varchar(25)
, @AdjustEnteredDate datetime

AS

SET NOCOUNT ON

DECLARE @AdjustID int

IF NOT EXISTS (
	SELECT TOP 1 AdjustID 
	FROM Adjustments 
	WHERE WorkorderId = @WorkorderID AND WorkorderMod = @WorkorderMod 
		AND AdjustCostCode = @CostCode AND AdjustCategory = @Category
	)

BEGIN --> insert a new register on adjustments table

	INSERT INTO Adjustments (
		WorkorderID
		, WorkorderMod
		, AdjustCostCode
		, AdjustCostCodeDesc
		, AdjustCategory
		, AdjustEnteredBy
		, AdjustEnteredDate
	)
	VALUES (
		@WorkorderID
		, @WorkorderMod 
		, @CostCode
		, @CostCodeDesc
		, @Category
		, @AdjustEnteredBy
		, getdate()
	)

	SET @AdjustID = SCOPE_IDENTITY()
	
	SELECT @AdjustID AS AdjustID, 'yes' AS AdjustCostCodeDesc, '' as CostCodeDesc_Ant
	
END

ELSE

BEGIN --> update the Cost Code description value of register on adjustments table

	DECLARE @CostCodeDesc_Ant varchar(1000), @CostCodeDesc_New varchar(1000)

	SELECT TOP 1 @CostCodeDesc_Ant = AdjustCostCodeDesc 
	FROM Adjustments 
	WHERE WorkorderId = @WorkorderID AND WorkorderMod = @WorkorderMod 
		AND AdjustCostCode = @CostCode AND AdjustCategory = @Category

	EXEC dbo.RTS_Adjustments_CostCodeDesc_Update @WorkorderID, @WorkorderMod, @CostCode, @CostCodeDesc, @Category, @AdjustEnteredBy, @AdjustEnteredDate

	SELECT TOP 1 @AdjustID = AdjustID, @CostCodeDesc_New = AdjustCostCodeDesc 
	FROM Adjustments 
	WHERE WorkorderId = @WorkorderID AND WorkorderMod = @WorkorderMod 
		AND AdjustCostCode = @CostCode AND AdjustCategory = @Category

	SELECT @AdjustID AS AdjustID
	, CASE WHEN @CostCodeDesc_Ant <> @CostCodeDesc_New THEN 'yes' ELSE 'no' END AS AdjustCostCodeDesc, @CostCodeDesc_Ant as CostCodeDesc_Ant

END


/******************************************************************/
GO