reportextension 87102 "wan Customer - Balance to Date" extends "Customer - Balance to Date"
{
    dataset
    {
        add(CustLedgEntry3)
        {
            column(ExternalDocumentNo; "External Document No.") { }
            column(ClosedByEntryNo; "Closed by Entry No.") { }
        }
    }
    local procedure GetClosedByEntryNo(pEntryNo: Integer; pOpen: Boolean; pClosedByEntryNo: Integer): Integer
    begin
        if pClosedByEntryNo <> 0 then
            exit(pClosedByEntryNo)
        else
            if not pOpen then
                exit(pEntryNo);
    end;
}
