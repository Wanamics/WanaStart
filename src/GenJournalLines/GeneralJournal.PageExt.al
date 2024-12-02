pageextension 87100 "WanaStart General Journal" extends "General Journal"
{
    layout
    {
        addlast(Control1)
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
                    RunObject = codeunit "WanaStart Import FR";
                }
                action(WanaStartMapSourceCode)
                {
                    Caption = 'Map Source Codes';
                    ApplicationArea = All;
                    Image = JournalSetup;
                    RunObject = page "WanaStart Map Source Codes";
                }
                action(WanaStartMapAccounts)
                {
                    Caption = 'Map Accounts';
                    ApplicationArea = All;
                    Image = Accounts;
                    RunObject = page "WanaStart Map Accounts";
                }

                action(WanaStartGetJournalLines)
                {
                    ApplicationArea = All;
                    Caption = 'Get Lines';
                    Image = GetLines;
                    RunObject = codeunit "WanaStart Get Journal Lines";
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
