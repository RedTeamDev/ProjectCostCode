CREATE VIEW [dbo].[OpenCommitments_View]

AS


SELECT DISTINCT bo.WorkorderID
, bo.WorkorderMod
, w.TypeOfBid as ProposalType
, w.WorkorderStatus
, isnull(w.ChangeInitiatedBy,'') as ChangeInitiatedBy
, case 
	when bo.WorkorderMod = '00' and w.WorkorderStatus in ('InProgress','Acknowledge') then 'Active'
	when bo.WorkorderMod <> '00' and w.WorkorderStatus in ('InProgress','Acknowledge','Closed') then 'Active'
	else 'Inactive'
  end as Workorder_Status
, bo.BuyoutID
, bo.ordnum
, bo.TO_Mod
, bt.BoTypeID
, bt.BoTypePrefix
, bt.CategoryNumber
, ct.CategoryName
, bl.CstCde as OrderCostCode
, bo.OrderDate
, bo.VendorID
, e.EntityID
, CASE bt.BOTypeID 
	WHEN '3' THEN (Select top 1 FirstName + ' ' + LastName from Users inner join BuyoutLines on BuyoutLines.UserID = Users.UserID and BuyoutLines.Recnum = bo.BuyoutID)
	ELSE ISNULL(e.EntityName, u.FirstName + ' ' + u.LastName) 
  END AS EntityName
, bo.DelegatedTo as EmployeeID
, u.FirstName + ' ' + u.LastName as EmployeeName
, bo.Description

/*
, case 
	when isnull(bl.Usrdf1,0) = 1 
	then SUM(isnull(bl.Extttl,0)) * (1 + isnull(tv.TaxVenueRate,0) / 100)
	else SUM(isnull(bl.Extttl,0))
  end as OrderTotal
*/
, max(bo.OrderTotal) as OrderTotal
, bo.status
, case
	when bo.TO_Mod = '00' and bo.status in ('Committed','Executed') then 'Active'
	when bo.TO_Mod <> '00' and bo.status in ('Committed','Executed','Closed') then 'Active'
	else 'Inactive'
  end as Buyout_Status
, null as GeneralLedgerID--t.GeneralLedgerID
, t.Source
, null as SourceID--t.ID as SourceID
, null as AccountID --t.AccountID
, null as AcctControlRef--t.AcctControlRef
, isnull(max(t.glAmount),0) as glAmount
, max(t.glStatus) as glStatus
, case 
	when max(t.glStatus) in ('Pending','Posted') then 'Active'
	else 'Inactive'
  end as gl_Status
, case bo.WorkorderMod
	when '00' then 'Original'
	else 'CO ' + bo.WorkorderMod
  end as BuyoutScope

, case 
	when bo.TO_Mod = '00' and isnull(bo.status,'') not in  ('','Void')
	then 
		
		case 
			when isnull(bl.Usrdf1,0) = 1 
			then SUM(isnull(bl.Extttl,0)) * (1 + isnull(tv.TaxVenueRate,0) / 100)
			else SUM(isnull(bl.Extttl,0))
		end
		
		--isnull(max(bo.OrderTotal),0)
	else convert(DECIMAL(18,9),0)
  end as OriginalAmt

, case 
	when bo.TO_Mod = '00' and isnull(bo.status,'') in ('Committed','Executed','Closed') 
	then
		
		case 
			when isnull(bl.Usrdf1,0) = 1 
			then SUM(isnull(bl.Extttl,0)) * (1 + isnull(tv.TaxVenueRate,0) / 100)
			else SUM(isnull(bl.Extttl,0))
		end
		
		--isnull(max(bo.OrderTotal),0)
	else convert(DECIMAL(18,9),0)
  end as ApprovedOriginalAmt
, case 
	when bo.TO_Mod = '00' and isnull(bo.status,'') in ('Draft') 
	then
		
		case 
			when isnull(bl.Usrdf1,0) = 1 
			then SUM(isnull(bl.Extttl,0)) * (1 + isnull(tv.TaxVenueRate,0) / 100)
			else SUM(isnull(bl.Extttl,0))
		end
		
		--isnull(max(bo.OrderTotal),0)
	else convert(DECIMAL(18,9),0)
  end as DraftOriginalAmt

, case
	when bo.TO_Mod <> '00' and bo.status in ('Committed','Executed','Closed') 
	then
		
		case 
			when isnull(bl.Usrdf1,0) = 1 
			then SUM(isnull(bl.Extttl,0)) * (1 + isnull(tv.TaxVenueRate,0) / 100)
			else SUM(isnull(bl.Extttl,0))
		end
		
		--isnull(max(bo.OrderTotal),0)
	else convert(DECIMAL(18,9),0)
  end as ApprovedChangesAmt

  , case
	when bo.TO_Mod <> '00' and bo.status = 'Draft' 
	then
		
		case 
			when isnull(bl.Usrdf1,0) = 1 
			then SUM(isnull(bl.Extttl,0)) * (1 + isnull(tv.TaxVenueRate,0) / 100)
			else SUM(isnull(bl.Extttl,0))
		end
		
		--isnull(max(bo.OrderTotal),0)
	else convert(DECIMAL(18,9),0)
  end as PotentialChangesAmt

