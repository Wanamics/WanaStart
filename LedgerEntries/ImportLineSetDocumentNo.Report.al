#if FALSE
report 87104 "WanaStart Set Document No."
{
    Caption = 'Set Document No.';
    ProcessingOnly = true;
    UseRequestPage = false;
    dataset
    {
        // dataitem("Map Source Code"; "wanaStart Map Source Code")
        // {
        //     RequestFilterFields = "From Source Code";
        //     DataItemTableView = where("Document No." = const("Document No."::"From Line"));


        dataitem(ImportLine; "wanaStart Import FR Line")
        {
            DataItemTableView = sorting(JournalCode, EcritureNum);
            // DataItemLinkReference = "Map Source Code";
            // DataItemLink = JournalCode = field("From Source Code");

            trigger OnPreDataItem()
            var
                ConfirmLbl: Label 'Do-you want to set %1 on %2 %3?', Comment = '%1 FieldName, %2:Count, %3:TableCaption';
            begin
                if not Confirm(ConfirmLbl, false, FieldCaption("Document No."), Count, TableCaption) then
                    CurrReport.Quit;
            end;

            trigger OnAfterGetRecord()
            begin
                xImportLine."Document No." := "Document No.";
                if (JournalCode <> xImportLine.JournalCode) or
                    (EcritureNum <> xImportLine.EcritureNum) then begin
                    if UniqueCustomerVendor(ImportLine) then
                        Suffix := 0
                    else
                        Suffix := 1;
                    xImportLine := ImportLine;
                end else
                    if (CompAuxNum <> '') and ("VAT Prod. Posting Group" = '') then
                        Suffix += 1;

                if Suffix = 0 then
                    "Document No." := EcritureNum
                else
                    "Document No." := EcritureNum + '.' + Format(Suffix);
                if "Document No." <> xImportLine."Document No." then
                    Modify();
            end;
        }
    }
    // }
    var
        xImportLine: Record "wanaStart Import FR Line";
        Suffix: Integer;

    local procedure UniqueCustomerVendor(pRec: Record "wanaStart Import FR Line"): Boolean
    var
        Rec2: Record "wanaStart Import FR Line";
    begin
        Rec2.SetRange(JournalCode, pRec.JournalCode);
        Rec2.SetRange(EcritureNum, pRec.EcritureNum);
        Rec2.SetRange(CompteNum, pRec.CompteNum);
        Rec2.SetFilter(CompAuxNum, '<>%1', '');
        Rec2.SetFilter("Line No.", '<>%1', pRec."Line No.");
        Rec2.SetRange("Split Line No.", 0);
        Rec2.SetRange("VAT Prod. Posting Group",'');
        exit(Rec2.IsEmpty);
    end;
}
#endif