#if FALSE
codeunit 87131 "WanaStart Import Line Merge"
{
    TableNo = "WanaStart Import FR Line";

    trigger OnRun()
    var
        Attached: Record "WanaStart Import FR Line";
    begin
        Rec.TestField("Split Line No.", 0);
        Attached.SetRange("Line No.", Rec."Line No.");
        Attached.SetFilter("Split Line No.", '<>0');
        Attached.CalcSums(Amount);
        Rec.Amount += Attached.Amount;
        Rec.Validate("VAT Prod. Posting Group");
        Rec.Modify(false);
        Attached.DeleteAll(false);
    end;
}
#endif
