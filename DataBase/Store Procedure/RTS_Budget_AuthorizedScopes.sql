
CREATE PROCEDURE [dbo].[RTS_Budget_AuthorizedScopes]
	@WorkorderIDParam varchar(7)
,	@WorkorderModParam char(2) = NULL
,	@GroupBy varchar(15) = 'CostCode'

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

/******************************************************************************/

IF @WorkorderModParam IS NULL
BEGIN
	INSERT INTO #AllData
	EXEC dbo.BudgetAndActualCosts_pa NULL, @WorkorderIDParam, NULL, 'yes'
END ELSE
BEGIN
	INSERT INTO #AllData
	EXEC dbo.BudgetAndActualCosts_pa NULL, @WorkorderIDParam, @WorkorderModParam, 'yes'
END

IF @GroupBy = 'CostCode'
BEGIN
	IF @WorkorderModParam IS NULL OR @WorkorderModParam = '00'
	BEGIN
		select distinct t.WorkorderMod, t.AssemblyNumber 
		from #AllData t
		inner join Workorders w on w.WorkorderID = t.WorkorderID collate Modern_Spanish_CI_AS
			and w.WorkorderMod = t.WorkorderMod collate Modern_Spanish_CI_AS
		where (t.ModStatus = 'Authorized' or (t.WorkorderMod = '00' and t.ModStatus = 'Potential'))
		and (@WorkorderModParam is null or t.WorkorderMod  = @WorkorderModParam)
		order by t.WorkorderMod, t.AssemblyNumber asc
	END
	ELSE
	BEGIN
		select distinct t.WorkorderMod, t.AssemblyNumber 
		from #AllData t
		inner join Workorders w on w.WorkorderID = t.WorkorderID collate Modern_Spanish_CI_AS
			and w.WorkorderMod = t.WorkorderMod collate Modern_Spanish_CI_AS
		where (t.ModStatus = 'Authorized' or (t.WorkorderMod <> '00' and w.WorkorderStatus = 'Proposal'))
		and (@WorkorderModParam is null or t.WorkorderMod  = @WorkorderModParam)
		order by t.WorkorderMod, t.AssemblyNumber asc
	END
END
ELSE
BEGIN

	IF @WorkorderModParam IS NULL OR @WorkorderModParam = '00'
	BEGIN
		select distinct t.WorkorderMod, t.AssemblyNumber 
		from #AllData t
		where t.ModStatus = 'Authorized'
		and (@WorkorderModParam is null or t.WorkorderMod  = @WorkorderModParam)
		order by t.WorkorderMod, t.AssemblyNumber asc
	END
	ELSE
	BEGIN
		select distinct t.WorkorderMod, t.AssemblyNumber 
		from #AllData t
		inner join Workorders w on w.WorkorderID = t.WorkorderID collate Modern_Spanish_CI_AS
			and w.WorkorderMod = t.WorkorderMod collate Modern_Spanish_CI_AS
		where (t.ModStatus = 'Authorized' or (t.WorkorderMod <> '00' and w.WorkorderStatus = 'Proposal'))
		and (@WorkorderModParam is null or t.WorkorderMod  = @WorkorderModParam)
		order by t.WorkorderMod, t.AssemblyNumber asc
	END
END

DROP TABLE #AllData

SET NOCOUNT OFF



GO