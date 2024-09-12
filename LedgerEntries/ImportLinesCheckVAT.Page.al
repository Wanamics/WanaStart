page 87104 "wan Import Lines Check VAT"
{
    ApplicationArea = All;
    Caption = 'Import Lines Check VAT';
    PageType = CardPart;
    SourceTable = "wanaStart Import FR Line";

    layout
    {
        area(content)
        {
            field("Feom Account Name"; MapAccount."From Account Name")
            {
                Caption = 'FromAccount Name';
            }
            field("Account No."; MapAccount."Account No.")
            {
                Caption = 'Account No.';
                DrillDown = true;
                trigger OnDrillDown()
                begin
                    MapAccount.ShowAccount();
                end;
            }
            field("VAT Bus. Posting Group"; MapAccountVATBusPostingGroup)
            {
                Caption = 'Map Account VAT Bus. Posting Group';
            }
            field("Map Source VAT Prod. Posting Group"; MapSourceCode."VAT Prod. Posting Group")
            {
                Caption = 'Map Source VAT Prod. Posting Group';
            }
            field("Map Account VAT Prod. Posting Group"; MapAccount."VAT Prod. Posting Group")
            {
                Caption = 'Map Account VAT Prod. Posting Group';
            }
            field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
            {
                // Caption = 'VAT Prod. Posting Group';
            }
            field("VAT %"; VATPostingSetup."VAT %")
            {
                // Caption = 'VAT %';
                StyleExpr = not VATPostingSetupExists;
                Style = Unfavorable;
                DrillDown = true;
                trigger OnDrillDown()
                var
                    VATPostingSetup2: Record "VAT Posting Setup";
                begin
                    VATPostingSetup2.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                    VATPostingSetup2.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
                    RunModal(0, VATPostingSetup2);
                end;
            }
            field("VAT Calculation Type"; VATPostingSetup."VAT Calculation Type")
            {
                Caption = 'VAT Calculation Type';
                // DrillDown = true;
                // trigger OnDrillDown()
                // var
                //     VATPostingSetup2: Record "VAT Posting Setup";
                // begin
                //     VATPostingSetup2.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
                //     VATPostingSetup2.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
                //     RunModal(0, VATPostingSetup2);
                // end;
            }
            field("VAT Base Amount"; VATBaseAmount)
            {
                Caption = 'VAT Base Amount';
            }
            field("VAT Amount"; VATAmount)
            {
                Caption = 'VAT Amount';
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        MapAccount.Get(Rec.CompteNum, Rec.CompAuxNum);
        MapAccountVATBusPostingGroup := MapAccount.GetVATBusPostingGroup();
        MapSourceCode.Get(Rec.JournalCode);
        if Rec."VAT Prod. Posting Group" <> '' then
            VATPostingSetup."VAT Prod. Posting Group" := Rec."VAT Prod. Posting Group"
        else
            if MapAccount."VAT Prod. Posting Group" <> '' then
                VATPostingSetup."VAT Prod. Posting Group" := MapAccount."VAT Prod. Posting Group"
            else
                VATPostingSetup."VAT Prod. Posting Group" := MapSourceCode."VAT Prod. Posting Group";
        if (MapAccountVATBusPostingGroup <> '') and (VATPostingSetup."VAT Prod. Posting Group" <> '') then
            VATPostingSetupExists := VATPostingSetup.Get(MapAccountVATBusPostingGroup, VATPostingSetup."VAT Prod. Posting Group");
        if VATPostingSetup."VAT %" <> 100 then
            VATBaseAmount := -Rec.Amount / (1 + VATPostingSetup."VAT %" / 100);
        VATAmount := -(Rec.Amount + VATBaseAmount);
    end;

    var
        MapAccountVATBusPostingGroup: Code[20];
        MapAccount: Record "wanaStart Map Account";
        MapSourceCode: Record "wanaStart Map Source Code";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetupExists: Boolean;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
}
