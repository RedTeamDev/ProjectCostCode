
CREATE  PROCEDURE [dbo].[RTS_ImportCostByTransactions]
 @WorkorderID varchar(7) = NULL
,@WorkorderMod varchar(2) = NULL
,@Status	varchar(100) = NULL
,@Origin	varchar(20) = NULL
,@SchedValueID	int = NULL

AS

SET NOCOUNT ON

DECLARE @StatusList			VARCHAR(100)
DECLARE @SqlQuery			varchar(MAX)   

SET @StatusList = '''' + REPLACE(REPLACE(@Status, ',', ''','''), ' ', '') + ''''   
IF @Status = '' SET @Status = NULL

CREATE TABLE #CostsByTransactions
(
	id			int
,	GeneralLedgerLineID int
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
								 
INSERT #CostsByTransactions EXEC RTS_Labor_Costs_ByTransactions @WorkorderID, @WorkorderMod --, @FromDate, @ToDate, @AcctPeriodUniqueID
INSERT #CostsByTransactions EXEC RTS_Material_Costs_ByTransactions @WorkorderID, @WorkorderMod --, @FromDate, @ToDate, @AcctPeriodUniqueID
INSERT #CostsByTransactions EXEC RTS_Subcontract_Costs_ByTransactions @WorkorderID, @WorkorderMod --, @FromDate, @ToDate, @AcctPeriodUniqueID
INSERT #CostsByTransactions EXEC RTS_Equipment_Costs_ByTransactions @WorkorderID, @WorkorderMod --, @FromDate, @ToDate, @AcctPeriodUniqueID

SELECT 	id
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
INTO #CostTemp
FROM #CostsByTransactions
GROUP BY id
,	cstCde
,	cstName
,	min_trndte
,	max_entdte
,	[hours]
,	category
,	SourceID
ORDER BY cstCde, min_trndte, SourceID

SELECT distinct ct.*, gl.TMSheet, gl.Billed, gl.WocompletedID 
INTO #CostTempTMSheet
FROM #CostTemp ct 
left JOIN dbo.GeneralLedger gl ON gl.GeneralLedgerID = ct.id --AND ct.sum_cstamt = gl.Amount

IF @Origin = 'Billing'
BEGIN
	SET @SqlQuery = 'SELECT id, cstCde, cstName, min_trndte, max_entdte, [hours], sum_cstamt, category, SourceID, scope, CostCodeDesc, isnull(TMSheet,0) as TMSheet, WocompletedID FROM #CostTempTMSheet '
	IF (@Status = 'UnBilled') 
	BEGIN
		SET @SqlQuery = @SqlQuery + 'where Billed is NULL ORDER BY cstCde, min_trndte, SourceID'
	END
	ELSE
	BEGIN
		SET @SqlQuery = @SqlQuery + 'where Billed = ''Included'' and WocompletedID in (select CompletedUniqueID from WorkorderCompleted where SchedValueUniqueID = ''' + RTRIM(@SchedValueID) + ''' and WorkorderID = ''' + RTRIM(@WorkorderID) + ''' ) ORDER BY cstCde, min_trndte, SourceID'
	END
END 
ELSE
BEGIN
	SET @SqlQuery = 'SELECT id, cstCde, cstName, min_trndte, max_entdte, [hours], sum_cstamt, category, SourceID, scope, CostCodeDesc, isnull(TMSheet,0) as TMSheet FROM #CostTempTMSheet '
	IF (@Status = 'Excluded') 
	BEGIN 
		SET @SqlQuery = @SqlQuery + ' where TMSheet IN (' + @StatusList  + ') ORDER BY cstCde, min_trndte, SourceID'
	END		
	ELSE
	BEGIN
		IF (@Status = 'UnWaive') 
		BEGIN
			SET @SqlQuery = @SqlQuery + ' where TMSheet is NULL ORDER BY cstCde, min_trndte, SourceID'
		END
		ELSE
		BEGIN
			SET @SqlQuery = @SqlQuery + ' where (TMSheet IS NULL OR TMSheet = ''Excluded'') ORDER BY cstCde, min_trndte, SourceID'
		END
	END
END 

--Print @SqlQuery  
Exec (@SqlQuery)
	
DROP TABLE #CostTemp
DROP TABLE #CostTempTMSheet
DROP TABLE #CostsByTransactions

SET NOCOUNT OFF

GO
