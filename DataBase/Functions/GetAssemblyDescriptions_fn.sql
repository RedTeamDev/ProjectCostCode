
ALTER FUNCTION [dbo].[GetAssemblyDescriptions_fn]
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

IF EXISTS (
	SELECT TOP 1 x.AdjustCostCodeDesc
	FROM (
		select AdjustCostCodeDesc
		from Adjustments
		where workorderid = @workorderid
		and AdjustCostCode = @assemblynumber
		and not isnull(AdjustCostCodeDesc,'') = ''
	) x
)
BEGIN
	select @Str = (
		select top 1 AdjustCostCodeDesc
		from Adjustments
		where workorderid = @workorderid
		and AdjustCostCode = @assemblynumber
		and not isnull(AdjustCostCodeDesc,'') = ''
	)
END

ELSE

IF EXISTS (
	SELECT TOP 1 x.AssemblyDescription 
	FROM (
		select AssemblyDescription
		from workorderassemblies 
		where workorderid = @workorderid
		and workordermod = @workordermod
		and assemblynumber = @assemblynumber
		and assemblymod in (SELECT AssemblyMod FROM Assemblies WHERE AssemblyNumber = @assemblynumber)
		and status = 'show'

		union

		select AssemblyDescription
		from buyoutassemblies 
		where workorderid = @workorderid
		and workordermod = @workordermod
		and assemblynumber = @assemblynumber
		and assemblymod  in (SELECT AssemblyMod FROM Assemblies WHERE AssemblyNumber = @assemblynumber)
		and status = 'show'
	) x
)
BEGIN

	select @Str = COALESCE(@Str+'; ','') + x.AssemblyDescription 
			from (
					Select distinct y.AssemblyDescription 
					from ( 
						select AssemblyDescription
						from workorderassemblies 
						where workorderid = @workorderid
						and workordermod = @workordermod
						and assemblynumber = @assemblynumber
						and  assemblymod in (SELECT AssemblyMod FROM Assemblies WHERE AssemblyNumber = @assemblynumber)
						and status = 'show'

						union

						select AssemblyDescription
						from buyoutassemblies 
						where workorderid = @workorderid
						and workordermod = @workordermod
						and assemblynumber = @assemblynumber
						and  assemblymod in (SELECT AssemblyMod FROM Assemblies WHERE AssemblyNumber = @assemblynumber)
						and status = 'show'
					)y
			) x
			

	

END

ELSE

BEGIN
	
	IF EXISTS (
			select top 1 ProjectCostCodeID
			from ProjectCostCodes
			where WorkorderID = @workorderid
			and CostCodeNumber = @assemblynumber	
	)
	begin
		select @Str = CostCodeName
		from ProjectCostCodes
		where WorkorderID = @workorderid
		and CostCodeNumber = @assemblynumber
	end
	ELSE IF EXISTS (
			select top 1 AssemblyNumber
			from assemblies
			where assemblynumber = @assemblynumber
			and assemblymod in (SELECT TOP 1 AssemblyMod FROM Assemblies WHERE AssemblyNumber = @assemblynumber)
		) 
	begin
		select @Str = AssemblyDescription 
		from assemblies 
		where assemblynumber = @assemblynumber
		and assemblymod in (SELECT TOP 1 AssemblyMod FROM Assemblies WHERE AssemblyNumber = @assemblynumber)
	END
	ELSE
		SELECT @Str = cc.CostCodeDesc FROM CostCode cc WHERE cc.CostCodeID =  @assemblynumber
END

RETURN @Str

END

