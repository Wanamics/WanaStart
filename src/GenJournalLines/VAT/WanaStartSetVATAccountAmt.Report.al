namespace Wanamics.WanaStart;
using Microsoft.Foundation.Enums;

report 87104 "WanaStart Set VAT Account Amt."
{
    Caption = 'WanaStart Set VAT Account Amt.';
    ProcessingOnly = true;

    dataset
    {
        dataitem(MapSourceCode; "wanaStart Map Source Code")
        {
            DataItemTableView = where("WanaStart Posting Type" = filter('<>0'));
            dataitem(ImportLine; "wanaStart Import Line")
            {
                DataItemLinkReference = MapSourceCode;
                DataItemLink = JournalCode = field("From Source Code");
                DataItemTableView = where(CompAuxNum = filter('<>'''''));
                trigger OnAfterGetRecord()
                var
                    VATLine: Record "wanaStart Import Line";
                begin
                    VATLine.SetLoadFields(JournalCode, EcritureNum, CompteNum, PieceRef, Amount, "Split Line No.");
                    VATLine.SetRange(JournalCode, JournalCode);
                    VATLine.SetRange(EcritureNum, EcritureNum);
                    VATLine.SetFilter(CompteNum, VATAccountFilter);
                    VATLine.SetRange(PieceRef, PieceRef);
                    VATLine.CalcSums(Amount);
                    VATLine.SetRange(CompteNum, CompteNum);
                    VATLine.SetRange("Split Line No.", 0);
                    if VATLine.Count = 1 then
                        Validate("VAT Account Amount", VATLine.Amount)
                    else
                        Validate("VAT Account Amount", 0);
                    // if Amount = "VAT Account Amount" then
                    //     "VAT Account Amt. %" := 0
                    // else
                    //     "VAT Account Amt. %" := "VAT Account Amount" / (Amount - "VAT Account Amount");
                    Modify(false);
                end;
            }
            trigger OnPreDataItem()
            begin
                // SetFilter("WanaStart Source Posting Type", '%1|%2', "WanaStart Source Posting Type"::Purchase, "WanaStart Source Posting Type"::Sale);
                if not Confirm('Do you want to set "%1" for lines of %2 "%3"?', false, ImportLine.FieldCaption("VAT Account Amount"), Count, TableCaption) then
                    CurrReport.Quit();
                VATAccountFilter := GetVATAccountFilter();
            end;
        }
    }
    var
        VATAccountFilter: Text;

    local procedure GetVATAccountFilter() ReturnValue: Text
    var
        MapAccount: Record "wanaStart Map Account";
    begin
        MapAccount.SetRange("From SubAccount No.", '');
        MapAccount.SetFilter("WanaStart Source Posting Type", '%1|%2', MapAccount."WanaStart Source Posting Type"::Purchase, MapAccount."WanaStart Source Posting Type"::Sale);
        if MapAccount.FindSet then
            repeat
                if ReturnValue <> '' then
                    ReturnValue += '|';
                ReturnValue += MapAccount."From Account No.";
            until MapAccount.Next() = 0;
    end;
}
