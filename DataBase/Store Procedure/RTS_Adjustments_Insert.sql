CREATE PROCEDURE [dbo].[RTS_Adjustments_Insert]
  @WorkorderID char(7)
, @WorkorderMod char(2)
, @CostCode varchar(25)
, @Category varchar(25)
, @AdjustAmount float = NULL
, @AdjustContingency float = NULL
, @AdjustEnteredBy varchar(25)
, @AdjustEnteredDate datetime
, @Action varchar(20) --> Save, Commit

AS

SET NOCOUNT ON

DECLARE @DateCommitted char(10)
DECLARE @AdjustID int

If @Action = 'Commit'
   SET @DateCommitted = convert(char(10),getdate(),101)
Else If @Action = 'Save'
   SET @DateCommitted = ''

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
		, AdjustAmount
		, AdjustContingency
		, AdjustEnteredBy
		, AdjustEnteredDate
		, AdjustDateCommitted )
	VALUES (
		@WorkorderID
		, @WorkorderMod
		, @CostCode
		, (select dbo.GetAssemblyDescriptions_fn (@WorkorderID, @WorkorderMod, @CostCode, null, 'yes'))
		, @Category
		, @AdjustAmount
		, @AdjustContingency
		, @AdjustEnteredBy
		, getdate()
		, @DateCommitted
	)

	SET @AdjustID = SCOPE_IDENTITY()
	
	SELECT @AdjustID AS AdjustID, 'yes' AS AdjustBudget, 'yes' AS AdjustContingency
	
END

ELSE

BEGIN --> update the AdjustDateCommitted value of register on adjustments table

	DECLARE @AdjustAmount_Ant float, @AdjustContingency_Ant float
	DECLARE @AdjustAmount_New float, @AdjustContingency_New float
	
	SELECT TOP 1 @AdjustAmount_Ant = isnull(AdjustAmount,0), @AdjustContingency_Ant = isnull(AdjustContingency,0)
	FROM Adjustments 
	WHERE WorkorderId = @WorkorderID AND WorkorderMod = @WorkorderMod 
		AND AdjustCostCode = @CostCode AND AdjustCategory = @Category

	EXEC dbo.RTS_Adjustments_Update @WorkorderID, @WorkorderMod, @CostCode, @Category, @AdjustAmount, @AdjustContingency, @DateCommitted, @AdjustEnteredBy, @AdjustEnteredDate

	SELECT TOP 1 @AdjustAmount_New =  isnull(AdjustAmount,0), @AdjustContingency_New = isnull(AdjustContingency,0)
	FROM Adjustments 
	WHERE WorkorderId = @WorkorderID AND WorkorderMod = @WorkorderMod 
		AND AdjustCostCode = @CostCode AND AdjustCategory = @Category

	SELECT TOP 1 AdjustID
	, CASE WHEN @AdjustAmount_Ant <> @AdjustAmount_New THEN 'yes' ELSE 'no' END AS AdjustBudget
	, CASE WHEN @AdjustContingency_Ant <> @AdjustContingency_New THEN 'yes' ELSE 'no' END AS AdjustContingency
	FROM Adjustments 
	WHERE WorkorderId = @WorkorderID AND WorkorderMod = @WorkorderMod 
		AND AdjustCostCode = @CostCode AND AdjustCategory = @Category

END


GO