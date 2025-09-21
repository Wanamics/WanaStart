#if FALSE
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
                action(WanaStartImportBalance)
                {
                    Caption = 'Import Balance';
                    ApplicationArea = All;
                    Image = ImportChartOfAccounts;
                    // RunObject = codeunit "WanaStart Import Balance";
                    RunObject = Report "WanaStart Import Balance";
                    // trigger OnAction()
                    // var
                    //     ImportLine: Record "WanaStart Import FR Line";
                    //     StartDateTime: DateTime;
                    //     DoneMsg: Label '%1 lines imported in %2.';
                    //     DeleteLines: Label 'Do you want to delete %1 previous lines?';
                    // begin
                    //     if not ImportLine.IsEmpty then
                    //         if not Confirm(DeleteLines, false, ImportLine.Count) then
                    //             exit
                    //         else
                    //             ImportLine.DeleteAll();
                    //     StartDateTime := CurrentDateTime;
                    //     Xmlport.Run(Xmlport::"WanaStart Import Balance", false, true, ImportLine);
                    //     Message(DoneMsg, ImportLine.Count, CurrentDateTime - StartDateTime);
                    // end;
                }
                action(WanaStartImportFEC)
                {
                    Caption = 'Import FEC';
                    ApplicationArea = All;
                    Image = ImportChartOfAccounts;
                    RunObject = codeunit "WanaStart Import FR";
                    // trigger OnAction()
                    // var
                    //     ImportLine: Record "wanaStart Import FR Line";
                    //     StartDateTime: DateTime;
                    //     DoneMsg: Label '%1 lines imported in %2.';
                    //     DeleteLines: Label 'Do you want to delete %1 previous lines?';
                    // begin
                    //     if not ImportLine.IsEmpty then
                    //         if not Confirm(DeleteLines, false, ImportLine.Count) then
                    //             exit
                    //         else
                    //             Rec.DeleteAll();
                    //     StartDateTime := CurrentDateTime;
                    //     Xmlport.Run(Xmlport::"Import FEC+", false, true, Rec);
                    //     Message(DoneMsg, ImportLine.Count, CurrentDateTime - StartDateTime);
                    // end;
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
                action(WanaStartBalance)
                {
                    ApplicationArea = All;
                    Caption = 'Balance / Posting Date & Document No.';
                    Image = Balance;
                    RunObject = report "WanaStart Balance Batch";
                }
            }
        }
    }
}
#endif
