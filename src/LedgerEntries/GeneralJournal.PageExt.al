pageextension 81900 "wanaStart General Journal" extends "General Journal"
{
    actions
    {
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
        addlast("Opening Balance")
        {
            group(WanaStart)
            {
                Caption = 'WanaStart';
                action(WanaStartImportSetupFEC)
                {
                    Caption = 'Import FR Tax Audit Setup';
                    ApplicationArea = All;
                    Image = ImportCodes;
                    RunObject = Codeunit "wanaStart Import FR Setup";
                }
                action(WanaStartMapAccounts)
                {
                    Caption = 'Map Accounts';
                    ApplicationArea = All;
                    Image = Accounts;
                    RunObject = page "wanaStart Accounts";
                }
                action(WanaStartMapSourceCode)
                {
                    Caption = 'Map Source Codes';
                    ApplicationArea = All;
                    Image = JournalSetup;
                    RunObject = page "wanaStart Source Codes";
                }
                action(WanaStartImportFEC)
                {
                    Caption = 'Import FR Tax Audit';
                    ApplicationArea = All;
                    Image = ImportChartOfAccounts;
                    RunObject = codeunit "wanaStart Import FR";
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
}
