#if FALSE
query 87101 "WanaStart Balance"
{
    Caption = 'WanaStart Balance';
    QueryType = Normal;

    elements
    {
        dataitem(wanaStartImportFRLine; "wanaStart Import FR Line")
        {
            column(JournalCode; JournalCode)
            {
            }
            column(EcritureDate; EcritureDate)
            {
            }
            column(DocumentNo; "Document No.")
            {
            }
            column(Amount; Amount)
            {
                Method = Sum;
            }
        }
    }

    trigger OnBeforeOpen()
    begin

    end;
}
#endif