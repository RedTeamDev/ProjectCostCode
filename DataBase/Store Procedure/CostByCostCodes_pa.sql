CREATE PROCEDURE [dbo].[CostByCostCodes_pa]
  @WorkorderID varchar(7)
, @WorkorderMod char(2)
, @Format varchar(10) = NULL
, @FromDate varchar(10) = NULL
, @ToDate varchar(10) = NULL
, @AcctPeriodUniqueID int = NULL

AS

SET NOCOUNT ON

CREATE TABLE #CostsByCostCodes
(
	cstCde		varchar(15)
,	cstName		varchar(max)
,	cstPayeeCol	varchar(max)
,	min_trndte	datetime null
,	max_entdte	datetime null
,	AccountingPeriod int
,	[hours]		decimal(18,9)
,	sum_cstamt	varchar(100)
,	category	varchar(15)
,	cstPayeeName varchar(max)
)

IF @Format = 'negotiated'
INSERT #CostsByCostCodes EXEC Labor_NegociatedCosts_pa @WorkorderID, @WorkorderMod, @FromDate, @ToDate, @AcctPeriodUniqueID
ELSE
INSERT #CostsByCostCodes EXEC Labor_Costs_pa @WorkorderID, @WorkorderMod, @FromDate, @ToDate, @AcctPeriodUniqueID

INSERT #CostsByCostCodes EXEC Material_Costs_pa @WorkorderID, @WorkorderMod, @FromDate, @ToDate, @AcctPeriodUniqueID

INSERT #CostsByCostCodes EXEC Subcontract_Costs_pa @WorkorderID, @WorkorderMod, @FromDate, @ToDate, @AcctPeriodUniqueID

INSERT #CostsByCostCodes EXEC Equipment_Costs_pa @WorkorderID, @WorkorderMod, @FromDate, @ToDate, @AcctPeriodUniqueID

		
Select a.*
, dbo.GetAssemblyDescriptions_fn(@WorkorderID,@WorkorderMod,RTRIM(cstCde),'00','yes') as CostCodeDesc
From #CostsByCostCodes a
Inner join CostCode cc on RTRIM(a.cstCde) = RTRIM(cc.CostCodeID) COLLATE Modern_Spanish_CI_AS
--Group by a.cstCde, a.category, a.cstName, a.cstPayeeCol, a.cstPayeeName, a.min_trndte, a.max_entdte, a.hours, a.sum_cstamt, cc.CostCodeDesc
--Order by a.cstCde, a.category, a.cstName, a.cstPayeeCol, a.cstPayeeName, cc.CostCodeDesc
Order by a.cstCde, a.min_trndte, a.cstPayeeCol, a.cstPayeeName

	
DROP TABLE #CostsByCostCodes

SET NOCOUNT OFF



GO