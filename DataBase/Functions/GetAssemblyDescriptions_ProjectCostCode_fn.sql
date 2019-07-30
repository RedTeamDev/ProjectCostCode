ALTER FUNCTION [dbo].[GetAssemblyDescriptions_ProjectCostCode_fn]
(
  @workorderid varchar(7)
, @workordermod char(2)
, @assemblynumber varchar(15)
, @assemblymod char(2)
, @showOriginal varchar(3)
)
RETURNS varchar(max)

AS

BEGIN


IF @showOriginal = 'yes'
SELECT @workordermod = (case when @workordermod <> '00' then '00' else @workordermod end)

DECLARE @Str varchar(max)
DECLARE @CostCodeUniqueId int
DECLARE @ProjectCostCodeID  int 



SELECT @CostCodeUniqueId = ISNULL(
									(
										SELECT CostCodeUniqueId FROM dbo.CostCode cc	
										WHERE cc.CostCodeID	=  @assemblynumber), 
									(	SELECT CostCodeUniqueId 
										FROM dbo.ProjectCostCodes pcc 
										WHERE pcc.WorkOrderID = @workorderid AND pcc.CostCodeNumber	= @assemblynumber)
								)



IF EXISTS (
	SELECT TOP 1 x.*
	FROM (
		select isnull(pcc.CostCodeName,adj.AdjustCostCodeDesc) AdjustCostCodeDesc
		from Adjustments adj
		LEFT JOIN dbo.ProjectCostCodes pcc	ON adj.ProjectCostCodeID = pcc.ProjectCostCodeID	AND pcc.Status	= 'on'
		where adj.workorderid = @workorderid
		and pcc.CostCodeUniqueID	= @CostCodeUniqueID
		and not isnull(adj.AdjustCostCodeDesc,'') = ''
	) x
)
BEGIN
	select @Str = (
		select top 1 isnull(pcc.CostCodeName,adj.AdjustCostCodeDesc) AdjustCostCodeDesc
		from Adjustments adj
		LEFT JOIN dbo.ProjectCostCodes pcc	ON adj.ProjectCostCodeID = pcc.ProjectCostCodeID	AND pcc.Status	= 'on'
		where adj.workorderid = @workorderid
		and pcc.CostCodeUniqueID	= @CostCodeUniqueID
		and not isnull(adj.AdjustCostCodeDesc,'') = ''
	)
END

ELSE

IF EXISTS (
	SELECT TOP 1 x.* 
	FROM (
		SELECT  IIF(woa.AssemblyMod = '00', ISNULL(pcc.CostCodeName,woa.AssemblyDescription) , woa.AssemblyDescription) AssemblyDescription
		from workorderassemblies woa
		INNER JOIN dbo.Assemblies a	ON	woa.AssemblyNumber = a.AssemblyNumber	AND woa.AssemblyMod = a.AssemblyMod
		LEFT JOIN dbo.ProjectCostCodes pcc	ON woa.ProjectCostCodeID = pcc.ProjectCostCodeID	AND pcc.Status	= 'on'		
		where woa.workorderid = @workorderid
		and woa.workordermod = @workordermod
		and pcc.CostCodeUniqueID = @CostCodeUniqueId
		and woa.status = 'show'

		union

		select IIF(ba.AssemblyMod = '00', ISNULL(pcc.CostCodeName,ba.AssemblyDescription) , ba.AssemblyDescription) AssemblyDescription 
		from buyoutassemblies  ba
		INNER JOIN dbo.ProjectCostCodes pcc	ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID	AND pcc.Status	= 'on'
		where ba.workorderid = @workorderid
		and ba.workordermod = @workordermod
		and pcc.CostCodeUniqueID =@CostCodeUniqueId
		and ba.status = 'show'
	) x
)
BEGIN

	select @Str = (
		
		select assDesc = STUFF(
		(
			
			select distinct '; ' + x.AssemblyDescription 
			from (
			
				SELECT  IIF(woa.AssemblyMod = '00', ISNULL(pcc.CostCodeName,woa.AssemblyDescription) , woa.AssemblyDescription) AssemblyDescription
				from workorderassemblies woa
				INNER JOIN dbo.Assemblies a	ON	woa.AssemblyNumber = a.AssemblyNumber	AND woa.AssemblyMod = a.AssemblyMod
				LEFT JOIN dbo.ProjectCostCodes pcc	ON woa.ProjectCostCodeID = pcc.ProjectCostCodeID	AND pcc.Status	= 'on'		
				where woa.workorderid = @workorderid
				and woa.workordermod = @workordermod
				and pcc.CostCodeUniqueID = @CostCodeUniqueId
				and woa.status = 'show'

				union

				select IIF(ba.AssemblyMod = '00', ISNULL(pcc.CostCodeName,ba.AssemblyDescription) , ba.AssemblyDescription) AssemblyDescription 
				from buyoutassemblies  ba
				INNER JOIN dbo.ProjectCostCodes pcc	ON ba.ProjectCostCodeID = pcc.ProjectCostCodeID	AND pcc.Status	= 'on'
				where ba.workorderid = @workorderid
				and ba.workordermod = @workordermod
				and pcc.CostCodeUniqueID =@CostCodeUniqueId
				and ba.status = 'show'
			) x
			FOR XML PATH ('')
		),1,2,'')

	)

END

ELSE

BEGIN
	
	IF EXISTS (
			select top 1 *
			from ProjectCostCodes
			where WorkorderID = @workorderid
			and CostCodeUniqueID = @CostCodeUniqueID

	)
	begin
		select @Str = CostCodeName
		from ProjectCostCodes
		where WorkorderID = @workorderid
		and CostCodeUniqueID = @CostCodeUniqueID
	end
	else IF EXISTS (
		select TOP 1 AssemblyDescription 
		from assemblies 
		where assemblynumber = @assemblynumber
		and assemblymod in (SELECT TOP 1  AssemblyMod FROM Assemblies WHERE AssemblyNumber = @assemblynumber)
	)
	begin
		select @Str = AssemblyDescription 
		from assemblies 
		where assemblynumber = @assemblynumber
		and assemblymod in (SELECT TOP 1  AssemblyMod FROM Assemblies WHERE AssemblyNumber = @assemblynumber)
	END
	ELSE 
		SELECT @Str = cc.CostCodeDesc FROM CostCode cc WHERE cc.CostCodeID =  @assemblynumber

END

RETURN @Str

END

