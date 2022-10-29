pageextension 81900 "wanaStart General Journal" extends "General Journal"
{
    actions
    {
        addlast("Opening Balance")
        {
            group(WanaStart)
            {
                Caption = 'WanaStart';
                action(WanaStartImportSetupFEC)
                {
                    Caption = 'Import FR Tax Audit Setup';
                    ApplicationArea = All;
                    RunObject = Codeunit "wanaStart Import FR Setup";
                }
                action(WanaStartMapAccounts)
                {
                    Caption = 'Map Accounts';
                    ApplicationArea = All;
                    RunObject = page "wanaStart Accounts";
                }
                action(WanaStartMapSourceCode)
                {
                    Caption = 'Map Source Codes';
                    ApplicationArea = All;
                    RunObject = page "wanaStart Source Codes";
                }
                action(WanaStartImportFEC)
                {
                    Caption = 'Import FR Tax Audit';
                    ApplicationArea = All;
                    RunObject = codeunit "wanaStart Import FR";
                }
                action(WanaStartApply)
                {
                    ApplicationArea = All;
                    Caption = 'Apply Applies-to IDs';
                    RunObject = codeunit "wanaStart Apply Applies-to ID";
                }
            }
        }
    }
}
