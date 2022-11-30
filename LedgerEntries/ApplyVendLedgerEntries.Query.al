query 87103 "wan Apply Vendor Applies-to ID"
{
    Caption = 'Apply Vendor Applies-to ID';
    QueryType = Normal;

    elements
    {
        dataitem(LedgerEntry; "Vendor Ledger Entry")
        {
            DataItemTableFilter = Open = const(true), "Applies-to ID" = filter(<> '');
            column(No; "Vendor No.") { }
            column(CurrencyCode; "Currency Code") { }
            column(PostingGroup; "Vendor Posting Group") { }
            column(AppliestoID; "Applies-to ID") { }
            column(Amount; Amount)
            {
                Method = Sum;
            }
            column(RemainingAmount; "Remaining Amount")
            {
                Method = Sum;
            }
        }
    }
}