, isnull((
	select sum(convert(DECIMAL(18,9), isnull(sd.DirectiveAmount,0))) as x
	from SubDirectives sd 
	where sd.BuyoutID = bo.BuyoutID 
	and sd.DirectiveStatus in('Draft','Committed')
	),0) as OpenDirectivesAmt
, case 
	when bo.TO_Mod = '00' and isnull(bo.status,'') in ('Committed','Executed','Closed') 
	then
		isnull((
		select sum(convert(DECIMAL(18,9), isnull(sd.DirectiveAmount,0))) as x
		from SubDirectives sd 
		where sd.BuyoutID = bo.BuyoutID 
		and sd.DirectiveStatus in('Draft','Committed')
		),0)
	else convert(DECIMAL(18,9),0)
	end as ApprovedOpenDirectivesAmt
, case 
	when bo.status = 'Draft'
	then
		isnull((
		select sum(convert(DECIMAL(18,9), isnull(sd.DirectiveAmount,0))) as x
		from SubDirectives sd 
		where sd.BuyoutID = bo.BuyoutID 
		and sd.DirectiveStatus in('Draft','Committed')
		),0)
	else convert(DECIMAL(18,9),0)
	end as DraftOpenDirectivesAmt

, isnull((select sum(isnull(q.QuoteAmount,0))
	from Quotes q
	where q.WorkorderID = bo.WorkorderID 
	and q.WorkorderMod = bo.WorkorderMod
	and q.DefaultCC = bl.CstCde
	and bt.CategoryNumber = case q.DefaultCat
		when 'Material' then '030'
		when 'Labor' then '010'
		when 'Subcontract' then '040'
		when 'Equipment' then '020'
	end
	and q.VendorID = bo.VendorID
	and not q.QuoteUniqueID in (select isnull(sd.QuoteReference,0) from SubDirectives sd where sd.WorkorderID = bo.WorkorderID)
	and q.QuoteStatus in ('Draft','Committed')
	group by q.WorkorderID, q.DefaultCC, q.DefaultCat
	),0) as OpenQuotesAmt
, case 
	when bo.TO_Mod = '00' and isnull(bo.status,'') in ('Committed','Executed','Closed') 
	then isnull((select sum(isnull(q.QuoteAmount,0))
		from Quotes q
		where q.WorkorderID = bo.WorkorderID 
		and q.WorkorderMod = bo.WorkorderMod
		and q.DefaultCC = bl.CstCde
		and bt.CategoryNumber = case q.DefaultCat
			when 'Material' then '030'
			when 'Labor' then '010'
			when 'Subcontract' then '040'
			when 'Equipment' then '020'
		end
		and q.VendorID = bo.VendorID
		and not q.QuoteUniqueID in (select isnull(sd.QuoteReference,0) from SubDirectives sd where sd.WorkorderID = bo.WorkorderID)
		and q.QuoteStatus in ('Draft','Committed')
		group by q.WorkorderID, q.DefaultCC, q.DefaultCat
		),0)
	else convert(DECIMAL(18,9),0)
	end as ApprovedOpenQuotesAmt
, case 
	when bo.status = 'Draft'
	then isnull((select sum(isnull(q.QuoteAmount,0))
		from Quotes q
		where q.WorkorderID = bo.WorkorderID 
		and q.WorkorderMod = bo.WorkorderMod
		and q.DefaultCC = bl.CstCde
		and bt.CategoryNumber = case q.DefaultCat
			when 'Material' then '030'
			when 'Labor' then '010'
			when 'Subcontract' then '040'
			when 'Equipment' then '020'
		end
		and q.VendorID = bo.VendorID
		and not q.QuoteUniqueID in (select isnull(sd.QuoteReference,0) from SubDirectives sd where sd.WorkorderID = bo.WorkorderID)
		and q.QuoteStatus in ('Draft','Committed')
		group by q.WorkorderID, q.DefaultCC, q.DefaultCat
		),0)
	else convert(DECIMAL(18,9),0)
	end as DraftOpenQuotesAmt

, case 
	when /*bo.TO_Mod = '00' and*/ isnull(bo.status,'') in ('Committed','Executed','Closed') 
	then case 
			when max(ta.glStatus) in ('Pending','Posted') then isnull(max(ta.glAmount),0)
			else convert(DECIMAL(18,9),0)
		end 
	else convert(DECIMAL(18,9),0)
  end as ApprovedActualAmt
, case
	when bo.status = 'Draft'
	then case
			when max(ta.glStatus) in ('Pending','Posted') then isnull(max(ta.glAmount),0)
			else convert(DECIMAL(18,9),0)
		end
	else convert(DECIMAL(18,9),0)
  end as DraftActualAmt
, case
	--when max(t.OpenStatus) = 'Paid' and t.Source IN ('ExpenseReimbursement','Timesheets') then isnull(max(t.glAmount),0)
	when max(ta.OpenStatus) = 'Paid' then isnull(max(ta.glAmount),0)
	else convert(DECIMAL(18,9),0)
  end as PartialActualAmt

