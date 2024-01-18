pageextension 87100 "wanaStart General Journal" extends "General Journal"
{
    layout
    {
        addlast(Control120)
        {
            field("Source Code"; Rec."Source Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Source Code field.';
                Visible = false;
            }
            field("Line No."; Rec."Line No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Line No. field.';
                Visible = false;
            }
        }
    }
    actions
    {
        /* Moved to WanaPort
        addlast("F&unctions")
        {
            action(wanaStartExcelExport)
            {
                ApplicationArea = All;
                Caption = 'Excel Export';
                Image = ExportToExcel;
                trigger OnAction()
                var
                    GenJournalLineExcel: codeunit "wanaStart Gen. Journal Excel";
                begin
                    GenJournalLineExcel.Export(Rec);
                end;
            }
            action(wanaStartExcelImport)
            {
                ApplicationArea = All;
                Caption = 'Excel Import';
                Image = ImportExcel;
                trigger OnAction()
                var
                    GenJournalLineExcel: codeunit "wanaStart Gen. Journal Excel";
                begin
                    GenJournalLineExcel.Import(Rec);
                end;
            }
        }
        */
        addlast("Opening Balance")
        {
            group(WanaStart)
            {
                Caption = 'WanaStart';
                action(WanaStartImportFEC)
                {
                    Caption = 'Import FEC';
                    ApplicationArea = All;
                    Image = ImportChartOfAccounts;
                    RunObject = codeunit "wanaStart Import FR";
                }
                action(WanaStartMapSourceCode)
                {
                    Caption = 'Map Source Codes';
                    ApplicationArea = All;
                    Image = JournalSetup;
                    RunObject = page "wanaStart Map Source Codes";
                }
                action(WanaStartMapAccounts)
                {
                    Caption = 'Map Accounts';
                    ApplicationArea = All;
                    Image = Accounts;
                    RunObject = page "wanaStart Map Accounts";
                }

                action(WanaStartGetJournalLines)
                {
                    ApplicationArea = All;
                    Caption = 'Get Lines';
                    Image = GetLines;
                    RunObject = codeunit "wanaStart Get Journal Lines";
                }
                action(WanaStartApply)
                {
                    ApplicationArea = All;
                    Caption = 'Apply Applies-to IDs';
                    Image = ApplyEntries;
                    RunObject = codeunit "wanaStart Apply Applies-to ID";
                }
            }
        }
    }
    // local procedure CreateAccounts(var pGenJournalLine: Record "Gen. Journal Line")
    // var
    //     GLAccount: Record "G/L Account";
    //     Customer: Record Customer;
    //     Vendor: Record Vendor;
    // begin
    //     if pGenJournalLine.FindSet() then
    //         repeat
    //             if pGenJournalLine.Description.IndexOf(' ') < 10 then begin
    //                 Case pGenJournalLine."Account Type" of
    //                     pGenJournalLine."Account Type"::"G/L Account":
    //                         begin
    //                             GLAccount.Validate("No.", CopyStr(pGenJournalLine.Description, 1, pGenJournalLine.Description.IndexOf(' ') - 1));
    //                             GLAccount.Validate("Name", CopyStr(pGenJournalLine.Description, pGenJournalLine.Description.IndexOf(' ') + 1));
    //                             if not GLAccount.Find() then
    //                                 GLAccount.Insert(true);
    //                             pGenJournalLine.Validate("Account No.", GLAccount."No.");
    //                             pGenJournalLine.Description := GLAccount.Name;
    //                             pGenJournalLine.Modify();
    //                         end;
    //                     pGenJournalLine."Account Type"::Customer:
    //                         begin
    //                             Customer.Validate("No.", CopyStr(pGenJournalLine.Description, 1, pGenJournalLine.Description.IndexOf(' ') - 1));
    //                             Customer.Validate("Name", CopyStr(pGenJournalLine.Description, pGenJournalLine.Description.IndexOf(' ') + 1));
    //                             if not Customer.Find() then
    //                                 Customer.Insert(true);
    //                             pGenJournalLine.Validate("Account No.", Customer."No.");
    //                             pGenJournalLine.Description := Customer.Name;
    //                             pGenJournalLine.Modify();
    //                         end;
    //                     pGenJournalLine."Account Type"::Vendor:
    //                         begin
    //                             Vendor.Validate("No.", CopyStr(pGenJournalLine.Description, 1, pGenJournalLine.Description.IndexOf(' ') - 1));
    //                             Vendor.Validate("Name", CopyStr(pGenJournalLine.Description, pGenJournalLine.Description.IndexOf(' ') + 1));
    //                             if not Vendor.Find() then
    //                                 Vendor.Insert(true);
    //                             pGenJournalLine.Validate("Account No.", Vendor."No.");
    //                             pGenJournalLine.Description := Vendor.Name;
    //                             pGenJournalLine.Modify();
    //                         end;
    //                 End;
    //             end;
    //         until pGenJournalLine.Next() = 0;
    // end;
}
