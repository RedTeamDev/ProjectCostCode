CREATE PROCEDURE [dbo].[RTS_Adjustments_CostCodeDesc_Update]
  @WorkorderID char(7)
, @WorkorderMod char(2)
, @CostCode varchar(25)
, @CostCodeDesc varchar(1000)
, @Category varchar(25)
, @AdjustUpdatedBy varchar(25) = NULL
, @AdjustUpdatedDate datetime = NULL

AS

UPDATE Adjustments
	SET AdjustCostCodeDesc = @CostCodeDesc
	, AdjustEnteredBy = @AdjustUpdatedBy
	, AdjustEnteredDate = getdate()
WHERE WorkorderId = @WorkorderID 
	AND AdjustCostCode = @CostCode 


/***********************************************************************************************/

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
GO