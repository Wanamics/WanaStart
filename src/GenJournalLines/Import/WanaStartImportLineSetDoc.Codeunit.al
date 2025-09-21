codeunit 87107 "WanaStart Import Line Set Doc."
{
    TableNo = "wanaStart Import Line";

    trigger OnRun()
    var
        ConfirmLbl: Label 'Do-you want to set %1 on %2 %3?', Comment = '%1 FieldName, %2:Count, %3:TableCaption';
        DoneLbl: Label '%1 "%2" Updated', Comment = '%1:Count, %2:TableCaption';
        Updated: Integer;
    begin
        if not Confirm(ConfirmLbl, false, Rec.FieldCaption("Document No."), Rec.Count, Rec.TableCaption) then
            exit;
        if Rec.FindSet() then
            repeat
                if Update(Rec) then
                    Updated += 1;
            until Rec.Next() = 0;
        Message(DoneLbl, Rec.Count, Rec.TableCaption);
    end;

    var
        xRec: Record "wanaStart Import Line";
        Suffix: Integer;

    local procedure Update(var pRec: Record "wanaStart Import Line"): Boolean
    begin
        xRec."Document No." := pRec."Document No.";
        if (pRec.JournalCode <> xRec.JournalCode) or
            (pRec.EcritureNum <> xRec.EcritureNum) then begin
            if UniqueCustomerVendor(pRec) then
                Suffix := 0
            else
                Suffix := 1;
            xRec := pRec;
        end else
            if (pRec.CompAuxNum <> '') and (pRec."VAT Prod. Posting Group" = '') then
                Suffix += 1;

        if Suffix = 0 then
            pRec."Document No." := pRec.EcritureNum
        else
            pRec."Document No." := pRec.EcritureNum + '.' + Format(Suffix);
        if pRec."Document No." <> xRec."Document No." then
            exit(pRec.Modify());
    end;

    local procedure UniqueCustomerVendor(pRec: Record "wanaStart Import Line"): Boolean
    var
        Rec2: Record "wanaStart Import Line";
    begin
        Rec2.SetRange(JournalCode, pRec.JournalCode);
        Rec2.SetRange(EcritureNum, pRec.EcritureNum);
        Rec2.SetRange(CompteNum, pRec.CompteNum);
        Rec2.SetFilter(CompAuxNum, '<>%1', '');
        Rec2.SetFilter("Line No.", '<>%1', pRec."Line No.");
        Rec2.SetRange("Split Line No.", 0);
        Rec2.SetRange("VAT Prod. Posting Group", '');
        exit(Rec2.IsEmpty);
    end;
}
