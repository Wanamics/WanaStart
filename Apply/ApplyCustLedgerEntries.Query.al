query 87102 "wan Apply Cust. Applies-to ID"
{
    Caption = 'Apply Cust. Applies-to ID';
    QueryType = Normal;

    elements
    {
        dataitem(LedgerEntry; "Cust. Ledger Entry")
        {
            DataItemTableFilter = Open = const(true), "Applies-to ID" = filter(<> '');
            column(No; "Customer No.") { }
            column(CurrencyCode; "Currency Code") { }
            column(PostingGroup; "Customer Posting Group") { }
            column(AppliestoID; "Applies-to ID") { }
            column(Amount; Amount)
            {
                Method = Sum;
            }
            column(RemainingAmount; "Remaining Amount")
            {
                Method = Sum;
            }
            column(NoOfEntry)
            {
                Method = Count;
            }
        }
    }
}
