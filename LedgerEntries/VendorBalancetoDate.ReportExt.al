reportextension 87101 "wan Vendor - Balance to Date " extends "Vendor - Balance to Date"
{
    dataset
    {
        add(VendLedgEntry3)
        {
            column(ExternalDocumentNo; "External Document No.") { }
            column(ClosedByEntryNo; GetClosedByEntryNo("Entry No.", Open, "Closed by Entry No.")) { }
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
