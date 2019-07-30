CREATE VIEW [dbo].[Budget_OpenCol_View]

AS

select distinct case 
	when isnull(bl.Usrdf1,0) = 1 and isnull(bo.TaxVenueID,0) in (select TaxVenueID from TaxVenues) then 
	(
		convert(decimal(19,9),isnull(bl.Extttl,0) * (1 + isnull(tv.TaxVenueRate,0) / 100) 
		- 
		(isnull 
			(
				isnull(
				(
					sum(isnull(p.ChangeInProgress,0))
				),0)
			,0
			)
			+ 
			(
				isnull(
				(
					sum(isnull(p.ChangeInTax,0))
				),0)
			)
		)
		)
	)
	when isnull(bl.Usrdf1,0) = 1 and not isnull(bo.TaxVenueID,0) in (select TaxVenueID from TaxVenues) then 
	(
		convert(decimal(19,9),isnull(bl.Extttl,0) + isnull(bo.SlsTax,0)
		- 
		(isnull 
			(
				isnull(
				(
					sum(isnull(p.ChangeInProgress,0))
				),0)
			,0
			)
			+ 
			(
				isnull(
				(
					sum(isnull(p.ChangeInTax,0))
				),0)
			)
		)
		)
	)
	else convert(decimal(19,9),isnull(bl.Extttl,0) - isnull(sum(isnull(p.ChangeInProgress,0)),0))
end
as OpenBudget
, isnull(bl.Extttl,0) as OpenBudget_Exp
, isnull(bl.Extttl,0) as OpenBudget_Lab
, isnull(bl.Extttl,0) as Extttl
, bt.BOTypeTitle
, bo.BuyoutID
, bl.BoLinesID
, bo.WorkorderID
, bo.WorkorderMod
, bl.Cstcde
, bt.CategoryNumber
, bo.Ordnum
from Buyout bo
inner join BuyoutLines bl on bl.RecNum = bo.BuyoutID
inner join BuyoutType bt on bo.BoTypeID = bt.BoTypeID
left join (
	select isnull(bp.ChangeInProgress,0) as ChangeInProgress, isnull(bp.ChangeInTax,0) as ChangeInTax, bp.BoLinesID
	from BuyoutProgress bp
	inner join vendorinvoices vi on vi.ID = bp.VendorInvoiceID 
	where vi.VendorInvoiceStatus in ('Committed','Executed','Closed')
	) p on p.BoLinesID = bl.BoLinesID 
left join TaxVenues tv on tv.TaxVenueID = bo.TaxVenueID
where bo.Status in ('Committed','Executed')
AND bo.BoTypeID NOT IN(select BOTypeID from Buyouttype bt where  CategoryNumber IN ('030','040') and BOTypePrefix IN ('MI','SI')  AND  reserved='YES') 
group by bl.Usrdf1, bl.Extttl, bo.TaxVenueID, bo.SlsTax, tv.TaxVenueRate, bo.BuyoutID, bl.BoLinesID, bt.BOTypeTitle, bo.WorkorderID, bo.WorkorderMod, bl.Cstcde, bt.CategoryNumber, bo.Ordnum




/*******************************************************************************************************************/
go