CREATE PROCEDURE [dbo].[RTS_CostByTransactions]
  @WorkorderID varchar(7)
, @WorkorderMod char(2) = NULL
, @Format varchar(10) = NULL
, @FromDate varchar(10) = NULL
, @ToDate varchar(10) = NULL
, @CostCodeID varchar(15) = NULL
, @AcctPeriodUniqueID int = NULL

AS

SET NOCOUNT ON

CREATE TABLE #CostsByTransactions
(
	id			int
,	GLlineID	int
,	cstCde		varchar(15)
,	cstName		varchar(max)
,	min_trndte	datetime null
,	max_entdte	datetime null
,	AccountingPeriod int
,	[hours]		decimal(18,9)
,	sum_cstamt	decimal(29,8)
,	category	varchar(15)
,	SourceID	varchar(25)
,	scope		char(2)
)

IF @Format = 'negotiated'
INSERT #CostsByTransactions EXEC RTS_Labor_NegociatedCosts_ByTransactions @WorkorderID, @WorkorderMod, @FromDate, @ToDate, @AcctPeriodUniqueID
ELSE
INSERT #CostsByTransactions EXEC RTS_Labor_Costs_ByTransactions @WorkorderID, @WorkorderMod, @FromDate, @ToDate, @AcctPeriodUniqueID

INSERT #CostsByTransactions EXEC RTS_Material_Costs_ByTransactions @WorkorderID, @WorkorderMod, @FromDate, @ToDate, @AcctPeriodUniqueID

INSERT #CostsByTransactions EXEC RTS_Subcontract_Costs_ByTransactions @WorkorderID, @WorkorderMod, @FromDate, @ToDate, @AcctPeriodUniqueID

INSERT #CostsByTransactions EXEC RTS_Equipment_Costs_ByTransactions @WorkorderID, @WorkorderMod, @FromDate, @ToDate, @AcctPeriodUniqueID


IF NOT @WorkorderMod IS NULL
	BEGIN
		--print 'entra 1'
		SELECT 	id
		,	GLlineID
		,	cstCde
		,	cstName
		,	min_trndte
		,	max_entdte
		,	[hours]
		,	sum_cstamt
		,	category
		,	SourceID
		,	scope
		,	dbo.GetAssemblyDescriptions_fn(@WorkorderID,@WorkorderMod,RTRIM(cstCde),scope,'yes') as CostCodeDesc
		FROM #CostsByTransactions
		WHERE (@CostCodeID is null OR cstCde = @CostCodeID)
		ORDER BY cstCde, min_trndte, SourceID
	END

ELSE

	BEGIN
		--print 'entra 2'
		SELECT 	id
		,	GLlineID
		,	cstCde
		,	cstName
		,	min_trndte
		,	max_entdte
		,	[hours]
		,	sum(sum_cstamt) as sum_cstamt
		,	category
		,	SourceID
		,	'00' as scope
		,	dbo.GetAssemblyDescriptions_fn(@WorkorderID,NULL,RTRIM(cstCde),'00','yes') as CostCodeDesc
		FROM #CostsByTransactions
		WHERE (@CostCodeID is null OR cstCde = @CostCodeID)
		GROUP BY id
		,   GLlineID
		,	cstCde
		,	cstName
		,	min_trndte
		,	max_entdte
		,	[hours]
		,	category
		,	SourceID
		ORDER BY cstCde, min_trndte, SourceID
	END

DROP TABLE #CostsByTransactions

SET NOCOUNT OFF

GO