#if FALSE
namespace Wanamics.WanaStart;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Setup;

codeunit 87131 "WanaStart Set VAT Prod. P.G."
{
    TableNo = "wanaStart Import FR Line";

    trigger OnRun()
    var
        MapSourceCode: Record "wanaStart Map Source Code";
        MapAccount: Record "wanaStart Map Account";
        VATPostingSetup: Record "VAT Posting Setup";
        TempVATPostingSetup: Record "VAT Posting Setup" temporary;
    begin
        if Rec.FindSet() then
            repeat
                Rec.Validate("VAT Prod. Posting Group");
                // if Rec.JournalCode <> MapSourceCode."Source Code" then
                //     MapSourceCode.Get(Rec.JournalCode);
                // if MapSourceCode."VAT Prod. Posting Group" = '' then
                //     Continue;
                // if (Rec.CompteNum <> MapAccount."From Account No.") or (Rec.CompAuxNum <> MapAccount."From SubAccount No.") then
                //     MapAccount.Get(Rec.CompteNum, Rec.CompAuxNum);
                // TempVATPostingSetup."VAT Bus. Posting Group" := MapAccount.GetVATBusPostingGroup();
                // case true of
                //     Rec."VAT Prod. Posting Group" <> '':
                //         TempVATPostingSetup."VAT Prod. Posting Group" := Rec."VAT Prod. Posting Group";
                //     MapAccount."VAT Prod. Posting Group" <> '':
                //         TempVATPostingSetup."VAT Prod. Posting Group" := MapAccount."VAT Prod. Posting Group"
                //     else
                //         TempVATPostingSetup."VAT Prod. Posting Group" := MapSourceCode."VAT Prod. Posting Group";
                // end;
                // if (VATPostingSetup."VAT Bus. Posting Group" <> TempVATPostingSetup."VAT Bus. Posting Group") or
                //         (VATPostingSetup."VAT Prod. Posting Group" <> TempVATPostingSetup."VAT Prod. Posting Group") then
                //     VATPostingSetup.Get(TempVATPostingSetup."VAT Bus. Posting Group", TempVATPostingSetup."VAT Prod. Posting Group");
                // if VATPostingSetup."VAT %" <> Rec."VAT %" then begin
                //     Rec.Validate("VAT %", VATPostingSetup."VAT %");
                //     Rec.Modify(true);
                // end;
            until Rec.Next() = 0;
    end;
}
#endif
