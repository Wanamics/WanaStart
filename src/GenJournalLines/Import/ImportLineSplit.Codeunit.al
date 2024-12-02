codeunit 87105 "WanaStart Import Line Split"
{
    TableNo = "WanaStart Import FR Line";

    trigger OnRun()
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VPS1: Record "VAT Posting Setup";
        VPS2: Record "VAT Posting Setup";
        Rec2: Record "WanaStart Import FR Line";
        xVATAmount: Decimal;
        MapAccount: Record "WanaStart Map Account";
    begin
        Rec.TestField(Rec.Idevise, '');
        Rec.TestField("Split Line No.", 0);
        Rec.TestField("VAT Prod. Posting Group");
        MapAccount.Get(Rec.CompteNum, Rec.CompAuxNum);
        VPS1.Get(MapAccount.GetVATBusPostingGroup(), Rec."VAT Prod. Posting Group");
        if Page.RunModal(0, VATProdPostingGroup) <> Action::LookupOK then
            exit;
        VPS2.Get(MapAccount.GetVATBusPostingGroup(), VATProdPostingGroup.Code);

        Rec2.SetRange("Line No.", Rec."Line No.");
        Rec2.FindLast();
        Rec2.TransferFields(Rec);
        Rec2."Split Line No." += 1;
        Rec2."VAT Prod. Posting Group" := VATProdPostingGroup.Code;

        Rec2.Validate(Amount,
            ((Rec.Amount + Rec."VAT Amount") * (1 + VPS2."VAT %" / 100) * (1 + VPS1."VAT %" / 100)
                - Rec.Amount * (1 + VPS2."VAT %" / 100))
            / ((1 + VPS1."VAT %" / 100) - (1 + VPS2."VAT %" / 100)));
        Rec2.Validate("VAT Amount", -Rec2.Amount * (1 - 1 / (1 + VPS2."VAT %" / 100)));
        Rec2.MontantDev := 0;
        Rec2.Insert(true);

        xVATAmount := Rec."VAT Amount";
        Rec.Validate(Amount, Rec.Amount - Rec2.Amount);
        Rec.Validate("VAT Amount", xVATAmount - Rec2."VAT Amount");
        Rec.Modify(true);
    end;
}