, convert(DECIMAL(18,9), (Select isnull(sum(isnull(vi.ChangeInRetainage,0)),0) 
							From VendorInvoices vi
							INNER JOIN Buyout b on b.BuyoutID = vi.BuyoutID
							INNER JOIN BuyoutType bt on b.BoTypeID = bt.BoTypeID
							Where vi.VendorInvoiceStatus IN ('Committed','Executed','Closed') and vi.buyoutID = bo.BuyoutID)) as RetainedAmt
, case 
	when bo.TO_Mod = '00' and isnull(bo.status,'') in ('Committed','Executed','Closed') then convert(DECIMAL(18,9), isnull(min(t.RetainedAmt),0))
	else convert(DECIMAL(18,9),0)
  end as ApprovedRetainedAmt
, case
	when bo.status = 'Draft' then convert(DECIMAL(18,9), isnull(min(t.RetainedAmt),0))
	else convert(DECIMAL(18,9),0)
  end as DraftRetainedAmt

, convert(DECIMAL(18,9),0) as OpenAmt --> se va a calcular en el Stored procedure "Buyout_CommitmentAudit_pa" usando la funcion "OpenCommitmentAmt_fn"
, convert(DECIMAL(18,9),0) as DraftOpenAmt --> no tiene sentido calcularlo

, 0 as PaidAmt
FROM Buyout bo
INNER JOIN BuyoutLines bl on bo.BuyoutID = bl.Recnum 
INNER JOIN BuyoutType bt on bo.BoTypeID = bt.BoTypeID
INNER JOIN Workorders w on bo.WorkorderID = w.WorkorderID and bo.WorkorderMod = w.WorkorderMod
INNER JOIN CostType ct on bt.CategoryNumber = ct.CategoryNumber
LEFT JOIN TaxVenues tv on bo.TaxVenueID = tv.TaxVenueID 
LEFT JOIN (
	select BuyoutID, OrderCostCode, WorkorderID,  CategoryNumber, Source, max(glStatus) as glStatus, sum(isnull(glAmount,0)) as glAmount, sum(isnull(RetainedAmt,0)) as RetainedAmt
	, case when OpenStatus in ('Committed','Executed','Closed') then 'Paid' else '' end as OpenStatus
	from YesClosedBuyout_View
	group by BuyoutID, OrderCostCode, WorkorderID, CategoryNumber, Source, (case when OpenStatus in ('Committed','Executed','Closed') then 'Paid' else '' end)
	) ta on ta.BuyoutID = (select b1.buyoutID from buyout b1 where b1.ordnum=bo.ordnum and b1.TO_Mod='00' and b1.workorderID = bo.workorderID  and isnull(b1.status,'') not in ('Void','Voided')  )
	 and ta.OrderCostCode = bl.CstCde and ta.WorkorderID = bo.WorkorderID  and ta.CategoryNumber = bt.CategoryNumber
LEFT JOIN (
	select BuyoutID, OrderCostCode, WorkorderID/*, WorkorderMod*/, CategoryNumber, Source, max(glStatus) as glStatus, sum(isnull(glAmount,0)) as glAmount, sum(isnull(RetainedAmt,0)) as RetainedAmt
	, case when OpenStatus in ('Committed','Executed','Closed') then 'Paid' else '' end as OpenStatus
	from YesClosedBuyout_View
	group by BuyoutID, OrderCostCode, WorkorderID/*, WorkorderMod*/, CategoryNumber, Source, (case when OpenStatus in ('Committed','Executed','Closed') then 'Paid' else '' end)
	) t on t.BuyoutID = bo.BuyoutID and t.OrderCostCode = bl.CstCde and t.WorkorderID = bo.WorkorderID /*and t.WorkorderMod = bo.WorkorderMod*/ and t.CategoryNumber = bt.CategoryNumber
LEFT JOIN Vendor v on bo.VendorID = v.[Vendor#]
LEFT JOIN Entity e on v.EntityID = e.EntityID
LEFT JOIN Users u on bo.DelegatedTo = u.UserID
WHERE isnull(bl.CstCde,'') <> ''
AND bl.Prttitle <> '**Unallocated**'
AND isnull(ltrim(bl.Extttl),'') <> ''
GROUP BY bo.WorkorderID
, bo.WorkorderMod
, bo.BuyoutID
, bo.ordnum
, bo.TO_Mod
, bo.DelegatedTo
, bo.Description 
, bo.status
, bo.TO_Mod
, bt.BoTypeID
, bt.BoTypePrefix
, bt.CategoryNumber 
, bo.OrderDate
, bo.VendorID 
, w.TypeOfBid
, w.WorkorderStatus
, w.ChangeInitiatedBy 
, ct.CategoryName 
, bl.CstCde
, isnull(bl.Usrdf1,0)
, tv.TaxVenueRate
, t.Source
, e.EntityID
, e.EntityName
, u.FirstName + ' ' + u.LastName



GO