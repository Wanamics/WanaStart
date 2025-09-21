codeunit 87105 "WanaStart Import Line Split"
{
    TableNo = "wanaStart Import Line";

    trigger OnRun()
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VPS1: Record "VAT Posting Setup";
        VPS2: Record "VAT Posting Setup";
        Rec2: Record "wanaStart Import Line";
        MapAccount: Record "WanaStart Map Account";
        MapSourceCode: Record "wanaStart Map Source Code";
        xVATAmount: Decimal;
        AmountExclVAT: Decimal;
    begin
        Rec.TestField(Rec.Idevise, '');
        Rec.TestField("Split Line No.", 0);
        // Rec.TestField(MontantDev, 0);
        // Rec.TestField("VAT Prod. Posting Group");
        Rec.TestField(CompAuxNum);
        MapAccount.Get(Rec.CompteNum, Rec.CompAuxNum);
        if Rec."VAT Prod. Posting Group" <> '' then
            VPS1.Get(MapAccount.GetVATBusPostingGroup(), Rec."VAT Prod. Posting Group")
        else begin
            MapSourceCode.Get(Rec.JournalCode);
            MapSourceCode.TestField("VAT Prod. Posting Group");
            VPS1.Get(MapAccount.GetVATBusPostingGroup(), MapSourceCode."VAT Prod. Posting Group")
        end;
        VATProdPostingGroup.SetFilter(Code, '<>%1', VPS1."VAT Prod. Posting Group");
        if Page.RunModal(0, VATProdPostingGroup) <> Action::LookupOK then
            exit;
        VPS2.Get(MapAccount.GetVATBusPostingGroup(), VATProdPostingGroup.Code);

        Rec2.SetRange("Line No.", Rec."Line No.");
        Rec2.FindLast();
        // Rec2.TransferFields(Rec);
        // Rec2 := Rec;
        Rec2."Split Line No." += 1;
        Rec2."VAT Account Amount" := 0;
        Rec2."VAT Account Amt. %" := 0;
        Rec2.Insert(true);
        Rec2.Validate("VAT Prod. Posting Group", VATProdPostingGroup.Code);
        SplitAmount(Rec.Amount, Rec."VAT Account Amount", VPS1."VAT %", VPS2."VAT %", Rec.Amount, Rec2.Amount);
        Rec2.Validate(Amount);
        // ((Rec.Amount - (Rec."VAT Account Amount") * (1 + VPS2."VAT %" / 100) * (1 + VPS1."VAT %" / 100)
        //     - Rec.Amount * (1 + VPS2."VAT %" / 100))
        // / ((1 + VPS1."VAT %" / 100) - (1 + VPS2."VAT %" / 100)));
        // Rec2.Validate("VAT Amount", -Rec2.Amount * (1 - 1 / Coef(VPS2."VAT %")));
        // Rec2.MontantDev := 0;
        Rec2.Modify(true);

        // xVATAmount := Rec."VAT Amount";
        Rec.Validate(Amount); //, Rec.Amount - Rec2.Amount);
        // Rec.Validate("VAT Amount", xVATAmount - Rec2."VAT Amount");
        Rec.Modify(true);
    end;

    local procedure SplitAmount(pAmount: Decimal; pVATAmount: Decimal; pVAT1: Decimal; pVAT2: Decimal; var pAmount1: Decimal; var pAmount2: decimal);
    begin
        // pAmount2 := ((pAmount - (pAmount + pVATAmount) * Coef(pVAT1))) / (Coef(pVAT2) - Coef(pVAT1)) * Coef(pVAT2);
        // pAmount1 := pAmount - pAmount2;
        pAmount1 := Round(((pAmount - (pAmount + pVATAmount) * Coef(pVAT2))) / (Coef(pVAT1) - Coef(pVAT2)) * Coef(pVAT1));
        pAmount2 := pAmount - pAmount1;
    end;

    local procedure Coef(pVAT: Decimal): Decimal
    begin
        exit(1 + pVAT / 100);
    end;
}
